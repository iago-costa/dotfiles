#!/bin/bash

# Auto-commit script with conventional commit messages
# Commits one file at a time with appropriate message based on file type and change
# Automatically updates GitHub token before pushing

# Usage: ./auto-commit.sh [OPTIONS]
# Options:
#   -s, --silent              Silent mode (no prompts, use defaults or provided args)
#   -l, --language LANG       Set commit language: en, es, pt (default: en)
#   -u, --username USER       GitHub username for token updates
#   -t, --update-tokens       Update GitHub tokens (requires -u)
#   -p, --preview             Show preview before committing
#   -h, --help                Show this help message
#
# Examples:
#   ./auto-commit.sh -s -l pt -u iago-costa -t
#   ./auto-commit.sh --silent --language es --preview
#   ./auto-commit.sh -s -l en

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub username (will be asked if not set)
GITHUB_USERNAME=""

# Commit message language
COMMIT_LANGUAGE="en"

# Script options
SILENT_MODE=false
SHOW_PREVIEW=false
UPDATE_TOKENS_ARG=false

# Common ignore patterns (applied even if not in .gitignore)
COMMON_IGNORE_PATTERNS=(
    "node_modules"
    ".env"
    ".env.local"
    ".env.*.local"
    "*.log"
    ".DS_Store"
    "Thumbs.db"
    "__pycache__"
    "*.pyc"
    ".pytest_cache"
    ".venv"
    "venv"
    "dist"
    "build"
    ".idea"
    ".vscode"
    "*.swp"
    "*.swo"
    ".cache"
    ".tmp"
    "tmp"
)

# Function to check if file matches common ignore patterns
is_commonly_ignored() {
    local file=$1
    
    for pattern in "${COMMON_IGNORE_PATTERNS[@]}"; do
        # Check if file path contains the pattern
        if [[ "$file" == *"$pattern"* ]] || [[ "$file" == *"/$pattern/"* ]] || [[ "$file" == "$pattern/"* ]]; then
            return 0  # File matches ignore pattern
        fi
        
        # Check wildcard patterns
        if [[ "$pattern" == *"*"* ]]; then
            # Convert pattern to regex-like matching
            if [[ "$file" == $pattern ]]; then
                return 0
            fi
        fi
    done
    
    return 1  # File doesn't match any ignore pattern
}

# Function to show help
show_help() {
    echo "Auto-commit Script - Multi Repository"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --silent              Silent mode (no prompts, use defaults or provided args)"
    echo "  -l, --language LANG       Set commit language: en, es, pt (default: en)"
    echo "  -u, --username USER       GitHub username for token updates"
    echo "  -t, --update-tokens       Update GitHub tokens (requires -u)"
    echo "  -p, --preview             Show preview before committing"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s -l pt -u iago-costa -t"
    echo "  $0 --silent --language es --preview"
    echo "  $0 -s -l en"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--silent)
            SILENT_MODE=true
            shift
            ;;
        -l|--language)
            COMMIT_LANGUAGE="$2"
            shift 2
            ;;
        -u|--username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        -t|--update-tokens)
            UPDATE_TOKENS_ARG=true
            shift
            ;;
        -p|--preview)
            SHOW_PREVIEW=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate language
case "$COMMIT_LANGUAGE" in
    en|es|pt)
        # Valid language
        ;;
    *)
        echo -e "${RED}Error: Invalid language '$COMMIT_LANGUAGE'. Use: en, es, or pt${NC}"
        exit 1
        ;;
esac

# Language templates
declare -A LANG_TEMPLATES=(
    ["en_add"]="add"
    ["en_remove"]="remove"
    ["en_update"]="update"
    ["en_modify"]="modify"
    ["en_rename"]="rename"
    ["es_add"]="agregar"
    ["es_remove"]="eliminar"
    ["es_update"]="actualizar"
    ["es_modify"]="modificar"
    ["es_rename"]="renombrar"
    ["pt_add"]="adicionar"
    ["pt_remove"]="remover"
    ["pt_update"]="atualizar"
    ["pt_modify"]="modificar"
    ["pt_rename"]="renomear"
)

# Function to get action verb in selected language
get_action_verb() {
    local action=$1
    local key="${COMMIT_LANGUAGE}_${action}"
    echo "${LANG_TEMPLATES[$key]}"
}

