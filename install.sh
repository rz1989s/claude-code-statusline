#!/bin/bash

# Claude Code Enhanced Statusline - Automated Installation Script
# This script downloads and configures the statusline for Claude Code
# Updated: cost_session → cost_repo component rename

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration - Branch aware architecture
# Detect installation branch from script source or allow override
INSTALL_BRANCH="${CLAUDE_INSTALL_BRANCH:-main}"

# Auto-detect branch if installer was downloaded from specific branch
# Note: BASH_SOURCE may not be available when piped from curl, so this is optional
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" =~ githubusercontent\.com/.*/(.*)/install\.sh ]]; then
    DETECTED_BRANCH="${BASH_REMATCH[1]}"
    if [[ "$DETECTED_BRANCH" != "main" ]]; then
        INSTALL_BRANCH="$DETECTED_BRANCH"
    fi
fi

# REPO_URL will be set dynamically after branch detection
CLAUDE_DIR="$HOME/.claude"
STATUSLINE_DIR="$CLAUDE_DIR/statusline"
STATUSLINE_PATH="$STATUSLINE_DIR/statusline.sh"
LIB_DIR="$STATUSLINE_DIR/lib"
EXAMPLES_DIR="$STATUSLINE_DIR/examples"
CONFIG_PATH="$STATUSLINE_DIR/Config.toml"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

# Debug mode flag (can be set via environment)
DEBUG_MODE="${STATUSLINE_INSTALL_DEBUG:-false}"

# Function to print colored output with enhanced debugging
print_status() {
    local timestamp=""
    if [[ "$DEBUG_MODE" == "true" ]]; then
        timestamp="$(date '+%H:%M:%S') "
    fi
    echo -e "${BLUE}[INFO]${NC} ${timestamp}$1"
}

print_success() {
    local timestamp=""
    if [[ "$DEBUG_MODE" == "true" ]]; then
        timestamp="$(date '+%H:%M:%S') "
    fi
    echo -e "${GREEN}[SUCCESS]${NC} ${timestamp}$1"
}

print_warning() {
    local timestamp=""
    if [[ "$DEBUG_MODE" == "true" ]]; then
        timestamp="$(date '+%H:%M:%S') "
    fi
    echo -e "${YELLOW}[WARNING]${NC} ${timestamp}$1"
}

print_error() {
    local timestamp=""
    if [[ "$DEBUG_MODE" == "true" ]]; then
        timestamp="$(date '+%H:%M:%S') "
    fi
    echo -e "${RED}[ERROR]${NC} ${timestamp}$1"
}

# Debug-only output function
print_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${YELLOW}[DEBUG]${NC} $(date '+%H:%M:%S') $1"
    fi
}

# Function to trace execution flow
trace_execution() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_debug "🔍 Executing: $1"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Enhanced system detection and capability analysis
detect_system_capabilities() {
    # OS and Architecture Detection
    OS_TYPE=$(uname -s)
    OS_ARCH=$(uname -m)
    
    # Detailed OS classification
    case "$OS_TYPE" in
        "Darwin") OS_PLATFORM="macOS" ;;
        "Linux") 
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS_PLATFORM="$NAME"
            else
                OS_PLATFORM="Linux"
            fi
            ;;
        "CYGWIN"*|"MINGW"*|"MSYS"*) OS_PLATFORM="Windows" ;;
        *) OS_PLATFORM="Unknown" ;;
    esac
    
    # Package Manager Detection (in priority order)
    PKG_MGR="none"
    PKG_INSTALL_CMD=""
    
    if command_exists brew; then
        PKG_MGR="brew"
        PKG_INSTALL_CMD="brew install"
    elif command_exists apt; then
        PKG_MGR="apt"
        PKG_INSTALL_CMD="sudo apt update && sudo apt install"
    elif command_exists yum; then
        PKG_MGR="yum"
        PKG_INSTALL_CMD="sudo yum install"
    elif command_exists dnf; then
        PKG_MGR="dnf"
        PKG_INSTALL_CMD="sudo dnf install"
    elif command_exists pacman; then
        PKG_MGR="pacman"
        PKG_INSTALL_CMD="sudo pacman -S"
    elif command_exists apk; then
        PKG_MGR="apk"
        PKG_INSTALL_CMD="sudo apk add"
    elif command_exists pkg; then
        PKG_MGR="pkg"
        PKG_INSTALL_CMD="sudo pkg install"
    fi
    
    print_status "🔍 System Analysis:"
    print_status "  • OS: $OS_PLATFORM ($OS_ARCH)"
    print_status "  • Package Manager: $PKG_MGR"
}

