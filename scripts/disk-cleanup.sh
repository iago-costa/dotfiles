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
# 9. LIMPEZA DE GITS (~89 GB)
#===============================================================================

cleanup_gits_dir() {
    local gits_dir="${1:-$REAL_HOME/GITS}"
    header "19. Limpeza de ~/GITS"

    if [[ ! -d "$gits_dir" ]]; then
        warn "Diretório $gits_dir não encontrado, pulando..."
        return
    fi

    local gits_total=$(get_size "$gits_dir")
    log "Tamanho total de ~/GITS: $(format_size $gits_total)"
    echo ""

    # ── Análise prévia ──────────────────────────────────────────────
    log "Top 10 maiores subpastas:"
    du -sh "$gits_dir"/*/  "$gits_dir"/*/*/ 2>/dev/null | sort -hr | head -10 | while read size dir; do
        echo -e "  ${CYAN}$size${NC}\t$dir"
    done
    echo ""

    # ── node_modules ────────────────────────────────────────────────
    local nm_total
    nm_total=$(find "$gits_dir" -name "node_modules" -type d -prune \
        -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if (( nm_total > 0 )); then
        log "node_modules encontrados: $(format_size $nm_total)"
        find "$gits_dir" -name "node_modules" -type d -prune \
            -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | while read size d; do
            echo -e "  ${YELLOW}$size${NC}\t$(dirname $d | sed "s|$gits_dir/||")"
        done
        if confirm "Remover TODOS os node_modules em ~/GITS (reinstale com npm/pnpm install)"; then
            local nm_before=$(get_size "$gits_dir")
            find "$gits_dir" -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null || true
            local nm_freed=$(( nm_before - $(get_size "$gits_dir") ))
            (( nm_freed < 0 )) && nm_freed=0
            success "node_modules removidos — liberado $(format_size $nm_freed)"
            TOTAL_FREED=$(( TOTAL_FREED + nm_freed ))
        fi
    fi
    echo ""

    # ── Rust target/ ────────────────────────────────────────────────
    local rust_total
    rust_total=$(find "$gits_dir" -name "target" -type d -prune \
        -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if (( rust_total > 0 )); then
        log "Diretórios Rust target/: $(format_size $rust_total)"
        find "$gits_dir" -name "target" -type d -prune \
            -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | while read size d; do
            echo -e "  ${YELLOW}$size${NC}\t$(dirname $d | sed "s|$gits_dir/||")"
        done
        if confirm "Remover todos os target/ de Rust em ~/GITS (recompile com cargo build)"; then
            local rt_before=$(get_size "$gits_dir")
            find "$gits_dir" -name "target" -type d -prune -exec rm -rf {} + 2>/dev/null || true
            local rt_freed=$(( rt_before - $(get_size "$gits_dir") ))
            (( rt_freed < 0 )) && rt_freed=0
            success "target/ removidos — liberado $(format_size $rt_freed)"
            TOTAL_FREED=$(( TOTAL_FREED + rt_freed ))
        fi
    fi
    echo ""

    # ── Python __pycache__ e .pyc ────────────────────────────────────
    local py_total
    py_total=$(find "$gits_dir" \( -name "__pycache__" -type d -o -name "*.egg-info" -type d -o -name ".pytest_cache" -type d \) \
        -prune -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if (( py_total > 0 )); then
        log "Caches Python (__pycache__, .egg-info, .pytest_cache): $(format_size $py_total)"
        if confirm "Remover caches Python em ~/GITS"; then
            local py_before=$(get_size "$gits_dir")
            find "$gits_dir" -type d \( -name "__pycache__" -o -name "*.egg-info" -o -name ".pytest_cache" \) \
                -prune -exec rm -rf {} + 2>/dev/null || true
            find "$gits_dir" -name "*.pyc" -delete 2>/dev/null || true
            local py_freed=$(( py_before - $(get_size "$gits_dir") ))
            (( py_freed < 0 )) && py_freed=0
            success "Caches Python removidos — liberado $(format_size $py_freed)"
            TOTAL_FREED=$(( TOTAL_FREED + py_freed ))
        fi
    fi
    echo ""

    # ── Build artifacts genéricos ────────────────────────────────────
    log "Outros artefatos de build:"
    local build_total
    build_total=$(find "$gits_dir" -type d \( -name "dist" -o -name "build" -o -name ".gradle" -o -name ".dart_tool" \) \
        -prune -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    log "  dist/, build/, .gradle/, .dart_tool/: $(format_size $build_total)"
    if confirm "Remover diretórios dist/, build/, .gradle/, .dart_tool/ em ~/GITS"; then
        local bd_before=$(get_size "$gits_dir")
        find "$gits_dir" -type d \( -name "dist" -o -name "build" -o -name ".gradle" -o -name ".dart_tool" \) \
            -prune -exec rm -rf {} + 2>/dev/null || true
        local bd_freed=$(( bd_before - $(get_size "$gits_dir") ))
        (( bd_freed < 0 )) && bd_freed=0
        success "Artefatos de build removidos — liberado $(format_size $bd_freed)"
        TOTAL_FREED=$(( TOTAL_FREED + bd_freed ))
    fi
    echo ""

    # ── Compactar histórico git ──────────────────────────────────────
    local git_total
    git_total=$(find "$gits_dir" -name ".git" -type d -prune \
        -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    log "Total em pastas .git: $(format_size $git_total)"
    log "Top 10 maiores .git:"
    find "$gits_dir" -name ".git" -type d -prune \
        -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | while read size d; do
        echo -e "  ${CYAN}$size${NC}\t$(basename $(dirname $d))"
    done
    if confirm "Compactar histórico git em todos os repos (git gc --aggressive --prune=now)"; then
        local gc_before=$(get_size "$gits_dir")
        local repos=(); while read -r gd; do repos+=("$(dirname "$gd")"); done \
            < <(find "$gits_dir" -name ".git" -type d -prune 2>/dev/null)
        local total=${#repos[@]}; local current=0
        for repo in "${repos[@]}"; do
            ((current++))
            show_progress "$current" "$total" " $(basename $repo)"
            (
                cd "$repo" 2>/dev/null || exit
                git reflog expire --expire=now --all 2>/dev/null || true
                git gc --aggressive --prune=now 2>/dev/null || true
            ) &>/dev/null
        done
        echo ""
        local gc_freed=$(( gc_before - $(get_size "$gits_dir") ))
        (( gc_freed < 0 )) && gc_freed=0
        success "Repos compactados — liberado $(format_size $gc_freed)"
        TOTAL_FREED=$(( TOTAL_FREED + gc_freed ))
    fi
    echo ""

    # ── Arquivos grandes suspeitos (> 100 MB, excluindo VMs/ISOs) ───
    log "Arquivos > 100 MB em ~/GITS (excluindo .git internos):"
    find "$gits_dir" -type f -size +100M ! -path "*/.git/objects/*" 2>/dev/null \
        | xargs -I{} du -sh {} 2>/dev/null | sort -hr | head -15 | while read size f; do
        echo -e "  ${RED}$size${NC}\t$f"
    done
    echo ""
    log "Para remover arquivos específicos acima: rm <arquivo>"
}

#===============================================================================
# 10. LIMPEZA DE VMs (~/VMs + ~/QEMU VMs)
#===============================================================================

_cleanup_vm_dir() {
    local vm_dir="$1"
    local label="$2"

    if [[ ! -d "$vm_dir" ]]; then
        warn "$label não encontrado, pulando..."
        return
    fi

    local vm_total=$(get_size "$vm_dir")
    log "$label: $(format_size $vm_total)"
    echo ""

    # Listar imagens e tamanhos
    log "Imagens de disco encontradas:"
    find "$vm_dir" -maxdepth 3 -type f \(
        -name "*.qcow2" -o -name "*.vmdk" -o -name "*.vdi" -o -name "*.raw" -o -name "*.img"
    \) 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -hr | while read size f; do
        fname=$(basename "$f")
        # Tamanho virtual vs real (para qcow2)
        virtual=""
        if [[ "$f" == *.qcow2 ]] && command -v qemu-img &>/dev/null; then
            virtual=$(qemu-img info "$f" 2>/dev/null | grep "virtual size" | awk '{print $3$4}')
            virtual=" (virtual: $virtual)"
        fi
        echo -e "  ${CYAN}$size${NC}\t$fname$virtual"
    done
    echo ""

    # Sparsificar imagens qcow2 com qemu-img convert
    local qcow2_files=()
    while IFS= read -r f; do
        qcow2_files+=("$f")
    done < <(find "$vm_dir" -maxdepth 3 -name "*.qcow2" -type f 2>/dev/null)

    if (( ${#qcow2_files[@]} > 0 )); then
        log "Compactar imagens qcow2 com qemu-img convert -c (sparsify + compress):"
        warn "A VM precisa estar DESLIGADA durante este processo!"
        for qimg in "${qcow2_files[@]}"; do
            local qsize=$(get_size "$qimg")
            echo -e "  ${YELLOW}$(format_size $qsize)${NC}\t$(basename $qimg)"
        done
        if confirm "Compactar e sparsificar imagens qcow2 em $label"; then
            for qimg in "${qcow2_files[@]}"; do
                local tmp="${qimg}.compacting"
                local before=$(get_size "$qimg")
                log "Compactando $(basename $qimg)..."
                if qemu-img convert -O qcow2 -c "$qimg" "$tmp" 2>/dev/null; then
                    local after=$(get_size "$tmp")
                    local freed=$(( before - after ))
                    if (( freed > 0 )); then
                        mv "$tmp" "$qimg"
                        success "$(basename $qimg) — liberado $(format_size $freed)"
                        TOTAL_FREED=$(( TOTAL_FREED + freed ))
                    else
                        rm -f "$tmp"
                        warn "$(basename $qimg) — sem ganho, mantendo original"
                    fi
                else
                    rm -f "$tmp"
                    warn "$(basename $qimg) — falha na compactação (VM pode estar em uso)"
                fi
            done
        fi
        echo ""
    fi

    # Listar e remover snapshots de VMs
    if command -v qemu-img &>/dev/null; then
        log "Snapshots em imagens qcow2:"
        local snap_count=0
        for qimg in "${qcow2_files[@]}"; do
            local snaps
            snaps=$(qemu-img snapshot -l "$qimg" 2>/dev/null | grep -v "^Snapshot list\|^ID\|^--" | grep -v '^[[:space:]]*$' || true)
            if [[ -n "$snaps" ]]; then
                snap_count=$(( snap_count + 1 ))
                echo -e "  ${YELLOW}$(basename "$qimg")${NC}:"
                while IFS= read -r snap_line; do echo "    $snap_line"; done <<< "$snaps"
            fi
        done
        (( snap_count == 0 )) && log "  (nenhum snapshot encontrado)"
        echo ""
    fi

    # Remover arquivos temporários/logs de VM
    local tmp_total
    tmp_total=$(find "$vm_dir" -maxdepth 4 -type f \(
        -name "*.log" -o -name "*.pid" -o -name "*.lock"
        -o -name "*.tmp" -o -name "*-QEMU_SNAPSHOT*"
    \) -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if (( tmp_total > 0 )); then
        log "Arquivos temporários/logs de VM: $(format_size $tmp_total)"
        if confirm "Remover logs e temporários de $label"; then
            find "$vm_dir" -maxdepth 4 -type f \(
                -name "*.log" -o -name "*.pid" -o -name "*.lock"
                -o -name "*.tmp" -o -name "*-QEMU_SNAPSHOT*"
            \) -delete 2>/dev/null || true
            success "Temporários de $label removidos"
            TOTAL_FREED=$(( TOTAL_FREED + tmp_total ))
        fi
    fi
    echo ""

    # Mostrar VMs gerenciadas pelo libvirt (informativo)
    if command -v virsh &>/dev/null; then
        log "VMs no libvirt (virsh):"
        virsh list --all 2>/dev/null | while read line; do
            echo -e "  ${CYAN}$line${NC}"
        done
        echo ""
        warn "Para liberar espaço máximo: desligue VMs que não usa e delete-as via virt-manager"
    fi
}

cleanup_vms() {
    header "20. Limpeza de VMs (~/VMs + ~/QEMU VMs)"

    _cleanup_vm_dir "$REAL_HOME/VMs" "~/VMs"
    _cleanup_vm_dir "$REAL_HOME/QEMU VMs" "~/QEMU VMs"

    # Verificar se as duas pastas têm VMs duplicadas
    if [[ -d "$REAL_HOME/VMs" && -d "$REAL_HOME/QEMU VMs" ]]; then
        echo ""
        log "Verificando possíveis duplicatas entre ~/VMs e ~/QEMU VMs:"
        local vms_names qemu_names
        vms_names=$(find "$REAL_HOME/VMs" -maxdepth 2 -name "*.qcow2" -o -name "*.vmdk" 2>/dev/null | xargs -I{} basename {} 2>/dev/null | sort)
        qemu_names=$(find "$REAL_HOME/QEMU VMs" -maxdepth 2 -name "*.qcow2" -o -name "*.vmdk" 2>/dev/null | xargs -I{} basename {} 2>/dev/null | sort)
        local dupes
        dupes=$(comm -12 <(echo "$vms_names") <(echo "$qemu_names") 2>/dev/null || true)
        if [[ -n "$dupes" ]]; then
            warn "Imagens com mesmo nome nas DUAS pastas (possíveis duplicatas):"
            echo "$dupes" | while read f; do
                echo -e "  ${RED}$f${NC}"
            done
            warn "Revise manualmente qual cópia é a atual e remova a outra!"
        else
            success "Nenhuma duplicata óbvia de nome detectada entre as duas pastas de VM"
        fi
    fi
}

#===============================================================================
# 11. LIMPEZA DE ~/.local
#===============================================================================

cleanup_local_dir() {
    header "21. Limpeza de ~/.local"

    local local_total=$(get_size "$REAL_HOME/.local")
    log "Tamanho total de ~/.local: $(format_size $local_total)"
    echo ""

    # ── Visão geral ─────────────────────────────────────────────────
    log "Top 15 maiores subpastas em ~/.local/share:"
    du -sh "$REAL_HOME/.local/share"/*/  2>/dev/null | sort -hr | head -15 | while read size dir; do
        echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
    done
    echo ""

    # ── Lixeira ─────────────────────────────────────────────────────
    if [[ -d "$REAL_HOME/.local/share/Trash" ]]; then
        local trash_size=$(get_size "$REAL_HOME/.local/share/Trash")
        log "Lixeira (Trash): $(format_size $trash_size)"
        if (( trash_size > 0 )) && confirm "Esvaziar a lixeira (~/.local/share/Trash)"; then
            rm -rf "$REAL_HOME/.local/share/Trash/files"/* 2>/dev/null || true
            rm -rf "$REAL_HOME/.local/share/Trash/info"/* 2>/dev/null || true
            success "Lixeira esvaziada — liberado $(format_size $trash_size)"
            TOTAL_FREED=$(( TOTAL_FREED + trash_size ))
        fi
    fi
    echo ""

    # ── Bottles / Wine ──────────────────────────────────────────────
    if [[ -d "$REAL_HOME/.local/share/bottles" ]]; then
        local bottles_total=$(get_size "$REAL_HOME/.local/share/bottles")
        log "Bottles total: $(format_size $bottles_total)"
        echo ""

        # Runners (versões Wine)
        if [[ -d "$REAL_HOME/.local/share/bottles/runners" ]]; then
            log "Wine runners instalados:"
            du -sh "$REAL_HOME/.local/share/bottles/runners"/*/  2>/dev/null | sort -hr | while read size dir; do
                echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
            done
            warn "Remova runners antigos manualmente: rm -rf ~/.local/share/bottles/runners/NOME"
        fi
        echo ""

        # Wine prefixes (bottles)
        if [[ -d "$REAL_HOME/.local/share/bottles/bottles" ]]; then
            log "Wine prefixes (bottles):"
            du -sh "$REAL_HOME/.local/share/bottles/bottles"/*/  2>/dev/null | sort -hr | while read size dir; do
                echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
            done
            echo ""

            # Limpar Temp e logs dentro dos bottles
            local bottle_tmp_total
            bottle_tmp_total=$(find "$REAL_HOME/.local/share/bottles/bottles" \
                -type d -name "Temp" -prune -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
            bottle_tmp_total=$(( bottle_tmp_total + $(find "$REAL_HOME/.local/share/bottles/bottles" \
                -maxdepth 6 -name "*.log" -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}') ))
            
            if (( bottle_tmp_total > 0 )); then
                log "Temp e logs dentro dos bottles: $(format_size $bottle_tmp_total)"
                if confirm "Limpar pastas Temp e logs dentro dos bottles Wine"; then
                    local bt_before=$(get_size "$REAL_HOME/.local/share/bottles/bottles")
                    # Limpar Temp do Windows dentro de cada bottle
                    find "$REAL_HOME/.local/share/bottles/bottles" \
                        -type d -name "Temp" -prune -exec rm -rf {} + 2>/dev/null || true
                    # Limpar logs de instalação
                    find "$REAL_HOME/.local/share/bottles/bottles" \
                        -maxdepth 6 -name "*.log" -delete 2>/dev/null || true
                    # Limpar Internet Files cache do Wine
                    find "$REAL_HOME/.local/share/bottles/bottles" \
                        -type d -name "Temporary Internet Files" -prune -exec rm -rf {} + 2>/dev/null || true
                    local bt_freed=$(( bt_before - $(get_size "$REAL_HOME/.local/share/bottles/bottles") ))
                    (( bt_freed < 0 )) && bt_freed=0
                    success "Temp e logs dos bottles removidos — liberado $(format_size $bt_freed)"
                    TOTAL_FREED=$(( TOTAL_FREED + bt_freed ))
                fi
            fi
        fi
        echo ""

        # DXVK state cache
        local dxvk_total
        dxvk_total=$(find "$REAL_HOME/.local/share/bottles" -name "*.dxvk-cache" -o -name "d3d*cache" \
            -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
        if (( dxvk_total > 0 )); then
            log "DXVK caches de shader: $(format_size $dxvk_total)"
            if confirm "Limpar caches DXVK (serão reconstruídos na próxima execução)"; then
                find "$REAL_HOME/.local/share/bottles" \
                    \( -name "*.dxvk-cache" -o -name "d3d*cache" \) -delete 2>/dev/null || true
                success "DXVK caches removidos"
                TOTAL_FREED=$(( TOTAL_FREED + dxvk_total ))
            fi
        fi
        echo ""
    fi

    # ── Flatpak (user) ───────────────────────────────────────────────
    for flatpak_dir in \
        "$REAL_HOME/.local/share/flatpak" \
        "/var/lib/flatpak"; do
        if [[ -d "$flatpak_dir" ]]; then
            local fp_size=$(get_size "$flatpak_dir")
            log "Flatpak ($flatpak_dir): $(format_size $fp_size)"
        fi
    done
    if command -v flatpak &>/dev/null; then
        if confirm "Remover runtimes Flatpak não utilizados"; then
            local fp_before=0
            [[ -d /var/lib/flatpak ]] && fp_before=$(get_size /var/lib/flatpak)
            flatpak uninstall --unused -y 2>/dev/null || true
            local fp_freed=$(( fp_before - $(get_size /var/lib/flatpak 2>/dev/null || echo $fp_before) ))
            (( fp_freed < 0 )) && fp_freed=0
            success "Runtimes Flatpak removidos — liberado $(format_size $fp_freed)"
            TOTAL_FREED=$(( TOTAL_FREED + fp_freed ))
        fi
    fi
    echo ""

    # ── ~/.var/app (Flatpak user data caches) ───────────────────────
    if [[ -d "$REAL_HOME/.var/app" ]]; then
        local var_app_size=$(get_size "$REAL_HOME/.var/app")
        log "~/.var/app (dados Flatpak): $(format_size $var_app_size)"
        du -sh "$REAL_HOME/.var/app"/*/  2>/dev/null | sort -hr | head -10 | while read size dir; do
            echo -e "  ${CYAN}$size${NC}\t$(basename $dir)"
        done
        if confirm "Limpar caches de apps Flatpak em ~/.var/app"; then
            local va_before=$(get_size "$REAL_HOME/.var/app")
            for app_dir in "$REAL_HOME/.var/app"/*/; do
                for sub in cache Cache "Code Cache" GPUCache; do
                    [[ -d "$app_dir/$sub" ]] && safe_clean_dir "$app_dir/$sub"
                done
            done
            local va_freed=$(( va_before - $(get_size "$REAL_HOME/.var/app") ))
            (( va_freed < 0 )) && va_freed=0
            success "Caches de apps Flatpak limpos — liberado $(format_size $va_freed)"
            TOTAL_FREED=$(( TOTAL_FREED + va_freed ))
        fi
        echo ""
    fi

    # ── Logs antigos em ~/.local/share ──────────────────────────────
    local old_logs_total
    old_logs_total=$(find "$REAL_HOME/.local/share" -name "*.log" -mtime +30 \
        -exec du -sb {} \; 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if (( old_logs_total > 0 )); then
        log "Logs > 30 dias em ~/.local/share: $(format_size $old_logs_total)"
        if confirm "Remover logs com mais de 30 dias em ~/.local/share"; then
            find "$REAL_HOME/.local/share" -name "*.log" -mtime +30 -delete 2>/dev/null || true
            success "Logs antigos removidos — liberado $(format_size $old_logs_total)"
            TOTAL_FREED=$(( TOTAL_FREED + old_logs_total ))
        fi
    fi
    echo ""

    # ── Recentemente usados (não liberativo, mas pode ser grande) ────
    local ru="$REAL_HOME/.local/share/recently-used.xbel"
    if [[ -f "$ru" ]]; then
        local ru_size=$(get_size "$ru")
        log "recently-used.xbel: $(format_size $ru_size)"
    fi

    # ── Estado final ─────────────────────────────────────────────────
    local local_after=$(get_size "$REAL_HOME/.local")
    local local_freed=$(( local_total - local_after ))
    (( local_freed < 0 )) && local_freed=0
    echo ""
    success "Limpeza de ~/.local concluída — total liberado nesta seção: $(format_size $local_freed)"
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
        cleanup_gits_dir
        cleanup_vms
        cleanup_local_dir
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