# Function to install GitHub CLI
install_gh_cli() {
    echo -e "${YELLOW}GitHub CLI not found. Installing...${NC}\n"
    
    # Detect OS and architecture
    local os=""
    local arch=""
    local file_ext=""
    local download_url=""
    
    # Detect OS
    case "$OSTYPE" in
        linux-gnu*)
            os="linux"
            file_ext="tar.gz"
            ;;
        darwin*)
            os="macOS"
            file_ext="zip"
            ;;
        msys*|cygwin*|win32)
            os="windows"
            file_ext="zip"
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
            return 1
            ;;
    esac
    
    # Detect architecture
    local machine=$(uname -m)
    case "$machine" in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        i386|i686)
            arch="386"
            ;;
        armv7l)
            arch="armv6"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $machine${NC}"
            return 1
            ;;
    esac
    
    echo -e "${BLUE}Detected: $os ($arch)${NC}"
    
    # Get latest version from GitHub API
    echo -e "${BLUE}Fetching latest version...${NC}"
    local latest_version=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
    
    if [[ -z "$latest_version" ]]; then
        echo -e "${YELLOW}Could not fetch latest version, using default${NC}"
        latest_version="2.61.0"
    fi
    
    echo -e "${GREEN}Latest version: $latest_version${NC}"
    
    # Construct download URL
    if [[ "$os" == "windows" ]]; then
        download_url="https://github.com/cli/cli/releases/download/v${latest_version}/gh_${latest_version}_windows_${arch}.${file_ext}"
    else
        download_url="https://github.com/cli/cli/releases/download/v${latest_version}/gh_${latest_version}_${os}_${arch}.${file_ext}"
    fi
    
    echo -e "${BLUE}Downloading from: $download_url${NC}\n"
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1
    
    # Download gh CLI
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$download_url" -O "gh.$file_ext"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar "$download_url" -o "gh.$file_ext"
    else
        echo -e "${RED}Neither wget nor curl found. Cannot download.${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to download GitHub CLI${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract based on file type
    echo -e "\n${BLUE}Extracting...${NC}"
    if [[ "$file_ext" == "tar.gz" ]]; then
        tar -xzf "gh.$file_ext"
    elif [[ "$file_ext" == "zip" ]]; then
        unzip -q "gh.$file_ext"
    fi
    
    # Install to ~/.local/bin (user local)
    mkdir -p "$HOME/.local/bin"
    
    # Find the gh binary
    local gh_binary=$(find . -name "gh" -type f -executable | head -n 1)
    
    if [[ -z "$gh_binary" ]]; then
        # Try without executable check (for extracted files)
        gh_binary=$(find . -path "*/bin/gh" | head -n 1)
    fi
    
    if [[ -z "$gh_binary" ]]; then
        echo -e "${RED}Could not find gh binary in extracted files${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    cp "$gh_binary" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/gh"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        
        # Update shell config files
        for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            if [[ -f "$rcfile" ]]; then
                if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$rcfile"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rcfile"
                fi
            fi
        done
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✓ GitHub CLI installed successfully to ~/.local/bin/gh${NC}\n"
    
    return 0
}

# Function to authenticate with GitHub CLI
authenticate_gh() {
    echo -e "${YELLOW}GitHub CLI authentication required...${NC}\n"
    echo -e "${BLUE}Please follow the prompts to authenticate:${NC}\n"
    
    gh auth login
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Authentication successful${NC}\n"
        return 0
    else
        echo -e "\n${RED}✗ Authentication failed${NC}\n"
        return 1
    fi
}

# Function to update GitHub token in repository
update_github_token() {
    # Skip if gh is not available or user doesn't want to update tokens
    if [[ "$GH_AVAILABLE" != true ]] || [[ "$UPDATE_TOKENS" != true ]]; then
        return 1
    fi
    
    echo -e "${BLUE}  → Updating GitHub token...${NC}"
    
    # Check if .git/config exists
    if [[ ! -f ".git/config" ]]; then
        echo -e "${YELLOW}  ⊘ .git/config not found, skipping token update${NC}"
        return 1
    fi
    
    # Get token from gh CLI
    local token=$(gh auth token -h github.com -u "$GITHUB_USERNAME" 2>/dev/null)
    
    if [[ -z "$token" ]]; then
        echo -e "${YELLOW}  ⊘ Failed to get token from gh CLI, skipping token update${NC}"
        return 1
    fi
    
    # Update .git/config
    local success=false
    if grep -q "url = https://$GITHUB_USERNAME:" .git/config 2>/dev/null; then
        # Token already exists, replace it
        sed -i "s|\($GITHUB_USERNAME:\)[^@]*@|\1$token@|" .git/config
        echo -e "${GREEN}  ✓ Token updated in .git/config${NC}"
        success=true
    elif grep -q "url = https://github.com/" .git/config 2>/dev/null; then
        # No token yet, add it
        sed -i "s|https://github.com/|https://$GITHUB_USERNAME:$token@github.com/|" .git/config
        echo -e "${GREEN}  ✓ Token added to .git/config${NC}"
        success=true
    else
        echo -e "${YELLOW}  ⊘ No GitHub HTTPS URL found in .git/config${NC}"
    fi
    
    if [[ "$success" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Function to determine commit type based on file extension and change
get_commit_type() {
    local file=$1
    local status=$2
    
    # Check if file is deleted
    if [[ "$status" == "D" ]]; then
        echo "chore"
        return
    fi
    
    # Check file extension
    case "$file" in
        *.md|*.txt|README*)
            echo "docs"
            ;;
        *.sh)
            echo "chore"
            ;;
        *.py|*.js|*.ts|*.java|*.c|*.cpp|*.go|*.rs)
            if [[ "$status" == "A" ]]; then
                echo "feat"
            else
                echo "refactor"
            fi
            ;;
        *.json|*.yaml|*.yml|*.toml|*.xml)
            echo "chore"
            ;;
        *.css|*.scss|*.sass)
            echo "style"
            ;;
        *.epub|*.pdf|*.mobi|*.kfx|*.djvu)
            echo "docs"
            ;;
        *.zip|*.rar|*.7z|*.tar|*.gz|*.bz2)
            echo "chore"
            ;;
        *.gns3a|*.gns3|*.unl)
            echo "chore"
            ;;
        *.crt|*.key|*.pem)
            echo "chore"
            ;;
        *.html)
            if [[ "$status" == "A" ]]; then
                echo "feat"
            else
                echo "refactor"
            fi
            ;;
        *)
            if [[ "$status" == "A" ]]; then
                echo "feat"
            else
                echo "chore"
            fi
            ;;
    esac
}

