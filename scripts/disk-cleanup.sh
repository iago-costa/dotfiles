#!/usr/bin/env bash
#===============================================================================
# NixOS Disk Cleanup Script
# Sistema: NixOS com Niri + Quickshell
# Objetivo: Liberar máximo de espaço no disco SSD
#===============================================================================

set -u  # Only fail on unbound variables, not on command errors

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Variáveis globais
TOTAL_FREED=0
DRY_RUN=false
AGGRESSIVE=false
LOG_FILE="/tmp/disk-cleanup-$(date +%Y%m%d_%H%M%S).log"

# Detectar o home real do usuário (não /root quando usando sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME="${HOME}"
fi

#===============================================================================
# Funções auxiliares
#===============================================================================

log() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN} $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

get_size() {
    du -sb "$1" 2>/dev/null | cut -f1 || echo 0
}

format_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        local gb=$((bytes / 1073741824))
        local remainder=$(( (bytes % 1073741824) * 100 / 1073741824 ))
        echo "${gb}.${remainder}GB"
    elif (( bytes >= 1048576 )); then
        local mb=$((bytes / 1048576))
        local remainder=$(( (bytes % 1048576) * 100 / 1048576 ))
        echo "${mb}.${remainder}MB"
    elif (( bytes >= 1024 )); then
        local kb=$((bytes / 1024))
        echo "${kb}KB"
    else
        echo "${bytes}B"
    fi
}

show_disk_usage() {
    header "Status do Disco"
    df -h / /nix /home 2>/dev/null | grep -v "^Filesystem" | while read line; do
        echo -e "  ${CYAN}$line${NC}"
    done
    echo ""
}

confirm() {
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] Seria executado: $1"
        return 1
    fi
    read -p "$(echo -e "${YELLOW}Confirmar: $1? [s/N]${NC} ")" -n 1 -r
    echo
    [[ $REPLY =~ ^[Ss]$ ]]
}

show_progress() {
    # $1: current
    # $2: total
    # $3: label (optional)
    local current=$1
    local total=$2
    local label="${3:-}"
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Create the bar [=====>.....]
    local bar="["
    if [ $filled -gt 0 ]; then
        bar+=$(printf "%${filled}s" | tr ' ' '=')
    fi
    if [ $empty -gt 0 ]; then
        bar+=$(printf "%${empty}s" | tr ' ' '.')
    fi
    bar+="]"
    
    # Print progress with carriage return to overwrite line
    echo -ne "\r${CYAN}${bar} ${percent}% ${NC}${label}"
    
    # If done, print newline
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}


#===============================================================================
# 1. LIMPEZA DO NIX STORE (MAIOR IMPACTO)
#===============================================================================

cleanup_nix_generations() {
    header "1. Limpeza de Gerações do NixOS"
    
    # Contar gerações do sistema
    local sys_gens=$(ls /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)
    log "Gerações do sistema encontradas: $sys_gens"
    
    # Contar gerações do usuário
    local user_gens=$(ls ~/.local/state/nix/profiles/profile-*-link 2>/dev/null | wc -l || echo 0)
    log "Gerações do usuário encontradas: $user_gens"
    
    
    echo -e "${YELLOW}ATENÇÃO: Manter apenas as últimas 3 gerações do sistema.${NC}"
    echo -e "${YELLOW}Isso irá liberar MUITO espaço mas remover opções de rollback antigas.${NC}"
    
    if confirm "Remover todas as gerações do sistema exceto as últimas 3"; then
        log "Removendo gerações antigas do sistema..."
        sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system 2>&1 | tee -a "$LOG_FILE" || true
        success "Gerações do sistema limpas"
    fi
    
    if confirm "Remover gerações antigas do usuário (manter últimas 3)"; then
        log "Removendo gerações antigas do usuário..."
        nix-env --delete-generations +3 2>&1 | tee -a "$LOG_FILE" || true
        success "Gerações do usuário limpas"
    fi
    
    # Home-manager generations
    if [[ -d ~/.local/state/home-manager/gcroots ]]; then
        if confirm "Limpar gerações antigas do Home Manager"; then
            log "Removendo gerações do Home Manager..."
            home-manager expire-generations "-7 days" 2>&1 | tee -a "$LOG_FILE" || true
            success "Gerações do Home Manager limpas"
        fi
    fi
}