# Comprehensive dependency checking for all statusline requirements
check_all_dependencies() {
    print_status "📋 Checking all dependencies for full functionality..."
    echo
    
    # Dependency categories and their impact
    local critical_deps=("curl:Download & installation" "jq:Configuration & JSON parsing")
    local important_deps=("bunx:Cost tracking with ccusage")
    local helpful_deps=("bc:Precise cost calculations" "python3:Advanced TOML features & date parsing")
    local optional_deps=("timeout:Network operation protection (gtimeout on macOS)" "CoreLocationCLI:GPS location for prayer times (macOS)" "geoclue:GPS location for prayer times (Linux)")
    
    local missing_critical=()
    local missing_important=()
    local missing_helpful=()
    local missing_optional=()
    local available_features=0
    local total_features=6
    
    # Check critical dependencies
    for dep_info in "${critical_deps[@]}"; do
        local dep="${dep_info%:*}"
        local desc="${dep_info#*:}"
        if command_exists "$dep"; then
            printf "  ✅ %-8s → %s\\n" "$dep" "$desc"
            ((available_features++))
        else
            printf "  ❌ %-8s → %s\\n" "$dep" "$desc"
            missing_critical+=("$dep")
        fi
    done
    
    # Check important dependencies
    for dep_info in "${important_deps[@]}"; do
        local dep="${dep_info%:*}"
        local desc="${dep_info#*:}"
        if command_exists "$dep"; then
            printf "  ✅ %-8s → %s\\n" "$dep" "$desc"
            ((available_features++))
        else
            printf "  ❌ %-8s → %s\\n" "$dep" "$desc"
            missing_important+=("$dep")
        fi
    done
    
    # Check helpful dependencies
    for dep_info in "${helpful_deps[@]}"; do
        local dep="${dep_info%:*}"
        local desc="${dep_info#*:}"
        if command_exists "$dep"; then
            printf "  ✅ %-8s → %s\\n" "$dep" "$desc"
            ((available_features++))
        else
            printf "  ❌ %-8s → %s\\n" "$dep" "$desc"
            missing_helpful+=("$dep")
        fi
    done
    
    # Check optional dependencies (timeout/gtimeout)
    if command_exists "gtimeout" || command_exists "timeout"; then
        local timeout_cmd="gtimeout"
        command_exists "timeout" && timeout_cmd="timeout"
        printf "  ✅ %-8s → %s\\n" "$timeout_cmd" "Network operation protection"
        ((available_features++))
    else
        printf "  ⚠️ %-8s → %s\\n" "timeout" "Network operation protection"
        missing_optional+=("timeout")
    fi

    # Check GPS location tools (platform-specific)
    case "$OS_TYPE" in
        "Darwin")
            if command_exists "CoreLocationCLI"; then
                printf "  ✅ %-8s → %s\\n" "GPS-macOS" "GPS location for prayer times (macOS)"
                ((available_features++))
            else
                printf "  ⚠️ %-8s → %s\\n" "GPS-macOS" "GPS location for prayer times (brew install corelocationcli)"
                missing_optional+=("CoreLocationCLI")
            fi
            ;;
        "Linux")
            if [[ -x "/usr/lib/geoclue-2.0/demos/where-am-i" ]] || command_exists "geoclue"; then
                printf "  ✅ %-8s → %s\\n" "GPS-Linux" "GPS location for prayer times (Linux)"
                ((available_features++))
            else
                printf "  ⚠️ %-8s → %s\\n" "GPS-Linux" "GPS location for prayer times (apt install geoclue-2.0-dev)"
                missing_optional+=("geoclue")
            fi
            ;;
        *)
            printf "  ⚠️ %-8s → %s\\n" "GPS" "GPS location not supported on this platform"
            ;;
    esac
    
    echo
    local percentage=$((available_features * 100 / total_features))
    print_status "📊 Available Features: $available_features/$total_features ($percentage% functionality)"
    echo
    
    # Export for use in other functions (arrays can't be exported, use globals)
    MISSING_CRITICAL=()
    MISSING_IMPORTANT=()
    MISSING_HELPFUL=()
    MISSING_OPTIONAL=()
    
    # Copy arrays if they have elements
    [[ ${#missing_critical[@]} -gt 0 ]] && MISSING_CRITICAL=("${missing_critical[@]}")
    [[ ${#missing_important[@]} -gt 0 ]] && MISSING_IMPORTANT=("${missing_important[@]}")
    [[ ${#missing_helpful[@]} -gt 0 ]] && MISSING_HELPFUL=("${missing_helpful[@]}")
    [[ ${#missing_optional[@]} -gt 0 ]] && MISSING_OPTIONAL=("${missing_optional[@]}")
    export AVAILABLE_FEATURES="$available_features"
    export TOTAL_FEATURES="$total_features"
    export FUNCTIONALITY_PERCENTAGE="$percentage"
    
    # Return status: 0=all good, 1=missing critical, 2=missing some
    if [ ${#missing_critical[@]} -gt 0 ]; then
        return 1
    elif [ $((${#missing_important[@]} + ${#missing_helpful[@]} + ${#missing_optional[@]})) -gt 0 ]; then
        return 2
    else
        return 0
    fi
}

# Original dependency check function (for backward compatibility)
check_dependencies() {
    print_status "Checking critical dependencies..."
    
    local missing_deps=()
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install missing dependencies:"
        print_status "  macOS: brew install ${missing_deps[*]}"
        print_status "  Linux: sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "Critical dependencies are available"
}

# Generate platform-specific install commands
generate_install_commands() {
    local all_missing=()
    
    # Combine all missing dependencies (check array existence first)
    [[ ${#MISSING_CRITICAL[@]} -gt 0 ]] && for dep in "${MISSING_CRITICAL[@]}"; do
        all_missing+=("$dep")
    done
    [[ ${#MISSING_IMPORTANT[@]} -gt 0 ]] && for dep in "${MISSING_IMPORTANT[@]}"; do
        all_missing+=("$dep")
    done
    [[ ${#MISSING_HELPFUL[@]} -gt 0 ]] && for dep in "${MISSING_HELPFUL[@]}"; do
        all_missing+=("$dep")
    done
    
    # Handle timeout specially (platform-specific)
    [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]] && for dep in "${MISSING_OPTIONAL[@]}"; do
        if [[ "$dep" == "timeout" && "$OS_PLATFORM" == "macOS" ]]; then
            all_missing+=("coreutils")  # Contains gtimeout on macOS
        elif [[ "$dep" == "timeout" ]]; then
            all_missing+=("coreutils")
        elif [[ "$dep" == "CoreLocationCLI" ]]; then
            all_missing+=("corelocationcli")  # macOS GPS tool
        elif [[ "$dep" == "geoclue" ]]; then
            all_missing+=("geoclue-2.0-dev")  # Linux GPS tool
        fi
    done
    
    if [ ${#all_missing[@]} -eq 0 ]; then
        echo "✅ All dependencies are already installed!"
        return 0
    fi
    
    echo "📦 Install missing dependencies:"
    echo
    
    case "$PKG_MGR" in
        "brew")
            echo "# macOS with Homebrew"
            local brew_deps=()
            for dep in "${all_missing[@]}"; do
                case "$dep" in
                    "bunx") brew_deps+=("bun") ;;
                    *) brew_deps+=("$dep") ;;
                esac
            done
            echo "$PKG_INSTALL_CMD ${brew_deps[*]}"
            ;;
        "apt")
            echo "# Ubuntu/Debian"
            local apt_deps=()
            for dep in "${all_missing[@]}"; do
                case "$dep" in
                    "bunx") 
                        echo "curl -fsSL https://bun.sh/install | bash"  # Special case for bun
                        ;;
                    *) apt_deps+=("$dep") ;;
                esac
            done
            [ ${#apt_deps[@]} -gt 0 ] && echo "$PKG_INSTALL_CMD ${apt_deps[*]}"
            ;;
        "yum"|"dnf")
            echo "# CentOS/RHEL/Fedora"
            local yum_deps=()
            for dep in "${all_missing[@]}"; do
                case "$dep" in
                    "bunx") 
                        echo "curl -fsSL https://bun.sh/install | bash"
                        ;;
                    *) yum_deps+=("$dep") ;;
                esac
            done
            [ ${#yum_deps[@]} -gt 0 ] && echo "$PKG_INSTALL_CMD ${yum_deps[*]}"
            ;;
        "pacman")
            echo "# Arch Linux"
            local pacman_deps=()
            for dep in "${all_missing[@]}"; do
                case "$dep" in
                    "bunx") 
                        echo "curl -fsSL https://bun.sh/install | bash"
                        ;;
                    *) pacman_deps+=("$dep") ;;
                esac
            done
            [ ${#pacman_deps[@]} -gt 0 ] && echo "$PKG_INSTALL_CMD ${pacman_deps[*]}"
            ;;
        "none")
            if [[ "$OS_PLATFORM" == "macOS" ]]; then
                echo "❌ No package manager detected on macOS"
                echo
                echo "Step 1: Install Homebrew first"
                echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                echo
                echo "Step 2: Then install dependencies"
                echo "brew install bun python3 bc jq coreutils"
                echo
                echo "Step 3: Re-run statusline installer"
                echo "sh -c \"\$(curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/install.sh)\""
            else
                echo "⚠️ Manual installation required"
                echo
                echo "Install these tools manually:"
                for dep in "${all_missing[@]}"; do
                    case "$dep" in
                        "bunx") echo "  • bun (from https://bun.sh)";;
                        *) echo "  • $dep";;
                    esac
                done
            fi
            ;;
    esac
    
    echo
}

# User choice interface
show_user_choice_menu() {
    echo -e "${BLUE}🎯 Choose your installation approach:${NC}"
    echo
    echo "1) Install statusline now, upgrade dependencies later"
    echo "   └─ $FUNCTIONALITY_PERCENTAGE% functionality, can upgrade anytime"
    echo
    echo "2) Show install commands only (copy-paste)"
    echo "   └─ Get exact commands for your system"
    echo
    echo "3) Exit to install dependencies manually first"
    echo "   └─ For users who prefer full setup before installation"
    echo
    
    while true; do
        read -p "Choice [1-3]: " choice
        case $choice in
            1)
                print_status "Proceeding with installation..."
                return 0
                ;;
            2)
                echo
                generate_install_commands
                echo
                print_status "Copy the commands above, then re-run this installer:"
                print_status "sh -c \"\$(curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/install.sh)\""
                exit 0
                ;;
            3)
                echo
                generate_install_commands
                echo
                print_status "Install the dependencies above, then re-run this installer."
                exit 0
                ;;
            *)
                echo "Please choose 1, 2, or 3"
                ;;
        esac
    done
}

# Parse command line arguments
parse_arguments() {
    ENHANCED_MODE=false
    INTERACTIVE_MODE=false
    MINIMAL_MODE=false
    SKIP_DEPS=false
    SHOW_HELP=false
    PRESERVE_STATUSLINE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-all-deps)
                ENHANCED_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --minimal)
                MINIMAL_MODE=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --branch)
                INSTALL_BRANCH="$2"
                shift 2
                ;;
            --branch=*)
                INSTALL_BRANCH="${1#*=}"
                shift
                ;;
            --preserve-statusline)
                PRESERVE_STATUSLINE=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# Show help information
show_help() {
    echo -e "${BLUE}Claude Code Enhanced Statusline - Installer${NC}"
    echo "============================================"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --check-all-deps    Use enhanced dependency checking (shows all 6 dependencies)"
    echo "  --interactive       Show user choice menu for installation approach"
    echo "  --minimal           Only check critical dependencies (curl, jq)"
    echo "  --skip-deps         Skip all dependency checks (install anyway)"
    echo "  --preserve-statusline  Skip settings.json configuration entirely"
    echo "  --debug             Enable detailed debug logging with timestamps"
    echo "  --help, -h          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                           # Standard installation (minimal deps)"
    echo "  $0 --check-all-deps         # Show full dependency analysis"
    echo "  $0 --interactive            # Interactive mode with user choices"
    echo "  $0 --check-all-deps --interactive  # Full analysis + user menu"
    echo "  $0 --preserve-statusline    # Install modules but keep settings.json unchanged"
    echo "  $0 --debug                  # Enable debug logging to trace installation flow"
    echo ""
    echo "Debug Mode:"
    echo "  STATUSLINE_INSTALL_DEBUG=true $0    # Enable debug via environment variable"
    echo "  $0 --debug --interactive           # Debug mode with interactive choices"
    echo
    echo "Rate Limit Optimization:"
    echo "  GITHUB_TOKEN=your_token $0   # Use GitHub token (5000/hour vs 60/hour)"
    echo "  export GITHUB_TOKEN=ghp_xxx  # Set token persistently"
    echo "  # Primary method uses raw URLs (no limits), token only for API fallback"
    echo
    echo "For more information, visit:"
    echo "https://github.com/rz1989s/claude-code-statusline"
    echo
}

# Function to create Claude directory if it doesn't exist
create_claude_directory() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        print_status "Creating Claude Code directory: $CLAUDE_DIR"
        mkdir -p "$CLAUDE_DIR"
        print_success "Created directory: $CLAUDE_DIR"
    else
        print_status "Claude Code directory already exists: $CLAUDE_DIR"
    fi
}

# Function to create lib directory for modules
create_lib_directory() {
    if [ ! -d "$LIB_DIR" ]; then
        print_status "Creating lib directory for modules: $LIB_DIR"
        mkdir -p "$LIB_DIR"
        print_success "Created directory: $LIB_DIR"
    else
        print_status "Lib directory already exists: $LIB_DIR"
    fi
}

# Function to download all modules using predefined structure (No API rate limits!)
download_directory_comprehensive() {
    local repo_path="$1"
    local local_path="$2"
    
    print_status "📦 Downloading all modules using optimized method (no rate limits)..."
    
    # Create local directory structure
    mkdir -p "$local_path"
    mkdir -p "$local_path/prayer"
    mkdir -p "$local_path/components"
    
    # ⚠️  CRITICAL REMINDER: HARDCODED MODULE LISTS - UPDATE WHEN ADDING NEW MODULES!
    # ========================================================================
    # When adding new modules to the repository, you MUST update these arrays:
    # 1. Add to appropriate array below (main_modules, prayer_modules, component_modules)
    # 2. Update the fallback function arrays (in download_lib_fallback function)
    # 3. Update verification function arrays (in verify_installation function) 
    # 4. Update expected_modules count (in verify_installation function)
    # 5. Test installation: curl ... | bash -s -- --branch=YOUR_BRANCH
    # 
    # Why hardcoded? Eliminates GitHub API rate limits (60/hour → unlimited)
    # Provides 100% reliability and fastest installation experience
    # ========================================================================
    
    # Define ALL modules based on known structure (eliminates API dependency)
    local main_modules=(
        "core.sh" "security.sh" "config.sh" "themes.sh" "cache.sh" 
        "git.sh" "mcp.sh" "cost.sh" "display.sh" "prayer.sh" "components.sh"
        # 🆕 ADD NEW MAIN MODULES HERE (lib/*.sh files)
    )
    
    local prayer_modules=(
        "prayer/location.sh" "prayer/calculation.sh" "prayer/display.sh" "prayer/core.sh" "prayer/timezone_methods.sh"
        # 🆕 ADD NEW PRAYER MODULES HERE (lib/prayer/*.sh files)
    )
    
    local component_modules=(
        "components/repo_info.sh" "components/version_info.sh" "components/time_display.sh"
        "components/model_info.sh" "components/cost_repo.sh" "components/cost_live.sh"
        "components/mcp_status.sh" "components/reset_timer.sh" "components/prayer_times.sh"
        "components/commits.sh"
        "components/submodules.sh" "components/cost_monthly.sh" "components/cost_weekly.sh"
        "components/cost_daily.sh" "components/burn_rate.sh" "components/token_usage.sh"
        "components/cache_efficiency.sh" "components/block_projection.sh"
        "components/location_display.sh"
        # 🆕 ADD NEW COMPONENT MODULES HERE (lib/components/*.sh files)
    )
    
    # Combine all modules
    local all_modules=("${main_modules[@]}" "${prayer_modules[@]}" "${component_modules[@]}")
    local files_downloaded=0
    local total_files=${#all_modules[@]}
    local failed_files=()
    
    print_status "📊 Downloading $total_files modules directly (bypassing API limits)..."
    
    # Download each module using direct raw URL (unlimited requests!)
    for module in "${all_modules[@]}"; do
        local raw_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/lib/$module"
        local file_path="$local_path/$module"
        local file_downloaded=false
        
        # Try downloading each file up to 3 times
        for attempt in {1..3}; do
            if curl -fsSL "$raw_url" -o "$file_path" 2>/dev/null && [[ -s "$file_path" ]]; then
                print_status "  ✓ Downloaded $module"
                ((files_downloaded++))
                file_downloaded=true
                break
            else
                [[ $attempt -lt 3 ]] && sleep 1
            fi
        done
        
        if [[ "$file_downloaded" == "false" ]]; then
            print_error "  ✗ Failed to download $module after 3 attempts"
            failed_files+=("$module")
        fi
    done
    
    # Report comprehensive results
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        print_error "❌ Failed to download ${#failed_files[@]} modules:"
        for failed_file in "${failed_files[@]}"; do
            print_error "  • $failed_file"
        done
        return 1
    else
        print_success "✅ Downloaded $files_downloaded/$total_files modules (100% success, no API limits used)"
        return 0
    fi
}

# Fallback function using GitHub API (only if comprehensive method fails)
download_directory_with_api_fallback() {
    local repo_path="$1"
    local local_path="$2"
    local depth="${3:-0}"
    local attempt="${4:-1}"
    local max_attempts=3
    
    # Check for GitHub token to increase rate limits
    local auth_header=""
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_header="-H \"Authorization: token $GITHUB_TOKEN\""
        print_status "🔑 Using GitHub token for enhanced rate limits (5000/hour)"
    else
        print_status "⚠️ No GitHub token - limited to 60 requests/hour"
    fi
    
    if [[ $attempt -eq 1 ]]; then
        print_status "📦 API fallback: discovering files in $repo_path..."
    else
        print_status "📦 API retry attempt $attempt/$max_attempts for $repo_path..."
    fi
    
    local api_url="https://api.github.com/repos/rz1989s/claude-code-statusline/contents/$repo_path?ref=$INSTALL_BRANCH"
    
    # Create local directory
    mkdir -p "$local_path"
    
    # Get directory contents with optional auth
    local contents
    if [[ -n "$auth_header" ]]; then
        contents=$(eval curl -fsSL $auth_header "$api_url" 2>/dev/null)
    else
        contents=$(curl -fsSL "$api_url" 2>/dev/null)
    fi
    
    if [[ -z "$contents" || "$contents" == "Not Found" || "$contents" == "null" ]]; then
        if [[ $attempt -lt $max_attempts ]]; then
            print_warning "API request failed for $repo_path, retrying in $((attempt * 2)) seconds..."
            sleep $((attempt * 2))
            return $(download_directory_with_api_fallback "$repo_path" "$local_path" "$depth" $((attempt + 1)))
        else
            print_error "Could not fetch directory contents after $max_attempts attempts: $repo_path"
            return 1
        fi
    fi
    
    # Check if jq is available for JSON parsing
    if ! command_exists jq; then
        print_error "jq is required for API discovery but not available"
        return 1
    fi
    
    local files_downloaded=0
    local total_files=0
    local failed_files=()
    
    # Download files (only .sh files) with individual retry
    while IFS='|' read -r download_url filename file_type; do
        [[ "$file_type" == "file" && "$filename" == *.sh ]] || continue
        
        ((total_files++))
        local file_path="$local_path/$filename"
        local file_downloaded=false
        
        # Try downloading each file up to 3 times
        for file_attempt in {1..3}; do
            if curl -fsSL "$download_url" -o "$file_path" 2>/dev/null && [[ -s "$file_path" ]]; then
                print_status "  ✓ Downloaded $repo_path/$filename"
                ((files_downloaded++))
                file_downloaded=true
                break
            else
                [[ $file_attempt -lt 3 ]] && sleep 1
            fi
        done
        
        if [[ "$file_downloaded" == "false" ]]; then
            print_error "  ✗ Failed to download $repo_path/$filename after 3 attempts"
            failed_files+=("$repo_path/$filename")
        fi
    done < <(echo "$contents" | jq -r '.[] | select(.type=="file") | "\(.download_url)|\(.name)|\(.type)"' 2>/dev/null)
    
    # Report results
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        print_error "Failed to download ${#failed_files[@]} files from $repo_path:"
        for failed_file in "${failed_files[@]}"; do
            print_error "  • $failed_file"
        done
        return 1
    elif [[ $files_downloaded -gt 0 ]]; then
        print_success "Downloaded $files_downloaded/$total_files files from $repo_path via API"
    fi
    
    return 0
}

# Function to download statusline script and modules
download_statusline() {
    print_status "Downloading modular statusline from repository..."
    
    # Create statusline directory first
    print_status "Creating statusline directory: $STATUSLINE_DIR"
    mkdir -p "$STATUSLINE_DIR"
    
    # Download main orchestrator script
    if curl -fsSL "$REPO_URL" -o "$STATUSLINE_PATH"; then
        print_success "Downloaded main statusline.sh to $STATUSLINE_PATH"
        
        # Make executable immediately after download for zero user interaction
        if chmod +x "$STATUSLINE_PATH"; then
            print_status "✓ Made statusline.sh executable (zero interaction required)"
        else
            print_warning "⚠️ Could not set executable permissions immediately"
        fi
    else
        print_error "Failed to download statusline.sh"
        exit 1
    fi
    
    # Smart version management - user local with update checking
    print_status "Managing statusline version..."
    
    # Version file paths
    local version_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/version.txt"
    local local_version_path="$STATUSLINE_DIR/version.txt"
    local current_version=""
    local new_version=""
    
    # Check if user already has a version file
    if [[ -f "$local_version_path" ]]; then
        current_version=$(cat "$local_version_path" 2>/dev/null | tr -d '[:space:]')
    fi
    
    # Download latest version to temp location first
    local temp_version="/tmp/statusline_version_check.txt"
    if curl -fsSL "$version_url" -o "$temp_version"; then
        new_version=$(cat "$temp_version" 2>/dev/null | tr -d '[:space:]')
        
        # Compare versions and update if needed
        if [[ "$current_version" != "$new_version" ]] || [[ ! -f "$local_version_path" ]]; then
            mv "$temp_version" "$local_version_path"
            if [[ -n "$current_version" ]]; then
                print_success "Updated statusline version: $current_version → $new_version"
            else
                print_success "Installed statusline version: $new_version"
            fi
            print_status "Version file: $local_version_path"
        else
            print_success "Version already up to date: $current_version"
            rm -f "$temp_version"
        fi
    else
        print_warning "Failed to check for version updates - using existing version"
        rm -f "$temp_version" 2>/dev/null
    fi
    
    # Create lib directory
    print_status "Creating lib directory for modules..."
    mkdir -p "$LIB_DIR"
    
    # Download all lib/ directory contents with multi-tier approach
    print_status "🚀 Downloading all lib/ modules with optimized strategy..."
    
    # Tier 1: Direct download using known structure (NO API limits, fastest)
    if download_directory_comprehensive "lib" "$LIB_DIR"; then
        local downloaded_count=$(find "$LIB_DIR" -name "*.sh" -type f | wc -l | tr -d ' ')
        print_success "✅ Tier 1 success: $downloaded_count modules downloaded (no API limits used)"
    else
        print_warning "⚠️ Tier 1 (direct download) failed"
        
        # Tier 2: GitHub API with optional token support
        print_status "🔄 Trying Tier 2: GitHub API discovery..."
        if download_directory_with_api_fallback "lib" "$LIB_DIR"; then
            local downloaded_count=$(find "$LIB_DIR" -name "*.sh" -type f | wc -l | tr -d ' ')
            print_success "✅ Tier 2 success: $downloaded_count modules downloaded via API"
        else
            print_warning "⚠️ Tier 2 (API discovery) also failed"
            
            # Tier 3: Comprehensive fallback with same known structure
            print_status "🔄 Tier 3: Final comprehensive fallback..."
            download_lib_fallback
        fi
    fi
    
    # Final verification that we have adequate modules
    local final_count=$(find "$LIB_DIR" -name "*.sh" -type f | wc -l | tr -d ' ')
    if [[ $final_count -lt 15 ]]; then
        print_error "🚨 CRITICAL: Only $final_count modules downloaded - installation incomplete"
        print_error "💡 All modules are required for proper functionality"
        print_status "🔧 Troubleshooting:"
        print_status "  1. Check internet connection to GitHub"
        print_status "  2. Verify branch '$INSTALL_BRANCH' exists"
        print_status "  3. For rate limit issues, set GITHUB_TOKEN environment variable"
        exit 1
    else
        print_success "🎉 Module download complete: $final_count modules ready (100% functionality guaranteed)"
    fi
}

# Comprehensive fallback function - downloads ALL modules with retry mechanism
download_lib_fallback() {
    print_status "🔄 Using comprehensive fallback download method for ALL modules..."
    
    # ⚠️  CRITICAL REMINDER: HARDCODED MODULE LISTS - KEEP IN SYNC!
    # ================================================================
    # These arrays MUST match the arrays in download_directory_comprehensive()
    # When you add new modules there, add them here too for fallback support
    # ================================================================
    
    # ALL modules that must exist - comprehensive list for 100% functionality
    local main_modules=(
        "core.sh" "security.sh" "config.sh" "themes.sh" "cache.sh" 
        "git.sh" "mcp.sh" "cost.sh" "display.sh" "prayer.sh" "components.sh"
        # 🆕 ADD NEW MAIN MODULES HERE (must match line 500-504 arrays)
    )
    
    # Prayer system modules (lib/prayer/)
    local prayer_modules=(
        "prayer/location.sh" "prayer/calculation.sh" "prayer/display.sh" "prayer/core.sh" "prayer/timezone_methods.sh"
        # 🆕 ADD NEW PRAYER MODULES HERE (must match line 506-508 arrays)
    )
    
    # Component modules (lib/components/) - all 18 components
    local component_modules=(
        "components/repo_info.sh" "components/version_info.sh" "components/time_display.sh"
        "components/model_info.sh" "components/cost_repo.sh" "components/cost_live.sh"
        "components/mcp_status.sh" "components/reset_timer.sh" "components/prayer_times.sh"
        "components/commits.sh"
        "components/submodules.sh" "components/cost_monthly.sh" "components/cost_weekly.sh"
        "components/cost_daily.sh" "components/burn_rate.sh" "components/token_usage.sh"
        "components/cache_efficiency.sh" "components/block_projection.sh"
        "components/location_display.sh"
        # 🆕 ADD NEW COMPONENT MODULES HERE (must match line 508-515 arrays)
    )
    
    # Combine all modules for comprehensive download
    local all_modules=("${main_modules[@]}" "${prayer_modules[@]}" "${component_modules[@]}")
    local failed_modules=()
    local successful_downloads=0
    local total_modules=${#all_modules[@]}
    
    print_status "📊 Attempting to download $total_modules modules comprehensively..."
    
    # Create subdirectories
    mkdir -p "$LIB_DIR/prayer"
    mkdir -p "$LIB_DIR/components"
    
    # Download each module with retry mechanism
    for module in "${all_modules[@]}"; do
        local module_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/lib/$module"
        local module_path="$LIB_DIR/$module"
        local module_downloaded=false
        
        # Try downloading each module up to 3 times
        for attempt in {1..3}; do
            if curl -fsSL "$module_url" -o "$module_path" 2>/dev/null && [[ -s "$module_path" ]]; then
                print_status "✓ Downloaded $module"
                ((successful_downloads++))
                module_downloaded=true
                break
            else
                [[ $attempt -lt 3 ]] && sleep 1
            fi
        done
        
        if [[ "$module_downloaded" == "false" ]]; then
            print_error "✗ Failed to download $module after 3 attempts"
            failed_modules+=("$module")
        fi
    done
    
    # Report comprehensive results
    echo
    print_status "📊 Fallback download summary:"
    print_status "  • Successfully downloaded: $successful_downloads/$total_modules modules"
    print_status "  • Success rate: $(( successful_downloads * 100 / total_modules ))%"
    
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        print_error "❌ FALLBACK FAILED: Could not download ${#failed_modules[@]} modules:"
        for failed_module in "${failed_modules[@]}"; do
            print_error "  • $failed_module"
        done
        echo
        print_error "🚨 Installation cannot continue with incomplete module set"
        print_error "💡 All modules are critical for proper functionality"
        print_status "🔧 Troubleshooting steps:"
        print_status "  1. Check your internet connection"
        print_status "  2. Verify GitHub.com is accessible"
        print_status "  3. Try again in a few minutes"
        print_status "  4. If issue persists, check if branch '$INSTALL_BRANCH' exists"
        exit 1
    else
        print_success "🎉 FALLBACK SUCCESS: All $total_modules modules downloaded (100% complete)"
        print_status "💡 Comprehensive fallback ensured full functionality"
        return 0
    fi
}


# Function to download all example configurations
download_examples() {
    print_status "📚 Downloading example configurations..."
    
    # Create examples directory structure
    print_status "Creating examples directory structure..."
    mkdir -p "$EXAMPLES_DIR"
    
    # Single source architecture - only comprehensive Config.toml needed (v2.8.0)
    local modular_configs=()  # No longer needed - single source approach
    
    local traditional_configs=(
        "Config.toml"  # The ONE comprehensive configuration template
    )
    
    
    local failed_downloads=()
    local successful_downloads=0
    
    # Single source architecture - no modular configs needed (v2.8.0)
    print_status "📦 Single source architecture - using comprehensive Config.toml only"
    
    # Download comprehensive Config.toml (single source of truth)
    print_status "📦 Downloading comprehensive configuration template..."
    for config in "${traditional_configs[@]}"; do
        # Download Config.toml to examples/ as reference template
        local config_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/examples/$config"
        local config_path="$EXAMPLES_DIR/$config"
        
        if curl -fsSL "$config_url" -o "$config_path"; then
            print_status "  ✓ Downloaded $config (reference template)"
            ((successful_downloads++))
        else
            print_error "  ✗ Failed to download $config"
            failed_downloads+=("$config")
        fi
    done
    
    
    # Download examples README.md
    print_status "📦 Downloading examples documentation..."
    local readme_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/examples/README.md"
    local readme_path="$EXAMPLES_DIR/README.md"
    
    if curl -fsSL "$readme_url" -o "$readme_path"; then
        print_status "  ✓ Downloaded examples/README.md"
        ((successful_downloads++))
    else
        print_error "  ✗ Failed to download examples/README.md"
        failed_downloads+=("examples/README.md")
    fi
    
    # Report results
    echo
    print_success "📊 Examples download summary:"
    print_success "  ✅ Successfully downloaded: $successful_downloads configurations"
    
    if [[ ${#failed_downloads[@]} -gt 0 ]]; then
        print_warning "  ⚠️ Failed downloads: ${#failed_downloads[@]} configurations"
        for failed_config in "${failed_downloads[@]}"; do
            print_error "    • $failed_config"
        done
        
        if [[ $successful_downloads -gt 0 ]]; then
            print_status "💡 Partial success: You can still use the downloaded configurations"
            return 0
        else
            print_error "❌ No examples downloaded successfully"
            return 1
        fi
    else
        print_success "🎉 All example configurations downloaded successfully!"
        print_status "📁 Available at: $EXAMPLES_DIR"
        return 0
    fi
}

# Function to check bash compatibility (informational only)
check_bash_compatibility() {
    print_status "Checking bash compatibility..."
    
    # Check if we're using modern bash that supports associative arrays
    if /bin/bash -c 'declare -A test_array' 2>/dev/null; then
        print_success "System bash supports all features"
        return 0
    fi
    
    # Check for modern bash installations  
    local modern_bash_found=false
    for bash_path in "/opt/homebrew/bin/bash" "/usr/local/bin/bash" "/opt/local/bin/bash"; do
        if [[ -x "$bash_path" ]] && "$bash_path" -c 'declare -A test_array' 2>/dev/null; then
            print_success "Modern bash found: $bash_path"
            modern_bash_found=true
            break
        fi
    done
    
    if [[ "$modern_bash_found" == "false" ]]; then
        print_warning "Modern bash not found - some advanced features may not work"
        print_status "For full functionality, consider: brew install bash"
        print_status "Statusline includes automatic compatibility detection"
    else
        print_success "Statusline will automatically use modern bash features"
    fi
}

# Function to make statusline executable with error handling
make_executable() {
    print_status "Making statusline.sh executable..."
    
    # Check if file exists first
    if [[ ! -f "$STATUSLINE_PATH" ]]; then
        print_error "Cannot make executable: $STATUSLINE_PATH does not exist"
        return 1
    fi
    
    # Make executable with error handling
    if chmod +x "$STATUSLINE_PATH"; then
        print_success "Made statusline.sh executable"
        
        # Verify it's actually executable
        if [[ -x "$STATUSLINE_PATH" ]]; then
            print_status "✓ Verified: statusline.sh has executable permissions"
        else
            print_warning "⚠️ chmod succeeded but file may not be executable"
        fi
    else
        print_error "Failed to make statusline.sh executable"
        print_status "💡 You may need to run manually: chmod +x $STATUSLINE_PATH"
        return 1
    fi
}

# Function to configure settings.json
configure_settings() {
    print_status "Configuring Claude Code settings..."

    # Skip if user wants to preserve existing settings
    if [ "$PRESERVE_STATUSLINE" = "true" ]; then
        print_status "Preserving existing settings (--preserve-statusline)"
        return 0
    fi

    # Always backup settings.json if it exists (same format as statusline backup)
    if [ -f "$SETTINGS_PATH" ]; then
        local backup_path="${SETTINGS_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$SETTINGS_PATH" "$backup_path"
        print_success "Backed up settings.json to $backup_path (restore: cp \"$backup_path\" \"$SETTINGS_PATH\")"
    fi

    local temp_settings=$(mktemp)

    # Always set canonical statusline command
    if [ -f "$SETTINGS_PATH" ]; then
        # Update existing file - preserve everything, only replace statusLine
        print_status "Updating existing settings.json with statusline configuration..."
        jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline/statusline.sh"}' \
           "$SETTINGS_PATH" > "$temp_settings"
    else
        # Create new file
        print_status "Creating new settings.json file..."
        cat > "$temp_settings" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline/statusline.sh"
  }
}
EOF
    fi

    # Validate and apply
    if jq . "$temp_settings" >/dev/null 2>&1; then
        mv "$temp_settings" "$SETTINGS_PATH"
        print_success "Configured settings.json with statusline"
    else
        print_error "Failed to configure settings.json"
        rm -f "$temp_settings"
        exit 1
    fi

    # Clean up temp file if it still exists
    [ -f "$temp_settings" ] && rm -f "$temp_settings" || true
}

# Function to safely remove directory with timeout protection
safe_remove_directory() {
    trace_execution "safe_remove_directory $1"
    local dir_path="$1"
    local timeout_seconds="${2:-30}"  # Default 30 seconds timeout

    if [[ ! -d "$dir_path" ]]; then
        print_debug "Directory doesn't exist: $dir_path"
        print_status "✓ Directory doesn't exist: $dir_path"
        return 0
    fi

    print_debug "Starting directory removal with ${timeout_seconds}s timeout: $dir_path"
    print_status "🗑️ Removing directory with timeout protection: $dir_path"

    # Detect available timeout command (prefer gtimeout on macOS)
    local timeout_cmd=""
    if command_exists "gtimeout"; then
        timeout_cmd="gtimeout"
    elif command_exists "timeout"; then
        timeout_cmd="timeout"
    fi

    # Remove directory with optional timeout protection
    if [[ -n "$timeout_cmd" ]]; then
        if $timeout_cmd "${timeout_seconds}s" rm -rf "$dir_path" 2>/dev/null; then
            print_success "✅ Directory removed successfully: $dir_path"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                print_error "❌ Directory removal timed out after ${timeout_seconds}s: $dir_path"
            else
                print_error "❌ Failed to remove directory: $dir_path (exit code: $exit_code)"
            fi
            return 1
        fi
    else
        # Fallback to direct rm without timeout protection
        print_warning "⚠️ No timeout command available, using direct rm"
        if rm -rf "$dir_path" 2>/dev/null; then
            print_success "✅ Directory removed successfully: $dir_path"
            return 0
        else
            print_error "❌ Failed to remove directory: $dir_path"
            return 1
        fi
    fi
}

# Function to safely terminate any running statusline processes
terminate_statusline_processes() {
    trace_execution "terminate_statusline_processes"
    print_status "🔍 Checking for running statusline processes..."

    # Find statusline processes (excluding grep itself)
    local statusline_pids=$(pgrep -f "statusline.sh" 2>/dev/null | grep -v $$ || true)

    if [[ -n "$statusline_pids" ]]; then
        print_status "⚠️ Found running statusline processes: $(echo $statusline_pids | tr '\n' ' ')"

        # Send TERM signal first for graceful shutdown
        for pid in $statusline_pids; do
            if kill -0 "$pid" 2>/dev/null; then
                print_status "  📤 Sending TERM signal to process $pid"
                kill -TERM "$pid" 2>/dev/null || true
            fi
        done

        # Wait briefly for graceful shutdown
        sleep 2

        # Check if any processes are still running and force kill if needed
        local remaining_pids=$(pgrep -f "statusline.sh" 2>/dev/null | grep -v $$ || true)
        if [[ -n "$remaining_pids" ]]; then
            print_warning "🔨 Force killing remaining statusline processes: $(echo $remaining_pids | tr '\n' ' ')"
            for pid in $remaining_pids; do
                if kill -0 "$pid" 2>/dev/null; then
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            done
            sleep 1
        fi

        print_success "✅ All statusline processes terminated"
    else
        print_status "✓ No running statusline processes found"
    fi
}

# Simplified backup function - backup entire statusline folder if exists
backup_existing_installation() {
    trace_execution "backup_existing_installation"
    if [ -d "$STATUSLINE_DIR" ]; then
        local backup_path="${STATUSLINE_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "🔄 Existing statusline installation found, creating backup..."
        
        if cp -r "$STATUSLINE_DIR" "$backup_path"; then
            print_success "✅ Backup created: $backup_path"
            print_status "💡 Your entire statusline configuration has been preserved"

            # Terminate any running statusline processes before removal
            terminate_statusline_processes

            # Remove old installation after successful backup with timeout protection
            if safe_remove_directory "$STATUSLINE_DIR" 30; then
                print_status "🧹 Removed old installation for clean install"
                return 0
            else
                print_error "❌ Failed to remove old installation - continuing anyway"
                print_warning "💡 You may need to manually remove: $STATUSLINE_DIR"
                return 0  # Continue installation even if removal fails
            fi
        else
            print_error "❌ Failed to create backup - installation aborted"
            exit 1
        fi
    else
        print_status "No existing statusline installation found"
        return 1
    fi
}

# Function to clean cache directories for fresh installation
clean_cache_directories() {
    trace_execution "clean_cache_directories"
    print_status "🧹 Cleaning cache directories for fresh installation..."

    # Cache directories to clean (both primary and fallback locations)
    local cache_dirs=(
        "$HOME/.cache/claude-code-statusline"
        "$HOME/.local/share/claude-code-statusline"
    )

    local cleaned_count=0

    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            print_status "  🗑️ Removing old cache: $cache_dir"
            if safe_remove_directory "$cache_dir" 15; then
                print_success "  ✅ Cache cleared: $cache_dir"
                ((cleaned_count++))
            else
                print_warning "  ⚠️ Failed to clear cache: $cache_dir"
            fi
        fi
    done

    if [ $cleaned_count -gt 0 ]; then
        print_success "🎉 Cache cleanup complete: $cleaned_count directories cleared"
        print_status "💡 Cache will rebuild automatically with correct format on first run"
    else
        print_status "✓ No existing cache found - starting with clean slate"
    fi

    return 0
}

# Function to download Config.toml template (simplified - no individual backup)
download_config_template() {
    print_status "Setting up comprehensive TOML configuration..."
    
    # Download comprehensive config template from repository  
    local config_template_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/examples/Config.toml"
    print_status "🔧 Downloading comprehensive Config.toml template..."
    
    if curl -fsSL "$config_template_url" -o "$CONFIG_PATH"; then
        # Verify the downloaded file is valid
        if [[ -f "$CONFIG_PATH" ]] && [[ -s "$CONFIG_PATH" ]]; then
            local line_count=$(wc -l < "$CONFIG_PATH" 2>/dev/null || echo "0")
            print_success "✅ Downloaded comprehensive Config.toml template ($line_count lines)"
            print_status "💡 Edit $CONFIG_PATH to customize your statusline"
            print_status "🔧 All 227 settings in ONE file - no more hunting for parameters!"
            print_status "📚 Single source of truth - all configurations pre-filled with sensible defaults"
            print_status "🎯 Revolutionary simplification: ONE file replaces 13 different configs"
            print_status "🧩 Edit display.lines and components arrays for 1-9 line layouts"
            return 0
        else
            print_error "❌ Downloaded config template appears to be empty or invalid"
            return 1
        fi
    else
        print_error "❌ Failed to download config template from: $config_template_url"
        print_status "🔍 This might be a network issue or the template file doesn't exist in branch: $INSTALL_BRANCH"
        return 1
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying modular statusline installation..."
    
    # Check if statusline.sh exists and is executable
    if [ -x "$STATUSLINE_PATH" ]; then
        print_success "statusline.sh is installed and executable"
    else
        print_error "statusline.sh is not properly installed or not executable"
        return 1
    fi
    
    # Check if lib directory exists
    if [ -d "$LIB_DIR" ]; then
        print_success "lib directory exists"
    else
        print_error "lib directory is missing"
        return 1
    fi
    
    # Check if examples directory exists
    if [ -d "$EXAMPLES_DIR" ]; then
        print_success "examples directory exists"
        
        # Check comprehensive Config.toml (single source architecture)
        local config_count=$(find "$EXAMPLES_DIR" -name "Config.toml" -type f | wc -l | tr -d ' ')
        print_status "  • $config_count comprehensive Config.toml template (single source of truth)"
    else
        print_warning "examples directory is missing (configurations will be limited)"
    fi
    
    # Strict module verification with comprehensive checks
    local total_modules=0
    local missing_critical_modules=()
    local expected_modules=32  # 🆕 UPDATE THIS COUNT when adding new modules!
    
    # ⚠️  CRITICAL REMINDER: HARDCODED MODULE LISTS - KEEP IN SYNC!
    # ================================================================
    # These arrays MUST match the arrays in download_directory_comprehensive()
    # and download_lib_fallback() functions. When you add modules there, add here too.
    # ================================================================
    
    # Define all expected critical modules for verification
    local all_critical_modules=(
        "core.sh" "security.sh" "config.sh" "themes.sh" "cache.sh" 
        "git.sh" "mcp.sh" "cost.sh" "display.sh" "prayer.sh" "components.sh"
        # 🆕 ADD NEW CRITICAL MODULES HERE (must match other functions)
    )
    
    # Count all .sh files in lib/ directory and subdirectories
    if [ -d "$LIB_DIR" ]; then
        total_modules=$(find "$LIB_DIR" -name "*.sh" -type f | wc -l | tr -d ' ')
        print_status "📊 Found $total_modules total modules in lib/ directory"
        
        # Verify all critical modules exist
        for module in "${all_critical_modules[@]}"; do
            if [ -f "$LIB_DIR/$module" ]; then
                print_status "✓ Essential module $module found"
            else
                print_error "✗ Essential module $module missing"
                missing_critical_modules+=("$module")
            fi
        done
        
        # Check subdirectories with detailed reporting
        local prayer_count=0
        local component_count=0
        
        if [ -d "$LIB_DIR/prayer" ]; then
            prayer_count=$(find "$LIB_DIR/prayer" -name "*.sh" -type f | wc -l | tr -d ' ')
            print_status "  • Prayer modules: $prayer_count files"
            [[ $prayer_count -lt 5 ]] && print_warning "    Expected ≥5 prayer modules"
        else
            print_warning "  • Prayer directory missing"
        fi
        
        if [ -d "$LIB_DIR/components" ]; then
            component_count=$(find "$LIB_DIR/components" -name "*.sh" -type f | wc -l | tr -d ' ')
            print_status "  • Component modules: $component_count files"
            [[ $component_count -lt 20 ]] && print_warning "    Expected 20 component modules"
        else
            print_warning "  • Components directory missing"
        fi
        
        # Strict validation - require ALL modules for success
        if [[ ${#missing_critical_modules[@]} -gt 0 ]]; then
            print_error "❌ Missing essential modules: ${missing_critical_modules[*]}"
            return 1
        elif [[ $total_modules -lt 15 ]]; then
            print_error "❌ Insufficient modules: $total_modules found (expected ≥15 for full functionality)"
            print_error "💡 This indicates an incomplete installation"
            return 1
        elif [[ $total_modules -lt $expected_modules ]]; then
            print_warning "⚠️ Module count below optimal: $total_modules found (expected ~$expected_modules)"
            print_warning "💡 Some advanced features may be unavailable"
            print_success "✅ Core functionality verified ($total_modules modules)"
        else
            print_success "✅ Complete installation verified: $total_modules modules (100% functionality)"
        fi
    else
        print_error "❌ lib directory is missing - critical installation failure"
        return 1
    fi
    
    # Check if settings.json exists and contains statusLine configuration
    if [ -f "$SETTINGS_PATH" ]; then
        if jq -e '.statusLine.command' "$SETTINGS_PATH" >/dev/null 2>&1; then
            local command_value=$(jq -r '.statusLine.command' "$SETTINGS_PATH")
            if [[ "$command_value" == "bash ~/.claude/statusline.sh" ]] || [[ "$command_value" == "bash ~/.claude/statusline/statusline.sh" ]]; then
                print_success "settings.json is properly configured"
            else
                print_warning "settings.json exists but statusLine command is: $command_value"
            fi
        else
            print_error "settings.json exists but statusLine configuration is missing"
            return 1
        fi
    else
        print_error "settings.json does not exist"
        return 1
    fi
    
    # Test statusline script
    print_status "Testing statusline script..."
    if "$STATUSLINE_PATH" --help >/dev/null 2>&1; then
        print_success "statusline.sh is working correctly"
    else
        print_warning "statusline.sh may have issues (this could be normal if dependencies are missing)"
    fi
}

# Enhanced installation success messaging
show_enhanced_completion() {
    echo
    echo -e "${GREEN}🎉 Claude Code Statusline Installed Successfully!${NC}"
    echo
    echo -e "${BLUE}📊 Current Status:${NC}"
    echo "✅ Core functionality (git, themes, display)"
    echo "✅ Configuration system"
    
    # Show what's missing and how to get it
    if [ ${#MISSING_IMPORTANT[@]} -gt 0 ] || [ ${#MISSING_HELPFUL[@]} -gt 0 ] || [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
        for dep in "${MISSING_IMPORTANT[@]}"; do
            case "$dep" in
                "bunx") echo "❌ Cost tracking (install: $PKG_INSTALL_CMD bun)";;
            esac
        done
        for dep in "${MISSING_HELPFUL[@]}"; do
            case "$dep" in
                "bc") echo "❌ Precise cost calculations (install: $PKG_INSTALL_CMD bc)";;
                "python3") echo "❌ Advanced TOML features (install: $PKG_INSTALL_CMD python3)";;
            esac
        done
        
        echo
        echo -e "${BLUE}🔧 Upgrade to $TOTAL_FEATURES/$TOTAL_FEATURES features (100%):${NC}"
        if [[ "$PKG_MGR" != "none" ]]; then
            local upgrade_deps=()
            for dep in "${MISSING_IMPORTANT[@]}" "${MISSING_HELPFUL[@]}"; do
                case "$dep" in
                    "bunx") upgrade_deps+=("bun") ;;
                    *) upgrade_deps+=("$dep") ;;
                esac
            done
            if [ ${#upgrade_deps[@]} -gt 0 ]; then
                echo "  $PKG_INSTALL_CMD ${upgrade_deps[*]}"
            fi
        else
            echo "  See installation commands above"
        fi
    else
        echo "✅ All features available ($TOTAL_FEATURES/$TOTAL_FEATURES)"
    fi
    
    echo
    echo -e "${BLUE}📁 Files installed:${NC}"
    echo "  $STATUSLINE_PATH"
    echo "  $CONFIG_PATH"
    echo "  $SETTINGS_PATH (updated)"
    echo
    echo -e "${BLUE}🧩 100% Complete Installation:${NC}"
    echo "  • Dynamic discovery with comprehensive fallback"
    echo "  • ALL modules downloaded (retry mechanism ensures 100% success)"
    echo "  • Single comprehensive Config.toml (227 settings)" 
    echo "  • All 18 statusline components + prayer system available"
    echo "  • Zero missing functionality - full feature set guaranteed"
    echo "  • Browse: ls $EXAMPLES_DIR"
    echo "  • Customize: edit $CONFIG_PATH"
    echo
    echo -e "${BLUE}🚀 Ready to use! Start a new Claude Code session.${NC}"
    echo
}

# Function to show completion message (fallback for simple installs)
show_completion() {
    echo
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Start a new Claude Code session to see your enhanced statusline"
    echo "2. Your statusline will automatically use the default theme"
    echo "3. To customize themes and features, see the Configuration section in README.md"
    echo
    echo -e "${BLUE}📁 Statusline files organized in: ~/.claude/statusline/${NC}"
    echo "  • statusline.sh     ← Enhanced statusline script"
    echo "  • Config.toml       ← Your configuration file (227 settings)"
    echo "  • lib/              ← Auto-discovered modules"
    echo "  • examples/         ← Configuration templates"
    echo
    echo -e "${BLUE}📁 Claude Code settings: ~/.claude/${NC}"
    echo "  • settings.json     ← Claude Code integration"
    echo
    echo -e "${BLUE}🎨 Customize your statusline:${NC}"
    echo "  edit ~/.claude/statusline/Config.toml"
    echo "  ~/.claude/statusline/statusline.sh --test-config"
    echo
    echo -e "${BLUE}🧩 Single source configuration (v2.8.2):${NC}"
    echo "  edit ~/.claude/statusline/Config.toml  # All 227 settings in ONE file"
    echo "  ENV_CONFIG_THEME=garden ./statusline.sh  # Test theme override"
    echo
    echo -e "${BLUE}Test your installation:${NC}"
    echo "  $STATUSLINE_PATH --help"
    echo
}

# Main installation function
main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    # Set dynamic URLs based on final branch selection
    REPO_URL="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/statusline.sh"
    
    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi
    
    echo -e "${BLUE}Claude Code Enhanced Statusline - Automated Installer${NC}"
    echo "=================================================="
    echo
    
    # Show branch information for transparency
    if [[ "$INSTALL_BRANCH" != "main" ]]; then
        print_status "🔧 Installing from branch: $INSTALL_BRANCH"
        echo
    fi
    
    # Choose dependency checking approach based on flags
    if [ "$SKIP_DEPS" = true ]; then
        print_status "Skipping all dependency checks (--skip-deps mode)"
        echo
    elif [ "$ENHANCED_MODE" = true ] || [ "$INTERACTIVE_MODE" = true ]; then
        # Enhanced mode: full dependency analysis
        detect_system_capabilities
        echo
        
        check_all_dependencies
        local dep_status=$?
        
        # Handle different dependency scenarios
        if [ $dep_status -eq 1 ]; then
            # Missing critical dependencies - must exit
            print_error "Missing critical dependencies required for installation"
            generate_install_commands
            exit 1
        elif [ $dep_status -eq 2 ] && [ "$INTERACTIVE_MODE" = true ]; then
            # Missing some dependencies - offer choices if interactive
            show_user_choice_menu
        elif [ $dep_status -eq 2 ]; then
            # Missing some dependencies - show info but continue
            print_warning "Some optional dependencies are missing (use --interactive for options)"
            generate_install_commands
        else
            # All dependencies available
            print_success "All dependencies available - proceeding with installation"
        fi
        echo
    else
        # Standard mode: minimal dependency check (backward compatibility)
        check_dependencies
        echo
    fi
    
    trace_execution "main installation flow"

    print_debug "Step 1: Creating Claude directory"
    create_claude_directory

    print_debug "Step 2: Cleaning cache directories (before backup)"
    clean_cache_directories  # Clear cache BEFORE backup and removal to prevent hangs

    print_debug "Step 3: Backing up existing installation"
    backup_existing_installation || true  # Don't fail if no existing installation

    print_debug "Step 4: Downloading statusline"
    download_statusline

    print_debug "Step 5: Downloading examples"
    download_examples  # Download all example configurations

    print_debug "Step 6: Checking bash compatibility"
    check_bash_compatibility

    print_debug "Step 7: Making executable"
    make_executable

    print_debug "Step 8: Configuring settings"
    configure_settings

    print_debug "Step 9: Downloading config template"
    download_config_template  # Fail installation if config template download fails
    
    echo
    if verify_installation; then
        if [ "$ENHANCED_MODE" = true ] || [ "$INTERACTIVE_MODE" = true ]; then
            show_enhanced_completion
        else
            show_completion
        fi
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Handle script interruption
trap 'echo; print_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"