# Function to get scope from file path
get_scope() {
    local file=$1
    local dir=$(dirname "$file")
    
    # Extract meaningful scope from path
    if [[ "$dir" == "." ]]; then
        echo ""
    else
        # Get the most specific directory name
        local scope=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        echo "$scope"
    fi
}

# Function to generate subject based on file and action
generate_subject() {
    local file=$1
    local status=$2
    local filename=$(basename "$file")
    
    case "$status" in
        A)
            echo "$(get_action_verb 'add') $filename"
            ;;
        D)
            echo "$(get_action_verb 'remove') $filename"
            ;;
        M)
            echo "$(get_action_verb 'update') $filename"
            ;;
        R*)
            echo "$(get_action_verb 'rename') $filename"
            ;;
        *)
            echo "$(get_action_verb 'modify') $filename"
            ;;
    esac
}

# Function to generate enhanced commit message with file content analysis
generate_enhanced_message() {
    local file=$1
    local status=$2
    local type=$3
    local scope=$4
    local base_subject=$5
    
    # Check if file exists and is readable
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        echo "$base_subject"
        return
    fi
    
    # Get file extension
    local ext="${file##*.}"
    
    # For programming language files, analyze code changes
    case "$ext" in
        py|js|ts|java|c|cpp|go|rs|rb|php|swift|kt|scala)
            if [[ "$status" == "M" ]]; then
                # Analyze the diff for code changes
                local diff_output=$(git diff --cached "$file" 2>/dev/null)
                
                if [[ -n "$diff_output" ]]; then
                    local added_functions=$(echo "$diff_output" | grep -E "^\+.*\b(function|def|func|fn|class|interface|struct|impl|async|const.*=.*=>)" | wc -l)
                    local removed_functions=$(echo "$diff_output" | grep -E "^-.*\b(function|def|func|fn|class|interface|struct|impl|async|const.*=.*=>)" | wc -l)
                    local added_imports=$(echo "$diff_output" | grep -E "^\+.*(import|require|use|include|from.*import)" | wc -l)
                    local removed_imports=$(echo "$diff_output" | grep -E "^-.*(import|require|use|include|from.*import)" | wc -l)
                    local added_comments=$(echo "$diff_output" | grep -E "^\+.*(//|#|/\*|\*|\"\"\")" | wc -l)
                    
                    local additions=$(echo "$diff_output" | grep -c "^+[^+]" || echo "0")
                    local deletions=$(echo "$diff_output" | grep -c "^-[^-]" || echo "0")
                    
                    # Build detailed message
                    local details=""
                    
                    if [[ $added_functions -gt 0 ]] || [[ $removed_functions -gt 0 ]]; then
                        case "$COMMIT_LANGUAGE" in
                            en)
                                if [[ $added_functions -gt 0 ]]; then
                                    details="add $added_functions function(s)"
                                fi
                                if [[ $removed_functions -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}remove $removed_functions function(s)"
                                fi
                                ;;
                            es)
                                if [[ $added_functions -gt 0 ]]; then
                                    details="agregar $added_functions función(es)"
                                fi
                                if [[ $removed_functions -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}eliminar $removed_functions función(es)"
                                fi
                                ;;
                            pt)
                                if [[ $added_functions -gt 0 ]]; then
                                    details="adicionar $added_functions função(ões)"
                                fi
                                if [[ $removed_functions -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}remover $removed_functions função(ões)"
                                fi
                                ;;
                        esac
                    fi
                    
                    if [[ $added_imports -gt 0 ]] || [[ $removed_imports -gt 0 ]]; then
                        case "$COMMIT_LANGUAGE" in
                            en)
                                if [[ $added_imports -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}add $added_imports import(s)"
                                fi
                                ;;
                            es)
                                if [[ $added_imports -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}agregar $added_imports importación(es)"
                                fi
                                ;;
                            pt)
                                if [[ $added_imports -gt 0 ]]; then
                                    [[ -n "$details" ]] && details="$details, "
                                    details="${details}adicionar $added_imports importação(ões)"
                                fi
                                ;;
                        esac
                    fi
                    
                    if [[ -n "$details" ]]; then
                        echo "$base_subject - $details"
                    else
                        case "$COMMIT_LANGUAGE" in
                            en)
                                echo "$base_subject (+$additions/-$deletions lines)"
                                ;;
                            es)
                                echo "$base_subject (+$additions/-$deletions líneas)"
                                ;;
                            pt)
                                echo "$base_subject (+$additions/-$deletions linhas)"
                                ;;
                        esac
                    fi
                    return
                fi
            elif [[ "$status" == "A" ]]; then
                # For new code files, analyze content
                local functions=$(grep -E "\b(function|def|func|fn|class|interface|struct|impl|async|const.*=.*=>)" "$file" 2>/dev/null | wc -l)
                local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                
                if [[ $functions -gt 0 ]]; then
                    case "$COMMIT_LANGUAGE" in
                        en)
                            echo "$base_subject - $functions function(s), $lines lines"
                            ;;
                        es)
                            echo "$base_subject - $functions función(es), $lines líneas"
                            ;;
                        pt)
                            echo "$base_subject - $functions função(ões), $lines linhas"
                            ;;
                    esac
                    return
                else
                    case "$COMMIT_LANGUAGE" in
                        en)
                            echo "$base_subject ($lines lines)"
                            ;;
                        es)
                            echo "$base_subject ($lines líneas)"
                            ;;
                        pt)
                            echo "$base_subject ($lines linhas)"
                            ;;
                    esac
                    return
                fi
            fi
            ;;
        md|txt|rst|adoc)
            # For documentation files
            if [[ "$status" == "M" ]]; then
                local additions=$(git diff --cached "$file" 2>/dev/null | grep -c "^+[^+]")
                local deletions=$(git diff --cached "$file" 2>/dev/null | grep -c "^-[^-]")
                
                if [[ $additions -gt 0 ]] || [[ $deletions -gt 0 ]]; then
                    case "$COMMIT_LANGUAGE" in
                        en)
                            echo "$base_subject (+$additions/-$deletions lines)"
                            ;;
                        es)
                            echo "$base_subject (+$additions/-$deletions líneas)"
                            ;;
                        pt)
                            echo "$base_subject (+$additions/-$deletions linhas)"
                            ;;
                    esac
                    return
                fi
            elif [[ "$status" == "A" ]]; then
                local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                case "$COMMIT_LANGUAGE" in
                    en)
                        echo "$base_subject ($lines lines)"
                        ;;
                    es)
                        echo "$base_subject ($lines líneas)"
                        ;;
                    pt)
                        echo "$base_subject ($lines linhas)"
                        ;;
                esac
                return
            fi
            ;;
        json|yaml|yml|toml|xml)
            # For configuration files
            if [[ "$status" == "M" ]]; then
                local additions=$(git diff --cached "$file" 2>/dev/null | grep -c "^+[^+]")
                local deletions=$(git diff --cached "$file" 2>/dev/null | grep -c "^-[^-]")
                
                case "$COMMIT_LANGUAGE" in
                    en)
                        echo "$base_subject - update configuration (+$additions/-$deletions)"
                        ;;
                    es)
                        echo "$base_subject - actualizar configuración (+$additions/-$deletions)"
                        ;;
                    pt)
                        echo "$base_subject - atualizar configuração (+$additions/-$deletions)"
                        ;;
                esac
                return
            fi
            ;;
    esac
    
    # Default: return base subject
    echo "$base_subject"
}