cleanup_nix_store() {
    header "2. Coleta de Lixo do Nix Store"
    
    local before=$(df --output=used /nix | tail -1)
    
    log "Executando nix-collect-garbage..."
    echo -e "${YELLOW}ATENÇÃO: Isso pode demorar vários minutos.${NC}"
    
    if confirm "Executar garbage collection completo"; then
        # Primeiro, limpar derivações não referenciadas
        log "Removendo derivações órfãs..."
        nix-store --gc --print-dead 2>/dev/null | head -20
        
        # Executar GC
        sudo nix-collect-garbage -d 2>&1 | tee -a "$LOG_FILE"
        
        # Também para o usuário
        nix-collect-garbage -d 2>&1 | tee -a "$LOG_FILE" || true
        
        local after=$(df --output=used /nix | tail -1)
        local freed_kb=$((before - after))
        local freed_bytes=$((freed_kb * 1024))
        
        success "Garbage collection concluído! Liberado: $(format_size $freed_bytes)"
        TOTAL_FREED=$((TOTAL_FREED + freed_bytes))
    fi
}

optimize_nix_store() {
    header "3. Otimização do Nix Store"
    
    log "Verificando se há duplicatas no store para deduplicar com hard links..."
    
    if confirm "Executar nix-store --optimise (pode demorar bastante)"; then
        log "Otimizando store com hard links..."
        sudo nix-store --optimise 2>&1 | tail -10 | tee -a "$LOG_FILE"
        success "Store otimizado!"
    fi
}

#===============================================================================
# 2. CACHES DO USUÁRIO
#===============================================================================

