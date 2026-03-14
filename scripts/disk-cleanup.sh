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
    local s
    s=$(du -sb "$1" 2>/dev/null | cut -f1)
    echo "${s:-0}"
}

# Reliably empty a directory (handles dotfiles, measures freed bytes)
# Usage: safe_clean_dir "/path/to/dir" [exclude_pattern...]
# Sets LAST_FREED to actual bytes freed
LAST_FREED=0
safe_clean_dir() {
    local dir="$1"; shift
    local excludes=("$@")
    [[ -d "$dir" ]] || { LAST_FREED=0; return 1; }
    local before after
    before=$(get_size "$dir")
    if [[ ${#excludes[@]} -gt 0 ]]; then
        # Build find exclusion args
        local find_args=(find "$dir" -mindepth 1 -maxdepth 1)
        for ex in "${excludes[@]}"; do
            find_args+=(! -name "$ex")
        done
        "${find_args[@]}" -exec rm -rf {} + 2>/dev/null || true
    else
        find "$dir" -mindepth 1 -delete 2>/dev/null || \
            find "$dir" -mindepth 1 -exec rm -rf {} + 2>/dev/null || true
    fi
    after=$(get_size "$dir")
    LAST_FREED=$(( before - after ))
    (( LAST_FREED < 0 )) && LAST_FREED=0
    return 0
}

format_size() {
    local bytes=${1:-0}
    (( bytes < 0 )) && bytes=0
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
    local current=$1
    local total=$2
    local label="${3:-}"
    (( total == 0 )) && return
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    local bar="["
    if [ $filled -gt 0 ]; then
        bar+=$(printf "%${filled}s" | tr ' ' '=')
    fi
    if [ $empty -gt 0 ]; then
        bar+=$(printf "%${empty}s" | tr ' ' '.')
    fi
    bar+="]"
    
    echo -ne "\r${CYAN}${bar} ${percent}% ${NC}${label}"
    
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
                    if [[ "$dir" == "$REAL_HOME/.cache" ]]; then
                        # Preserve critical cache subdirectories
                        safe_clean_dir "$dir" "p10k-instant-prompt-*" "fontconfig" "zsh-init-cache" "nix"
                    else
                        safe_clean_dir "$dir"
                    fi
                    if (( LAST_FREED > 0 )); then
                        success "Limpo: $dir — liberado $(format_size $LAST_FREED)"
                        TOTAL_FREED=$((TOTAL_FREED + LAST_FREED))
                    else
                        warn "Nada removido em $dir (permissão negada ou já vazio)"
                    fi
                fi
            fi
        fi
    done
}

cleanup_browser_caches() {
    header "5. Limpeza de Caches de Navegadores"
    
    # Firefox — measure only cache2 dirs, not entire profile
    if [[ -d "$REAL_HOME/.mozilla/firefox" ]]; then
        local firefox_caches=()
        while IFS= read -r d; do
            firefox_caches+=("$d")
        done < <(find "$REAL_HOME/.mozilla/firefox" -type d -name "cache2" 2>/dev/null)
        if [[ ${#firefox_caches[@]} -gt 0 ]]; then
            local size=0
            for fc in "${firefox_caches[@]}"; do
                size=$((size + $(get_size "$fc")))
            done
            log "Firefox cache (cache2): $(format_size $size)"
            if confirm "Limpar cache do Firefox"; then
                local before_ff=$(get_size "$REAL_HOME/.mozilla/firefox")
                # Use -prune to avoid descending into deleted dirs (prevents find race)
                find "$REAL_HOME/.mozilla/firefox" -type d -name "cache2" -prune -exec rm -rf {} + 2>/dev/null || true
                find "$REAL_HOME/.mozilla/firefox" -name "*.sqlite" -type f -exec sqlite3 {} "VACUUM;" \; 2>/dev/null || true
                local after_ff=$(get_size "$REAL_HOME/.mozilla/firefox")
                local freed_ff=$(( before_ff - after_ff ))
                (( freed_ff < 0 )) && freed_ff=0
                if (( freed_ff > 0 )); then
                    success "Cache do Firefox limpo — liberado $(format_size $freed_ff)"
                    TOTAL_FREED=$((TOTAL_FREED + freed_ff))
                else
                    warn "Cache do Firefox: nada a limpar"
                fi
            fi
        fi
    fi
    
    # Chrome/Chromium/Vivaldi — measure only cache dirs, not entire profile
    for browser_dir in "$REAL_HOME/.config/google-chrome" "$REAL_HOME/.config/chromium" "$REAL_HOME/.config/vivaldi"; do
        if [[ -d "$browser_dir" ]]; then
            local cache_size=0
            local browser_name=$(basename "$browser_dir")
            for cname in Cache "Code Cache" GPUCache "Service Worker"; do
                while IFS= read -r cdir; do
                    cache_size=$((cache_size + $(get_size "$cdir")))
                done < <(find "$browser_dir" -type d -name "$cname" -prune 2>/dev/null)
            done
            log "$browser_name (caches): $(format_size $cache_size)"
            
            if (( cache_size > 0 )) && confirm "Limpar cache do $browser_name"; then
                local before_br=$(get_size "$browser_dir")
                for cname in Cache "Code Cache" GPUCache "Service Worker"; do
                    find "$browser_dir" -type d -name "$cname" -prune -exec rm -rf {} + 2>/dev/null || true
                done
                local after_br=$(get_size "$browser_dir")
                local freed_br=$(( before_br - after_br ))
                (( freed_br < 0 )) && freed_br=0
                if (( freed_br > 0 )); then
                    success "Cache do $browser_name limpo — liberado $(format_size $freed_br)"
                    TOTAL_FREED=$((TOTAL_FREED + freed_br))
                else
                    warn "Cache do $browser_name: nada efetivamente removido"
                fi
            fi
        fi
    done
}

cleanup_package_caches() {
    header "6. Limpeza de Caches de Pacotes"
    
    # Helper: clean a cache dir and track freed bytes accurately
    _clean_pkg_cache() {
        local label="$1" dir="$2" cmd="$3"
        if [[ -d "$dir" ]]; then
            local before=$(get_size "$dir")
            log "$label: $(format_size $before)"
            if confirm "Limpar cache do $label"; then
                eval "$cmd" 2>/dev/null || true
                local after=$(get_size "$dir")
                local freed=$(( before - after ))
                (( freed < 0 )) && freed=0
                if (( freed > 0 )); then
                    success "Cache do $label limpo — liberado $(format_size $freed)"
                    TOTAL_FREED=$((TOTAL_FREED + freed))
                else
                    warn "Cache do $label: nada efetivamente removido"
                fi
            fi
        fi
    }

    _clean_pkg_cache "NPM" "$REAL_HOME/.npm" \
        "npm cache clean --force 2>/dev/null || safe_clean_dir '$REAL_HOME/.npm/_cacache'"
    
    _clean_pkg_cache "Yarn" "$REAL_HOME/.cache/yarn" \
        "yarn cache clean 2>/dev/null || rm -rf '$REAL_HOME/.cache/yarn'"
    
    _clean_pkg_cache "Pip" "$REAL_HOME/.cache/pip" \
        "pip cache purge 2>/dev/null || rm -rf '$REAL_HOME/.cache/pip'"
    
    # Cargo cache — includes both registry/cache and registry/src
    if [[ -d "$REAL_HOME/.cargo/registry/cache" ]]; then
        local cargo_cache_size=$(get_size "$REAL_HOME/.cargo/registry/cache")
        local cargo_src_size=0
        [[ -d "$REAL_HOME/.cargo/registry/src" ]] && cargo_src_size=$(get_size "$REAL_HOME/.cargo/registry/src")
        local cargo_total=$((cargo_cache_size + cargo_src_size))
        log "Cargo cache: $(format_size $cargo_total)"
        if confirm "Limpar cache do Cargo"; then
            safe_clean_dir "$REAL_HOME/.cargo/registry/cache"
            local freed_cargo=$LAST_FREED
            safe_clean_dir "$REAL_HOME/.cargo/registry/src"
            freed_cargo=$((freed_cargo + LAST_FREED))
            if (( freed_cargo > 0 )); then
                success "Cache do Cargo limpo — liberado $(format_size $freed_cargo)"
                TOTAL_FREED=$((TOTAL_FREED + freed_cargo))
            else
                warn "Cache do Cargo: nada efetivamente removido"
            fi
        fi
    fi

    # Go cache
    if [[ -d "$REAL_HOME/go/pkg" ]]; then
        local go_before=$(get_size "$REAL_HOME/go/pkg")
        log "Go modules cache: $(format_size $go_before)"
        if confirm "Limpar cache do Go"; then
            go clean -cache -modcache 2>/dev/null || safe_clean_dir "$REAL_HOME/go/pkg"
            local go_after=$(get_size "$REAL_HOME/go/pkg")
            local go_freed=$(( go_before - go_after ))
            (( go_freed < 0 )) && go_freed=0
            if (( go_freed > 0 )); then
                success "Cache do Go limpo — liberado $(format_size $go_freed)"
                TOTAL_FREED=$((TOTAL_FREED + go_freed))
            else
                warn "Cache do Go: nada efetivamente removido"
            fi
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
            local flatpak_freed=0
            for app_dir in "$REAL_HOME/.var/app"/*; do
                if [[ -d "$app_dir/cache" ]]; then
                    safe_clean_dir "$app_dir/cache"
                    flatpak_freed=$((flatpak_freed + LAST_FREED))
                fi
            done
            if (( flatpak_freed > 0 )); then
                success "Caches Flatpak limpos — liberado $(format_size $flatpak_freed)"
                TOTAL_FREED=$((TOTAL_FREED + flatpak_freed))
            else
                warn "Caches Flatpak: nada efetivamente removido"
            fi
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
                        safe_clean_dir "$dir"
                        if (( LAST_FREED > 0 )); then
                            success "$dir limpo — liberado $(format_size $LAST_FREED)"
                            TOTAL_FREED=$((TOTAL_FREED + LAST_FREED))
                        else
                            warn "$dir: nada efetivamente removido"
                        fi
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
            rm -rf "$ide_dir/extensions/.obsolete" 2>/dev/null || true
            # Use -prune to prevent find race when deleting parent dirs
            find "$ide_dir/extensions" -type d -name ".cache" -prune -exec rm -rf {} + 2>/dev/null || true
            find "$ide_dir/extensions" -type d -name "node_modules" -path "*/.cache/*" -prune -exec rm -rf {} + 2>/dev/null || true
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
                local before_ide=$(get_size "$config_dir")
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
                    "blob_storage"
                    "Cache"
                )
                
                for cache in "${caches[@]}"; do
                    [[ -d "$config_dir/$cache" ]] && safe_clean_dir "$config_dir/$cache"
                done
                # Service Worker subdirs (path contains slash, handle separately)
                for sw_sub in CacheStorage ScriptCache; do
                    [[ -d "$config_dir/Service Worker/$sw_sub" ]] && safe_clean_dir "$config_dir/Service Worker/$sw_sub"
                done
                
                local after_ide=$(get_size "$config_dir")
                local freed_ide=$(( before_ide - after_ide ))
                (( freed_ide < 0 )) && freed_ide=0
                if (( freed_ide > 0 )); then
                    success "Caches do $(basename $config_dir) limpos — liberado $(format_size $freed_ide)"
                    TOTAL_FREED=$((TOTAL_FREED + freed_ide))
                else
                    warn "Caches do $(basename $config_dir): nada efetivamente removido"
                fi
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
        local config_before=$(get_size "$REAL_HOME/.config")
        # Electron apps comum
        for app_dir in "$REAL_HOME/.config"/*; do
            for cname in Cache GPUCache "Code Cache" CachedData; do
                [[ -d "$app_dir/$cname" ]] && safe_clean_dir "$app_dir/$cname"
            done
        done
        local config_after=$(get_size "$REAL_HOME/.config")
        local config_freed=$(( config_before - config_after ))
        (( config_freed < 0 )) && config_freed=0
        if (( config_freed > 0 )); then
            success "Caches em ~/.config limpos — liberado $(format_size $config_freed)"
            TOTAL_FREED=$((TOTAL_FREED + config_freed))
        else
            warn "Caches em ~/.config: nada efetivamente removido"
        fi
    fi
}

#===============================================================================
# 8. MODO AGRESSIVO
#===============================================================================

aggressive_cleanup() {
    header "MODO AGRESSIVO - Limpeza Máxima"
    
    warn "Este modo remove TODOS os caches e pode requerer re-download de dependências!"
    
    if confirm "Continuar com limpeza agressiva"; then
        local agg_before=$(df --output=used / | tail -1)
        
        # Remover TODAS as gerações exceto a atual
        log "Removendo TODAS gerações antigas..."
        sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>/dev/null || true
        nix-env --delete-generations old 2>/dev/null || true
        
        # Limpar completamente o cache (preserving critical dirs)
        log "Limpando todos os caches..."
        safe_clean_dir "$REAL_HOME/.cache" "p10k-instant-prompt-*" "nix"
        
        # GC agressivo
        log "Executando GC agressivo..."
        sudo nix-collect-garbage -d 2>&1 | tee -a "$LOG_FILE"
        nix-collect-garbage -d 2>&1 | tee -a "$LOG_FILE" || true
        
        # Remover derivações result
        log "Removendo symlinks result..."
        find "$REAL_HOME" -maxdepth 3 -name "result" -type l -delete 2>/dev/null || true
        
        local agg_after=$(df --output=used / | tail -1)
        local agg_freed_kb=$(( agg_before - agg_after ))
        (( agg_freed_kb < 0 )) && agg_freed_kb=0
        local agg_freed_bytes=$(( agg_freed_kb * 1024 ))
        success "Limpeza agressiva concluída! Liberado: $(format_size $agg_freed_bytes)"
        TOTAL_FREED=$((TOTAL_FREED + agg_freed_bytes))
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