# Function to count files to commit in a repository
count_files_to_commit() {
    local repo_path=$1
    
    # Get absolute path to repository directory
    local repo_dir=$(cd "$(dirname "$repo_path")" 2>/dev/null && pwd)
    
    if [[ -z "$repo_dir" ]] || [[ ! -d "$repo_dir" ]]; then
        echo "0"
        return
    fi
    
    # Change to repository directory
    cd "$repo_dir" || return 0
    
    # Get all changed files
    local changed_files=$(git status --porcelain)
    
    if [[ -z "$changed_files" ]]; then
        return 0
    fi
    
    local file_count=0
    while IFS= read -r line; do
        local status="${line:0:2}"
        status=$(echo "$status" | tr -d ' ')
        local file="${line:3}"
        
        # Remove surrounding quotes
        file="${file#\"}"
        file="${file%\"}"
        
        # Skip if file is empty
        [[ -z "$file" ]] && continue
        
        # Skip files that match common ignore patterns
        if is_commonly_ignored "$file"; then
            continue
        fi
        
        # Skip files that are ignored by git
        if git check-ignore -q "$file" 2>/dev/null; then
            continue
        fi
        
        # Skip .git directories
        if [[ "$file" == ".git"* ]] || [[ "$file" == *"/.git"* ]] || [[ "$file" == *"/.git" ]]; then
            continue
        fi
        
        # If it's a directory, count files inside
        if [[ -d "$file" ]]; then
            while IFS= read -r subfile; do
                [[ -z "$subfile" ]] && continue
                
                # Skip files inside .git directories
                if [[ "$subfile" == *"/.git/"* ]] || [[ "$subfile" == ".git/"* ]]; then
                    continue
                fi
                
                # Skip files that match common ignore patterns
                if is_commonly_ignored "$subfile"; then
                    continue
                fi
                
                # Skip files that are ignored by git
                if git check-ignore -q "$subfile" 2>/dev/null; then
                    continue
                fi
                
                # Skip files larger than 100MB
                local file_size=$(stat -f%z "$subfile" 2>/dev/null || stat -c%s "$subfile" 2>/dev/null)
                local max_size=$((100 * 1024 * 1024))
                if [[ $file_size -gt $max_size ]]; then
                    continue
                fi
                
                file_count=$((file_count + 1))
            done < <(find "$file" -type f -not -path "*/.git/*")
        else
            # Skip files that match common ignore patterns
            if is_commonly_ignored "$file"; then
                continue
            fi
            
            # Skip files that are ignored by git (single file check)
            if git check-ignore -q "$file" 2>/dev/null; then
                continue
            fi
            
            # Skip files larger than 100MB
            if [[ -f "$file" ]]; then
                local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
                local max_size=$((100 * 1024 * 1024))
                if [[ $file_size -gt $max_size ]]; then
                    continue
                fi
            fi
            
            file_count=$((file_count + 1))
        fi
    done <<< "$changed_files"
    
    echo "$file_count"
}