cleanup_user_caches() {
    header "4. Limpeza de Caches do Usuário"
    
    local cache_dirs=(
        "$REAL_HOME/.cache"
        "$REAL_HOME/.local/share/Trash"
        "$REAL_HOME/.thumbnails"
        "$REAL_HOME/.local/share/thumbnails"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local size=$(get_size "$dir")
            if (( size > 1048576 )); then  # Maior que 1MB
                log "Encontrado: $dir ($(format_size $size))"
                if confirm "Limpar $dir"; then
                    rm -rf "${dir:?}"/* 2>/dev/null || true
                    success "Limpo: $dir"
                    TOTAL_FREED=$((TOTAL_FREED + size))
                fi
            fi
        fi
    done
}

cleanup_browser_caches() {
    header "5. Limpeza de Caches de Navegadores"
    
    # Firefox
    if [[ -d "$REAL_HOME/.mozilla/firefox" ]]; then
        local firefox_cache=$(find "$REAL_HOME/.mozilla/firefox" -type d -name "cache2" 2>/dev/null)
        if [[ -n "$firefox_cache" ]]; then
            local size=$(du -sb "$REAL_HOME/.mozilla/firefox" 2>/dev/null | cut -f1 || echo 0)
            log "Firefox cache: $(format_size $size)"
            if confirm "Limpar cache do Firefox"; then
                find "$REAL_HOME/.mozilla/firefox" -type d -name "cache2" -exec rm -rf {} \; 2>/dev/null || true
                find "$REAL_HOME/.mozilla/firefox" -name "*.sqlite" -type f -exec sqlite3 {} "VACUUM;" \; 2>/dev/null || true
                success "Cache do Firefox limpo"
            fi
        fi
    fi
    
    # Chrome/Chromium
    for browser_dir in "$REAL_HOME/.config/google-chrome" "$REAL_HOME/.config/chromium"; do
        if [[ -d "$browser_dir" ]]; then
            local size=$(get_size "$browser_dir")
            log "$(basename $browser_dir): $(format_size $size)"
            
            if confirm "Limpar cache do $(basename $browser_dir)"; then
                find "$browser_dir" -type d -name "Cache" -exec rm -rf {} \; 2>/dev/null || true
                find "$browser_dir" -type d -name "Code Cache" -exec rm -rf {} \; 2>/dev/null || true
                find "$browser_dir" -type d -name "GPUCache" -exec rm -rf {} \; 2>/dev/null || true
                find "$browser_dir" -type d -name "Service Worker" -exec rm -rf {} \; 2>/dev/null || true
                success "Cache do $(basename $browser_dir) limpo"
            fi
        fi
    done
}

cleanup_package_caches() {
    header "6. Limpeza de Caches de Pacotes"
    
    # NPM cache
    if [[ -d "$REAL_HOME/.npm" ]]; then
        local size=$(get_size "$REAL_HOME/.npm")
        log "NPM cache: $(format_size $size)"
        if confirm "Limpar cache do NPM"; then
            npm cache clean --force 2>/dev/null || rm -rf "$REAL_HOME/.npm/_cacache" 2>/dev/null || true
            success "Cache do NPM limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
    
    # Yarn cache
    if [[ -d "$REAL_HOME/.cache/yarn" ]]; then
        local size=$(get_size "$REAL_HOME/.cache/yarn")
        log "Yarn cache: $(format_size $size)"
        if confirm "Limpar cache do Yarn"; then
            yarn cache clean 2>/dev/null || rm -rf "$REAL_HOME/.cache/yarn" 2>/dev/null || true
            success "Cache do Yarn limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
    
    # pip cache
    if [[ -d "$REAL_HOME/.cache/pip" ]]; then
        local size=$(get_size "$REAL_HOME/.cache/pip")
        log "Pip cache: $(format_size $size)"
        if confirm "Limpar cache do pip"; then
            pip cache purge 2>/dev/null || rm -rf "$REAL_HOME/.cache/pip" 2>/dev/null || true
            success "Cache do pip limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
    
    # Cargo cache
    if [[ -d "$REAL_HOME/.cargo/registry/cache" ]]; then
        local size=$(get_size "$REAL_HOME/.cargo/registry/cache")
        log "Cargo cache: $(format_size $size)"
        if confirm "Limpar cache do Cargo"; then
            rm -rf "$REAL_HOME/.cargo/registry/cache"/* 2>/dev/null || true
            rm -rf "$REAL_HOME/.cargo/registry/src"/* 2>/dev/null || true
            success "Cache do Cargo limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi

    # Go cache
    if [[ -d "$REAL_HOME/go/pkg" ]]; then
        local size=$(get_size "$REAL_HOME/go/pkg")
        log "Go modules cache: $(format_size $size)"
        if confirm "Limpar cache do Go"; then
            go clean -cache -modcache 2>/dev/null || rm -rf "$REAL_HOME/go/pkg"/* 2>/dev/null || true
            success "Cache do Go limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

#===============================================================================
# 3. LIMPEZA DE ARQUIVOS TEMPORÁRIOS
#===============================================================================

cleanup_temp_files() {
    header "7. Limpeza de Arquivos Temporários"
    
    # /tmp (se não for tmpfs)
    local tmp_mount=$(df /tmp | tail -1 | awk '{print $1}')
    if [[ "$tmp_mount" != "tmpfs" ]]; then
        local size=$(get_size /tmp)
        log "/tmp (não-tmpfs): $(format_size $size)"
        if confirm "Limpar /tmp"; then
            sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
            success "/tmp limpo"
        fi
    fi
    
    # /var/tmp
    if [[ -d /var/tmp ]]; then
        local size=$(get_size /var/tmp)
        log "/var/tmp: $(format_size $size)"
        if confirm "Limpar /var/tmp"; then
            sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
            success "/var/tmp limpo"
        fi
    fi
    
    # Logs antigos
    if [[ -d /var/log ]]; then
        log "Verificando logs antigos em /var/log..."
        if confirm "Limpar logs antigos (journalctl e arquivos)"; then
            # Journalctl - manter apenas últimos 3 dias
            sudo journalctl --vacuum-time=3d 2>&1 | tee -a "$LOG_FILE"
            sudo journalctl --vacuum-size=100M 2>&1 | tee -a "$LOG_FILE"
            
            # Logs rotatados
            sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
            sudo find /var/log -name "*.old" -delete 2>/dev/null || true
            sudo find /var/log -name "*.[0-9]" -delete 2>/dev/null || true
            success "Logs limpos"
        fi
    fi
}

#===============================================================================
# 4. ANÁLISE DE GRANDES CONSUMIDORES
#===============================================================================

analyze_disk_usage() {
    header "8. Análise de Maiores Consumidores de Disco"
    
    log "Top 20 diretórios em /home/$USER:"
    echo ""
    du -sh "$REAL_HOME"/* "$REAL_HOME"/.[!.]* 2>/dev/null | sort -hr | head -20 | while read size dir; do
        echo -e "  ${CYAN}$size${NC}\t$dir"
    done
    
    echo ""
    log "Top 15 diretórios em /nix/store (pode demorar):"
    echo ""
    if confirm "Analisar /nix/store"; then
        sudo du -sh /nix/store/*/ 2>/dev/null | sort -hr | head -15 | while read size dir; do
            echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
        done
    fi
}

find_large_files() {
    header "9. Procurando Arquivos Grandes (>100MB)"
    
    log "Procurando em /home/$USER..."
    find "$REAL_HOME" -type f -size +100M 2>/dev/null | while read file; do
        local size=$(du -sh "$file" 2>/dev/null | cut -f1)
        echo -e "  ${YELLOW}$size${NC}\t$file"
    done | sort -hr | head -20
    
    echo ""
    log "Para remover arquivos específicos, use: rm <arquivo>"
}

find_duplicate_files() {
    header "10. Procurando Arquivos Duplicados"
    
    if command -v fdupes &> /dev/null; then
        log "Usando fdupes para encontrar duplicatas em $REAL_HOME..."
        if confirm "Procurar arquivos duplicados (pode demorar)"; then
            fdupes -r -S "$REAL_HOME" 2>/dev/null | head -50
        fi
    else
        warn "fdupes não instalado. Adicione ao seu configuration.nix:"
        echo -e "  ${CYAN}environment.systemPackages = with pkgs; [ fdupes ];${NC}"
    fi
}

#===============================================================================
# GIT REPOSITORIES CLEANUP
#===============================================================================

cleanup_git_repos() {
    header "15. Limpeza de Repositórios Git"
    
    local git_dir="${1:-$REAL_HOME/GITS}"
    
    if [[ ! -d "$git_dir" ]]; then
        warn "Diretório $git_dir não encontrado"
        return
    fi
    
    log "Analisando repositórios Git em $git_dir..."
    
    # Find all .git directories and their sizes
    log "Top 15 maiores pastas .git:"
    echo ""
    find "$git_dir" -name ".git" -type d 2>/dev/null | while read gitdir; do
        local size=$(du -sh "$gitdir" 2>/dev/null | cut -f1)
        local repo=$(dirname "$gitdir")
        echo -e "  ${CYAN}$size${NC}\t$(basename $repo)"
    done | sort -hr | head -15
    
    echo ""
    local total_git_size=$(find "$git_dir" -name ".git" -type d -exec du -sb {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
    log "Total em .git: $(format_size ${total_git_size:-0})"
    
    if confirm "Executar git gc --aggressive em todos os repos (compactar)"; then
        log "Compactando repositórios Git..."
        
        # Collect repos into array
        local repos=()
        while read -r gitdir; do
            repos+=("$gitdir")
        done < <(find "$git_dir" -name ".git" -type d 2>/dev/null)
        
        local total=${#repos[@]}
        local current=0
        
        for gitdir in "${repos[@]}"; do
            local repo=$(dirname "$gitdir")
            local repo_name=$(basename "$repo")
            
            ((current++))
            show_progress "$current" "$total" " $repo_name"
            
            (
                cd "$repo" 2>/dev/null || exit
                git reflog expire --expire=now --all 2>/dev/null || true
                git gc --aggressive --prune=now 2>/dev/null || true
            ) &>/dev/null
        done
        echo "" # Ensure newline after progress bar
        success "Repos Git compactados!"
    fi
    
    # Identify very large .git folders for special attention
    echo ""
    warn "Repositórios com .git > 1GB (considere remover histórico se são backups):"
    find "$git_dir" -name ".git" -type d 2>/dev/null | while read gitdir; do
        local size_bytes=$(du -sb "$gitdir" 2>/dev/null | cut -f1)
        if (( size_bytes > 1073741824 )); then  # > 1GB
            local size=$(du -sh "$gitdir" 2>/dev/null | cut -f1)
            local repo=$(dirname "$gitdir")
            echo -e "  ${RED}$size${NC}\t$(basename $repo)"
            echo -e "    ${YELLOW}→ Para remover histórico: rm -rf $gitdir${NC}"
        fi
    done
    
    echo ""
    log "Dica: Para repos de backup/arquivos, remover .git libera espaço imediatamente"
    log "      Mas você perderá o histórico de versões!"
}

cleanup_node_modules() {
    header "16. Limpeza de node_modules"
    
    local search_dir="${1:-$REAL_HOME}"
    
    log "Procurando node_modules em $search_dir..."
    
    local total_size=0
    local count=0
    
    echo ""
    find "$search_dir" -name "node_modules" -type d -prune 2>/dev/null | while read nmdir; do
        local size=$(du -sh "$nmdir" 2>/dev/null | cut -f1)
        local project=$(dirname "$nmdir")
        echo -e "  ${CYAN}$size${NC}\t$(basename $project)"
        ((count++)) || true
    done | sort -hr | head -20
    
    local total=$(find "$search_dir" -name "node_modules" -type d -prune 2>/dev/null | xargs -I{} du -sb {} 2>/dev/null | awk '{sum+=$1} END {print sum}')
    echo ""
    log "Total em node_modules: $(format_size ${total:-0})"
    
    if confirm "Remover TODOS os node_modules (você pode reinstalar com npm install)"; then
        local dirs=()
        while read -r d; do
            dirs+=("$d")
        done < <(find "$search_dir" -name "node_modules" -type d -prune 2>/dev/null)
        
        local total=${#dirs[@]}
        local current=0
        
        for d in "${dirs[@]}"; do
            ((current++))
            local label=" $(basename $(dirname "$d"))"
            show_progress "$current" "$total" "$label"
            rm -rf "$d" 2>/dev/null || true
        done
        echo "" # Newline
        success "node_modules removidos!"
        TOTAL_FREED=$((TOTAL_FREED + ${total:-0}))
    fi
}


cleanup_flatpak() {
    header "18. Limpeza de Flatpak"
    
    if ! command -v flatpak &> /dev/null; then
        log "Flatpak não instalado, pulando..."
        return
    fi
    
    local flatpak_size=$(du -sh /var/lib/flatpak 2>/dev/null | cut -f1)
    log "Flatpak total: $flatpak_size"
    
    echo ""
    log "Apps Flatpak instalados:"
    flatpak list --app 2>/dev/null | while read line; do
        echo -e "  ${CYAN}$line${NC}"
    done
    
    echo ""
    log "Runtimes não utilizados:"
    flatpak uninstall --unused 2>/dev/null | head -10 || log "Nenhum runtime não utilizado"
    
    if confirm "Remover runtimes Flatpak não utilizados"; then
        flatpak uninstall --unused -y 2>/dev/null || true
        success "Runtimes não utilizados removidos!"
    fi
    
    # Clean flatpak cache
    if [[ -d "$REAL_HOME/.var/app" ]]; then
        log "Cache de apps Flatpak em ~/.var/app:"
        du -sh "$REAL_HOME/.var/app"/* 2>/dev/null | sort -hr | head -10 | while read size path; do
            echo -e "  ${CYAN}$size${NC}\t$(basename "$path")"
        done
        
        if confirm "Limpar caches dos apps Flatpak"; then
            for app_dir in "$REAL_HOME/.var/app"/*; do
                if [[ -d "$app_dir/cache" ]]; then
                    rm -rf "$app_dir/cache"/* 2>/dev/null || true
                fi
            done
            success "Caches Flatpak limpos!"
        fi
    fi
}

#===============================================================================
# 5. LIMPEZA ESPECÍFICA DO NIRI/QUICKSHELL
#===============================================================================

cleanup_wayland_caches() {
    header "11. Limpeza de Caches Wayland/Niri/Quickshell"
    
    local wayland_caches=(
        "$REAL_HOME/.cache/niri"
        "$REAL_HOME/.cache/quickshell"
        "$REAL_HOME/.cache/mesa_shader_cache"
        "$REAL_HOME/.cache/nvidia"
        "$REAL_HOME/.cache/radv_builtin_shaders64"
        "$REAL_HOME/.local/share/recently-used.xbel"
        "$REAL_HOME/.cache/fontconfig"
    )
    
    for dir in "${wayland_caches[@]}"; do
        if [[ -e "$dir" ]]; then
            if [[ -d "$dir" ]]; then
                local size=$(get_size "$dir")
                if (( size > 0 )); then
                    log "$(basename $dir): $(format_size $size)"
                    if confirm "Limpar $dir"; then
                        rm -rf "${dir:?}"/* 2>/dev/null || true
                        success "$dir limpo"
                        TOTAL_FREED=$((TOTAL_FREED + size))
                    fi
                fi
            else
                rm -f "$dir" 2>/dev/null || true
            fi
        fi
    done
}

#===============================================================================
# 6. LIMPEZA DE DOCKER/PODMAN (se existir)
#===============================================================================

cleanup_containers() {
    header "12. Limpeza de Docker/Podman"
    
    if command -v docker &> /dev/null; then
        local docker_size=$(docker system df 2>/dev/null | grep -E "^(Images|Containers|Volumes)" | awk '{sum += $4} END {print sum}' || echo 0)
        log "Docker encontrado"
        if confirm "Executar docker system prune -a (remover tudo não usado)"; then
            docker system prune -af --volumes 2>&1 | tee -a "$LOG_FILE"
            success "Docker limpo"
        fi
    fi
    
    if command -v podman &> /dev/null; then
        log "Podman encontrado"
        if confirm "Executar podman system prune -a"; then
            podman system prune -af --volumes 2>&1 | tee -a "$LOG_FILE"
            success "Podman limpo"
        fi
    fi
}

#===============================================================================
# 7. LIMPEZA DE FERRAMENTAS DE DESENVOLVIMENTO
#===============================================================================

cleanup_dev_tools() {
    header "13. Limpeza de Ferramentas de Desenvolvimento"
    
    # 1. Extensões e Dados (Home Directories)
    local ide_dirs=(
        "$REAL_HOME/.vscode"
        "$REAL_HOME/.windsurf"
        "$REAL_HOME/.cursor"
    )
    
    for ide_dir in "${ide_dirs[@]}"; do
        if [[ -d "$ide_dir" ]]; then
            log "Verificando $(basename $ide_dir)..."
            # Limpeza segura de arquivos temporários de extensões sem confirmação explícita
            # ou inclua na confirmação abaixo se preferir
            rm -rf "$ide_dir/extensions/.obsolete" 2>/dev/null || true
            find "$ide_dir/extensions" -type d -name ".cache" -exec rm -rf {} \; 2>/dev/null || true
            find "$ide_dir/extensions" -type d -name "node_modules/.cache" -exec rm -rf {} \; 2>/dev/null || true
            find "$ide_dir" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
        fi
    done

    # 2. Caches de Aplicação (Config Directories)
    # Aqui residem os caches do Electron, GPU, etc.
    local ide_config_dirs=(
        "$REAL_HOME/.config/Code"
        "$REAL_HOME/.config/Windsurf"
        "$REAL_HOME/.config/Cursor"
        "$REAL_HOME/.config/VSCodium"
    )
    
    for config_dir in "${ide_config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            local size=$(get_size "$config_dir")
            log "Config/Cache $(basename $config_dir): $(format_size $size)"
            
            if confirm "Limpar caches do $(basename $config_dir)"; then
                # Lista de diretórios de cache comuns em Electron/VSCode-based
                local caches=(
                    "CachedData"
                    "CachedExtensionVSIXs"
                    "CachedExtensions"
                    "Code Cache"
                    "Crashpad"
                    "DawnCache"
                    "DawnGraphiteCache"
                    "DawnWebGPUCache"
                    "GPUCache"
                    "logs"
                    "Service Worker/CacheStorage"
                    "Service Worker/ScriptCache"
                    "blob_storage"
                    "Cache"
                )
                
                for cache in "${caches[@]}"; do
                    if [[ -d "$config_dir/$cache" ]]; then
                        rm -rf "$config_dir/$cache"/* 2>/dev/null || true
                    fi
                done
                
                success "Caches do $(basename $config_dir) limpos"
            fi
        fi
    done
    
    # Rust toolchains
    if command -v rustup &> /dev/null; then
        header "13.1 Limpeza do Rust"
        
        if [[ -d "$REAL_HOME/.rustup" ]]; then
            local size=$(get_size "$REAL_HOME/.rustup")
            log "Rustup: $(format_size $size)"
            
            log "Toolchains instalados:"
            rustup toolchain list 2>/dev/null | while read tc; do
                echo -e "  ${CYAN}$tc${NC}"
            done
            
            if confirm "Limpar downloads e caches do Rust"; then
                # Limpar downloads
                rustup self clean 2>/dev/null || true
                
                # Limpar target folders em projetos (opcional - pode ser muito agressivo)
                # find "$REAL_HOME" -name "target" -type d -path "*/.cargo/*" -prune -o -name "target" -type d -print 2>/dev/null
                
                success "Caches do Rust limpos"
            fi
            
            if confirm "Remover toolchains antigos (manter apenas stable)"; then
                # Listar e remover toolchains antigos exceto stable
                rustup toolchain list 2>/dev/null | grep -v "stable" | grep -v "default" | while read tc; do
                    log "Removendo toolchain: $tc"
                    rustup toolchain uninstall "$tc" 2>/dev/null || true
                done
                success "Toolchains antigos removidos"
            fi
        fi
    fi
    
    # Android SDK/Cache
    if [[ -d "$REAL_HOME/.android" ]]; then
        header "13.2 Limpeza do Android"
        
        local size=$(get_size "$REAL_HOME/.android")
        log "Android: $(format_size $size)"
        
        if confirm "Limpar caches do Android"; then
            rm -rf "$REAL_HOME/.android/cache" 2>/dev/null || true
            rm -rf "$REAL_HOME/.android/build-cache" 2>/dev/null || true
            rm -rf "$REAL_HOME/.android/.android/cache" 2>/dev/null || true
            
            # AVD cache (imagens temporárias)
            find "$REAL_HOME/.android/avd" -name "*.img.qcow2" -type f -delete 2>/dev/null || true
            
            success "Caches do Android limpos"
        fi
        
        # Listar AVDs grandes
        if [[ -d "$REAL_HOME/.android/avd" ]]; then
            log "AVDs encontrados:"
            du -sh "$REAL_HOME/.android/avd"/*/ 2>/dev/null | sort -hr | while read size dir; do
                echo -e "  ${YELLOW}$size${NC}\t$(basename $dir)"
            done
        fi
    fi
    
    # Dart/Flutter
    if [[ -d "$REAL_HOME/.pub-cache" ]]; then
        local size=$(get_size "$REAL_HOME/.pub-cache")
        log "Pub cache (Dart/Flutter): $(format_size $size)"
        if confirm "Limpar cache do Dart/Flutter"; then
            rm -rf "$REAL_HOME/.pub-cache/hosted"/*/.cache 2>/dev/null || true
            flutter clean 2>/dev/null || true
            success "Cache do Dart/Flutter limpo"
        fi
    fi
    
    # Dart server
    if [[ -d "$REAL_HOME/.dartServer" ]]; then
        local size=$(get_size "$REAL_HOME/.dartServer")
        log "Dart Server: $(format_size $size)"
        if confirm "Limpar Dart Server cache"; then
            rm -rf "$REAL_HOME/.dartServer" 2>/dev/null || true
            success "Dart Server cache limpo"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

analyze_config_dir() {
    header "14. Análise do ~/.config"
    
    log "Top 20 consumidores em ~/.config:"
    echo ""
    du -sh "$REAL_HOME/.config"/* 2>/dev/null | sort -hr | head -20 | while read size dir; do
        echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
    done
    
    echo ""
    
    # Sugerir diretórios grandes para limpeza
    local large_dirs=$(du -sb "$REAL_HOME/.config"/* 2>/dev/null | awk '$1 > 104857600 {print $2}')  # > 100MB
    
    if [[ -n "$large_dirs" ]]; then
        warn "Diretórios maiores que 100MB encontrados:"
        for dir in $large_dirs; do
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            local name=$(basename "$dir")
            echo -e "  ${YELLOW}$size${NC}\t$name"
            
            # Sugestões específicas
            case "$name" in
                "google-chrome"|"chromium")
                    echo -e "    ${CYAN}→ Considere limpar cache do navegador${NC}"
                    ;;
                "Code"|"VSCodium")
                    echo -e "    ${CYAN}→ Considere: rm -rf ~/.config/$name/Cache ~/.config/$name/CachedData${NC}"
                    ;;
                "discord")
                    echo -e "    ${CYAN}→ Considere: rm -rf ~/.config/$name/Cache${NC}"
                    ;;
                "Slack")
                    echo -e "    ${CYAN}→ Considere: rm -rf ~/.config/$name/Cache ~/.config/$name/Service Worker${NC}"
                    ;;
                "spotify")
                    echo -e "    ${CYAN}→ Considere: rm -rf ~/.config/$name/Users/*/cache${NC}"
                    ;;
            esac
        done
    fi
    
    # Limpeza automática de caches conhecidos em .config
    if confirm "Limpar caches conhecidos em ~/.config"; then
        # Electron apps comum
        for app_dir in "$REAL_HOME/.config"/*; do
            if [[ -d "$app_dir/Cache" ]]; then
                rm -rf "$app_dir/Cache" 2>/dev/null || true
            fi
            if [[ -d "$app_dir/GPUCache" ]]; then
                rm -rf "$app_dir/GPUCache" 2>/dev/null || true
            fi
            if [[ -d "$app_dir/Code Cache" ]]; then
                rm -rf "$app_dir/Code Cache" 2>/dev/null || true
            fi
            if [[ -d "$app_dir/CachedData" ]]; then
                rm -rf "$app_dir/CachedData" 2>/dev/null || true
            fi
        done
        success "Caches em ~/.config limpos"
    fi
}

#===============================================================================
# 8. MODO AGRESSIVO
#===============================================================================

aggressive_cleanup() {
    header "MODO AGRESSIVO - Limpeza Máxima"
    
    warn "Este modo remove TODOS os caches e pode requerer re-download de dependências!"
    
    if confirm "Continuar com limpeza agressiva"; then
        # Remover TODAS as gerações exceto a atual
        log "Removendo TODAS gerações antigas..."
        sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>/dev/null || true
        nix-env --delete-generations old 2>/dev/null || true
        
        # Limpar completamente o cache
        log "Limpando todos os caches..."
        rm -rf "$REAL_HOME/.cache"/* 2>/dev/null || true
        
        # GC agressivo
        log "Executando GC agressivo..."
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
        
        # Remover derivações result
        log "Removendo symlinks result..."
        find "$REAL_HOME" -maxdepth 3 -name "result" -type l -delete 2>/dev/null || true
        
        success "Limpeza agressiva concluída!"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

show_help() {
    echo -e "${BOLD}NixOS Disk Cleanup Script${NC}"
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  -h, --help       Mostrar esta ajuda"
    echo "  -d, --dry-run    Simular limpeza (não remove nada)"
    echo "  -a, --aggressive Modo agressivo (limpeza máxima)"
    echo "  -y, --yes        Confirmar todas as ações automaticamente"
    echo ""
}

main() {
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -a|--aggressive)
                AGGRESSIVE=true
                shift
                ;;
            -y|--yes)
                # Sobrescrever confirm para sempre retornar true
                confirm() { return 0; }
                shift
                ;;
            *)
                error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    clear
    echo -e "${BOLD}${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║         NixOS Disk Cleanup - Liberação de Espaço             ║"
    echo "║              Para Niri + Quickshell                          ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Iniciando análise do disco..."
    log "Log salvo em: $LOG_FILE"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "MODO DRY-RUN: Nenhuma alteração será feita"
    fi
    
    # Mostrar uso atual
    show_disk_usage
    
    # Executar limpezas
    if [[ "$AGGRESSIVE" == true ]]; then
        aggressive_cleanup
    else
        cleanup_nix_generations
        cleanup_nix_store
        # optimize_nix_store  # Descomentado se quiser (demora muito)
        cleanup_user_caches
        cleanup_browser_caches
        cleanup_package_caches
        cleanup_temp_files
        cleanup_wayland_caches
        cleanup_containers
        cleanup_dev_tools
        analyze_config_dir
        cleanup_git_repos
        cleanup_node_modules
        cleanup_flatpak
    fi
    
    # Análise final
    echo ""
    if confirm "Mostrar análise de grandes consumidores"; then
        analyze_disk_usage
        find_large_files
    fi
    
    # Resumo
    header "Resumo Final"
    show_disk_usage
    
    success "Limpeza concluída!"
    log "Total estimado liberado: $(format_size $TOTAL_FREED)"
    log "Log completo em: $LOG_FILE"
    
    echo ""
    echo -e "${YELLOW}Dicas extras para liberar mais espaço:${NC}"
    echo "  1. Execute: sudo nix-store --optimise"
    echo "  2. Revise projetos antigos em ~/GITS"
    echo "  3. Verifique ~/.local/share para apps que não usa mais"
    echo "  4. Use 'ncdu /' para análise interativa"
    echo ""
}

main "$@"