# Function to count commits to push
count_commits_to_push() {
    local repo_path=$1
    
    # Get absolute path to repository directory
    local repo_dir=$(cd "$(dirname "$repo_path")" 2>/dev/null && pwd)
    
    if [[ -z "$repo_dir" ]] || [[ ! -d "$repo_dir" ]]; then
        echo "0"
        return
    fi
    
    # Change to repository directory
    cd "$repo_dir" || return 0
    
    # Check if remote exists
    if ! git remote | grep -q .; then
        echo "0"
        return
    fi
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    if [[ -z "$current_branch" ]]; then
        echo "0"
        return
    fi
    
    # Count unpushed commits
    local unpushed=$(git rev-list --count origin/"$current_branch"..HEAD 2>/dev/null)
    
    if [[ -z "$unpushed" ]]; then
        echo "0"
    else
        echo "$unpushed"
    fi
}

# Function to decode git quoted filenames (handles octal escape sequences)
decode_git_filename() {
    local filename="$1"
    
    # If the filename is quoted, remove quotes and decode escape sequences
    if [[ "$filename" == \"*\" ]]; then
        # Remove surrounding quotes
        filename="${filename#\"}"
        filename="${filename%\"}"
        
        # Use printf to decode octal sequences like \303\207 (Ç)
        # This handles UTF-8 encoded characters
        printf '%b' "$filename"
    else
        # No encoding, return as-is
        echo "$filename"
    fi
}

# Function to process a single repository
process_repository() {
    local repo_path=$1
    
    # Get absolute path to repository directory
    local repo_dir=$(cd "$(dirname "$repo_path")" 2>/dev/null && pwd)
    
    if [[ -z "$repo_dir" ]] || [[ ! -d "$repo_dir" ]]; then
        echo -e "${RED}✗ Repository directory not found: $repo_path${NC}\n"
        return
    fi
    
    local repo_name=$(basename "$repo_dir")
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ Repository: ${YELLOW}$repo_name${NC}"
    echo -e "${GREEN}║ Path: ${YELLOW}$repo_dir${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    
    # Change to repository directory
    cd "$repo_dir" || return
    
    # Copy this script to the repository if it doesn't exist or update if it does
    local script_name="auto-commit.sh"
    local script_source="$original_dir/$script_name"
    
    if [[ -f "$script_source" ]] && [[ "$PWD" != "$original_dir" ]]; then
        echo -e "${BLUE}  → Copying/updating auto-commit.sh to repository...${NC}"
        
        if [[ -f "$script_name" ]]; then
            # Check if files are different
            if ! cmp -s "$script_source" "$script_name"; then
                cp "$script_source" "$script_name"
                chmod +x "$script_name"
                
                # Commit the updated script
                if git add -- "$script_name" > /dev/null 2>&1; then
                    if git commit -m "chore: update auto-commit.sh script" > /dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ Script updated and committed${NC}\n"
                    else
                        echo -e "${YELLOW}  ⊘ Script updated but not committed (no changes or commit failed)${NC}\n"
                    fi
                else
                    echo -e "${YELLOW}  ⊘ Script updated but not added to git${NC}\n"
                fi
            else
                echo -e "${GREEN}  ✓ Script already up to date${NC}\n"
            fi
        else
            # Script doesn't exist, create it
            cp "$script_source" "$script_name"
            chmod +x "$script_name"
            
            # Commit the new script
            if git add -- "$script_name" > /dev/null 2>&1; then
                if git commit -m "chore: add auto-commit.sh script" > /dev/null 2>&1; then
                    echo -e "${GREEN}  ✓ Script added and committed${NC}\n"
                else
                    echo -e "${YELLOW}  ⊘ Script added but not committed${NC}\n"
                fi
            else
                echo -e "${YELLOW}  ⊘ Script added but not added to git${NC}\n"
            fi
        fi
    fi
    
    # Update GitHub token (we're already in the repo directory)
    update_github_token
    echo ""
    
    # Get all changed files
    changed_files=$(git status --porcelain)
    
    if [[ -z "$changed_files" ]]; then
        echo -e "${YELLOW}No changes to commit in this repository${NC}\n"
        return
    fi
    
    # Process each file
    local count=0
    local committed=0
    while IFS= read -r line; do
        # Parse git status output
        status="${line:0:2}"
        status=$(echo "$status" | tr -d ' ')
        file="${line:3}"
        
        # Decode git filename (handles quotes and escape sequences like \303\207)
        file=$(decode_git_filename "$file")
        
        # Skip if file is empty
        [[ -z "$file" ]] && continue
        
        # Skip files that match common ignore patterns
        if is_commonly_ignored "$file"; then
            continue
        fi
        
        # Skip files that are ignored by git
        if git check-ignore -q "$file" 2>/dev/null; then
            continue
        fi
        
        # Skip .git directories and their contents
        if [[ "$file" == ".git"* ]] || [[ "$file" == *"/.git"* ]] || [[ "$file" == *"/.git" ]]; then
            continue
        fi
        
        # If it's a directory (untracked), find all files in it and process them
        if [[ -d "$file" ]]; then
            # Find all files recursively in the directory
            while IFS= read -r subfile; do
                [[ -z "$subfile" ]] && continue
                
                # Skip files inside .git directories
                if [[ "$subfile" == *"/.git/"* ]] || [[ "$subfile" == ".git/"* ]]; then
                    continue
                fi
                
                # Skip files that match common ignore patterns
                if is_commonly_ignored "$subfile"; then
                    continue
                fi
                
                # Skip files that are ignored by git
                if git check-ignore -q "$subfile" 2>/dev/null; then
                    continue
                fi
                
                # Skip files larger than 100MB
                file_size=$(stat -f%z "$subfile" 2>/dev/null || stat -c%s "$subfile" 2>/dev/null)
                max_size=$((100 * 1024 * 1024)) # 100MB in bytes
                if [[ $file_size -gt $max_size ]]; then
                    committed=$((committed + 1))
                    echo -e "${YELLOW}[$committed] Processing: $subfile${NC}"
                    echo -e "  ${RED}⊘ Skipped (file too large: $(($file_size / 1024 / 1024))MB > 100MB)${NC}\n"
                    continue
                fi
                
                committed=$((committed + 1))
                
                echo -e "${YELLOW}[$committed] Processing: $subfile${NC}"
                
                # Get commit components for subfile
                subtype=$(get_commit_type "$subfile" "$status")
                subscope=$(get_scope "$subfile")
                subsubject=$(generate_subject "$subfile" "$status")
                
                # Generate enhanced message
                subsubject=$(generate_enhanced_message "$subfile" "$status" "$subtype" "$subscope" "$subsubject")
                
                # Build commit message
                if [[ -n "$subscope" ]]; then
                    subcommit_msg="$subtype($subscope): $subsubject"
                else
                    subcommit_msg="$subtype: $subsubject"
                fi
                
                echo -e "  Type: ${GREEN}$subtype${NC}"
                [[ -n "$subscope" ]] && echo -e "  Scope: ${GREEN}$subscope${NC}"
                echo -e "  Message: ${GREEN}$subcommit_msg${NC}"
                
                # Add and commit the file
                add_output=$(git add -- "$subfile" 2>&1)
                add_status=$?
                if [[ $add_status -eq 0 ]]; then
                    commit_output=$(git commit -m "$subcommit_msg" 2>&1)
                    commit_status=$?
                    if [[ $commit_status -eq 0 ]]; then
                        echo -e "  ${GREEN}✓ Committed successfully${NC}\n"
                    else
                        echo -e "  ${RED}✗ Commit failed${NC}"
                        if [[ -n "$commit_output" ]]; then
                            echo -e "  ${RED}Error: $commit_output${NC}"
                        fi
                        echo ""
                        git reset HEAD -- "$subfile" > /dev/null 2>&1
                    fi
                else
                    echo -e "  ${RED}✗ Failed to add file${NC}"
                    if [[ -n "$add_output" ]]; then
                        echo -e "  ${RED}Error: $add_output${NC}"
                    fi
                    echo ""
                fi
            done < <(find "$file" -type f -not -path "*/.git/*")
            continue
        fi
        
        committed=$((committed + 1))
        
        # Skip files larger than 100MB (GitHub limit)
        if [[ -f "$file" ]]; then
            file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            max_size=$((100 * 1024 * 1024)) # 100MB in bytes
            if [[ $file_size -gt $max_size ]]; then
                echo -e "${YELLOW}[$committed] Processing: $file${NC}"
                echo -e "  ${RED}⊘ Skipped (file too large: $(($file_size / 1024 / 1024))MB > 100MB)${NC}\n"
                continue
            fi
        fi
        
        echo -e "${YELLOW}[$committed] Processing: $file${NC}"
        
        # Get commit components
        type=$(get_commit_type "$file" "$status")
        scope=$(get_scope "$file")
        subject=$(generate_subject "$file" "$status")
        
        # Generate enhanced message
        subject=$(generate_enhanced_message "$file" "$status" "$type" "$scope" "$subject")
        
        # Build commit message
        if [[ -n "$scope" ]]; then
            commit_msg="$type($scope): $subject"
        else
            commit_msg="$type: $subject"
        fi
        
        echo -e "  Type: ${GREEN}$type${NC}"
        [[ -n "$scope" ]] && echo -e "  Scope: ${GREEN}$scope${NC}"
        echo -e "  Message: ${GREEN}$commit_msg${NC}"
        
        # Add/remove and commit the file based on status
        local git_success=false
        local git_error=""
        
        if [[ "$status" == "D" ]]; then
            # For deleted files, use git rm
            git_error=$(git rm -- "$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                git_success=true
            fi
        else
            # For added/modified files, use git add
            git_error=$(git add -- "$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                git_success=true
            fi
        fi
        
        if [[ "$git_success" == true ]]; then
            commit_output=$(git commit -m "$commit_msg" 2>&1)
            commit_status=$?
            if [[ $commit_status -eq 0 ]]; then
                echo -e "  ${GREEN}✓ Committed successfully${NC}\n"
            else
                echo -e "  ${RED}✗ Commit failed${NC}"
                if [[ -n "$commit_output" ]]; then
                    echo -e "  ${RED}Error: $commit_output${NC}"
                fi
                echo ""
                git reset HEAD -- "$file" > /dev/null 2>&1
            fi
        else
            echo -e "  ${RED}✗ Failed to stage file${NC}"
            if [[ -n "$git_error" ]]; then
                echo -e "  ${RED}Error: $git_error${NC}"
            fi
            echo ""
        fi
        
    done <<< "$changed_files"
    
    echo -e "${GREEN}=== Done! Committed $committed file(s) in $repo_name ===${NC}\n"
    
    # Push commits to remote if any were made
    if [[ $committed -gt 0 ]]; then
        echo -e "${YELLOW}Pushing commits to remote...${NC}"
        
        # Get current branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        
        if [[ -z "$current_branch" ]]; then
            echo -e "${RED}✗ Could not determine current branch${NC}\n"
            return
        fi
        
        # Check if remote exists
        if ! git remote | grep -q .; then
            echo -e "${YELLOW}⊘ No remote configured, skipping push${NC}\n"
            return
        fi
        
        # Push to remote
        echo -e "${BLUE}Pushing to origin/$current_branch...${NC}"
        
        # Execute push and capture exit code
        git push origin "$current_branch" 2>&1
        local push_exit_code=$?
        
        # Check for authentication errors or other failures
        if [[ $push_exit_code -eq 0 ]]; then
            echo -e "${GREEN}✓ Successfully pushed to remote ($current_branch)${NC}\n"
        else
            echo -e "${RED}✗ Failed to push to remote (exit code: $push_exit_code)${NC}"
            echo -e "${YELLOW}Check authentication credentials or run with -t to update token${NC}\n"
        fi
    fi
}

# Main script
if [[ "$SILENT_MODE" != true ]]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Auto Commit Script - Multi Repository           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
fi

# Ask for commit message language (if not in silent mode and not provided)
if [[ "$SILENT_MODE" != true ]]; then
    echo -e "${BLUE}Select commit message language:${NC}"
    echo -e "  1) English (en)"
    echo -e "  2) Español (es)"
    echo -e "  3) Português (pt)"
    read -p "Enter choice (1-3) [default: 1]: " lang_choice

    case "$lang_choice" in
        2)
            COMMIT_LANGUAGE="es"
            echo -e "${GREEN}✓ Language set to: Español${NC}\n"
            ;;
        3)
            COMMIT_LANGUAGE="pt"
            echo -e "${GREEN}✓ Language set to: Português${NC}\n"
            ;;
        *)
            COMMIT_LANGUAGE="en"
            echo -e "${GREEN}✓ Language set to: English${NC}\n"
            ;;
    esac
else
    # Silent mode - just show what was selected
    case "$COMMIT_LANGUAGE" in
        es)
            echo -e "${GREEN}✓ Language: Español${NC}"
            ;;
        pt)
            echo -e "${GREEN}✓ Language: Português${NC}"
            ;;
        *)
            echo -e "${GREEN}✓ Language: English${NC}"
            ;;
    esac
fi

# Check if gh CLI is installed
GH_AVAILABLE=false
if ! command -v gh &> /dev/null; then
    if [[ "$SILENT_MODE" != true ]]; then
        echo -e "${YELLOW}GitHub CLI (gh) not found${NC}"
        read -p "Do you want to install GitHub CLI? (y/n): " install_choice
        
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            echo ""
            install_gh_cli
            
            if [[ $? -eq 0 ]]; then
                GH_AVAILABLE=true
            else
                echo -e "${RED}Failed to install GitHub CLI${NC}"
                echo -e "${YELLOW}Continuing without token update functionality...${NC}\n"
            fi
        else
            echo -e "${YELLOW}Skipping GitHub CLI installation${NC}"
            echo -e "${YELLOW}Continuing without token update functionality...${NC}\n"
        fi
    else
        # Silent mode - skip installation
        echo -e "${YELLOW}✓ GitHub CLI not found - skipping token updates${NC}"
    fi
else
    GH_AVAILABLE=true
fi

# Check if authenticated with gh (only if gh is available)
if [[ "$GH_AVAILABLE" == true ]]; then
    if ! gh auth status &> /dev/null; then
        if [[ "$SILENT_MODE" != true ]]; then
            echo -e "${YELLOW}Not authenticated with GitHub CLI${NC}\n"
            authenticate_gh
        else
            echo -e "${YELLOW}✓ Not authenticated with GitHub CLI - skipping token updates${NC}"
            GH_AVAILABLE=false
        fi
    else
        if [[ "$SILENT_MODE" != true ]]; then
            echo -e "${GREEN}✓ GitHub CLI authenticated${NC}\n"
        else
            echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"
        fi
    fi
fi

# Ask if user wants to update tokens
UPDATE_TOKENS=false
if [[ "$GH_AVAILABLE" == true ]]; then
    if [[ "$SILENT_MODE" != true ]]; then
        read -p "Do you want to update GitHub tokens in repositories? (y/n): " update_tokens_choice
        
        if [[ "$update_tokens_choice" =~ ^[Yy]$ ]]; then
            UPDATE_TOKENS=true
            
            # Ask for GitHub username
            read -p "GitHub username: " GITHUB_USERNAME
            
            if [[ -z "$GITHUB_USERNAME" ]]; then
                echo -e "${RED}Error: Username cannot be empty${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}Skipping token updates${NC}"
        fi
        echo ""
    else
        # Silent mode - use provided arguments
        if [[ "$UPDATE_TOKENS_ARG" == true ]]; then
            if [[ -n "$GITHUB_USERNAME" ]]; then
                UPDATE_TOKENS=true
                echo -e "${GREEN}✓ Will update tokens for user: $GITHUB_USERNAME${NC}"
            else
                echo -e "${YELLOW}✓ Username not provided - skipping token updates${NC}"
            fi
        else
            echo -e "${YELLOW}✓ Token updates disabled${NC}"
        fi
    fi
fi

# Save current directory
original_dir=$(pwd)

# Find all .git directories
if [[ "$SILENT_MODE" != true ]]; then
    echo -e "${YELLOW}Searching for git repositories...${NC}\n"
fi

git_dirs=()
while IFS= read -r git_dir; do
    git_dirs+=("$git_dir")
done < <(find . -type d -name ".git" 2>/dev/null)

if [[ ${#git_dirs[@]} -eq 0 ]]; then
    echo -e "${RED}No git repositories found${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#git_dirs[@]} git repository(ies)${NC}\n"

# Preview mode - count files in each repository
preview_choice="n"
if [[ "$SILENT_MODE" != true ]]; then
    read -p "Do you want to preview the number of files to commit? (y/n): " preview_choice
    echo ""
elif [[ "$SHOW_PREVIEW" == true ]]; then
    preview_choice="y"
fi

if [[ "$preview_choice" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Preview Summary                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    
    total_files_all_repos=0
    total_commits_to_push=0
    
    for git_dir in "${git_dirs[@]}"; do
        cd "$original_dir" || exit
        repo_name=$(basename "$(dirname "$git_dir")")
        file_count=$(count_files_to_commit "$git_dir")
        commits_to_push=$(count_commits_to_push "$git_dir")
        
        if [[ $file_count -gt 0 ]] || [[ $commits_to_push -gt 0 ]]; then
            echo -e "${GREEN}  Repository: ${YELLOW}$repo_name${NC}"
            echo -e "${GREEN}    Files to commit: ${YELLOW}$file_count${NC}"
            echo -e "${GREEN}    Commits to push: ${YELLOW}$commits_to_push${NC}\n"
            total_files_all_repos=$((total_files_all_repos + file_count))
            total_commits_to_push=$((total_commits_to_push + commits_to_push))
        else
            echo -e "${YELLOW}  Repository: $repo_name${NC}"
            echo -e "${YELLOW}    No changes to commit or push${NC}\n"
        fi
    done
    
    cd "$original_dir" || exit
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ Total files to commit: ${YELLOW}$total_files_all_repos${NC}"
    echo -e "${GREEN}║ Total commits to push: ${YELLOW}$total_commits_to_push${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    
    if [[ "$SILENT_MODE" != true ]]; then
        read -p "Do you want to proceed with committing? (y/n): " proceed_choice
        echo ""
        
        if [[ ! "$proceed_choice" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Operation cancelled by user${NC}"
            exit 0
        fi
    fi
fi

# Process each repository
for git_dir in "${git_dirs[@]}"; do
    process_repository "$git_dir"
    # Return to original directory after processing each repo
    cd "$original_dir" || exit
done

if [[ "$SILENT_MODE" != true ]]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              All Repositories Processed!                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${GREEN}✓ All repositories processed${NC}"
fi
