#!/bin/bash

# Claude Code Enhanced Statusline - Automated Installation Script
# This script downloads and configures the statusline for Claude Code

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
if [[ "${BASH_SOURCE[0]}" =~ githubusercontent\.com/.*/(.*)/install\.sh ]]; then
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
CONFIG_PATH="$STATUSLINE_DIR/Config.toml"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    local optional_deps=("timeout:Network operation protection (gtimeout on macOS)")
    
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
                echo "curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/install.sh | bash"
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
                print_status "curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/install.sh | bash"
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
    echo "  --help, -h          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                           # Standard installation (minimal deps)"
    echo "  $0 --check-all-deps         # Show full dependency analysis"
    echo "  $0 --interactive            # Interactive mode with user choices"
    echo "  $0 --check-all-deps --interactive  # Full analysis + user menu"
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

# Function to download statusline script and modules
download_statusline() {
    print_status "Downloading modular statusline from repository..."
    
    # Create statusline directory first
    print_status "Creating statusline directory: $STATUSLINE_DIR"
    mkdir -p "$STATUSLINE_DIR"
    
    # Download main orchestrator script
    if curl -fsSL "$REPO_URL" -o "$STATUSLINE_PATH"; then
        print_success "Downloaded main statusline.sh to $STATUSLINE_PATH"
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
    
    # Download all modules
    print_status "Downloading statusline modules..."
    local modules=("core.sh" "security.sh" "config.sh" "themes.sh" "git.sh" "mcp.sh" "cost.sh" "display.sh" "cache.sh")
    local failed_modules=()
    
    for module in "${modules[@]}"; do
        local module_url="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/$INSTALL_BRANCH/lib/$module"
        local module_path="$LIB_DIR/$module"
        
        if curl -fsSL "$module_url" -o "$module_path"; then
            print_status "✓ Downloaded $module"
        else
            print_error "✗ Failed to download $module"
            failed_modules+=("$module")
        fi
    done
    
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        print_error "Failed to download modules: ${failed_modules[*]}"
        print_error "Statusline may not function properly without all modules"
        exit 1
    else
        print_success "All modules downloaded successfully"
    fi
}

# Function to fix bash shebang for compatibility
fix_bash_shebang() {
    print_status "Checking bash compatibility..."
    
    # Check if we're using modern bash that supports associative arrays
    if /bin/bash -c 'declare -A test_array' 2>/dev/null; then
        print_success "System bash supports all features"
        return 0
    fi
    
    # Find modern bash location
    local modern_bash=""
    for bash_path in "/opt/homebrew/bin/bash" "/usr/local/bin/bash" "/bin/bash"; do
        if [[ -x "$bash_path" ]] && "$bash_path" -c 'declare -A test_array' 2>/dev/null; then
            modern_bash="$bash_path"
            break
        fi
    done
    
    if [[ -n "$modern_bash" ]]; then
        print_status "Updating shebang to use modern bash: $modern_bash"
        if sed -i '' "1s|#!/bin/bash|#!$modern_bash|" "$STATUSLINE_PATH"; then
            print_success "Updated bash shebang for compatibility"
        else
            print_warning "Could not update bash shebang, but statusline should still work"
        fi
    else
        print_warning "Modern bash not found - some features may not work properly"
        print_status "Consider installing bash 4+ via: brew install bash"
    fi
}

# Function to make statusline executable
make_executable() {
    print_status "Making statusline.sh executable..."
    chmod +x "$STATUSLINE_PATH"
    print_success "Made statusline.sh executable"
}

# Function to configure settings.json
configure_settings() {
    print_status "Configuring Claude Code settings..."
    
    local temp_settings=$(mktemp)
    
    # Check if settings.json exists
    if [ -f "$SETTINGS_PATH" ]; then
        print_status "Found existing settings.json, updating configuration..."
        
        # Create new settings with statusLine configuration
        if jq --arg cmd "bash ~/.claude/statusline/statusline.sh" \
           '.statusLine = {"type": "command", "command": $cmd}' \
           "$SETTINGS_PATH" > "$temp_settings"; then
            
            # Validate the JSON is properly formatted
            if jq . "$temp_settings" >/dev/null 2>&1; then
                mv "$temp_settings" "$SETTINGS_PATH"
                print_success "Updated existing settings.json with statusline configuration"
            else
                print_error "Generated invalid JSON, keeping original settings.json"
                rm -f "$temp_settings"
                exit 1
            fi
        else
            print_error "Failed to update settings.json"
            rm -f "$temp_settings"
            exit 1
        fi
    else
        print_status "Creating new settings.json file..."
        
        # Create minimal settings.json with statusline configuration
        cat > "$temp_settings" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline/statusline.sh"
  }
}
EOF
        
        # Validate the JSON
        if jq . "$temp_settings" >/dev/null 2>&1; then
            mv "$temp_settings" "$SETTINGS_PATH"
            print_success "Created new settings.json with statusline configuration"
        else
            print_error "Failed to create valid settings.json"
            rm -f "$temp_settings"
            exit 1
        fi
    fi
    
    # Clean up temp file if it still exists
    [ -f "$temp_settings" ] && rm -f "$temp_settings"
}

# Function to migrate existing installation
migrate_existing_installation() {
    local old_statusline_path="$CLAUDE_DIR/statusline.sh"
    
    if [ -f "$old_statusline_path" ]; then
        print_status "🔄 Detected existing installation, migrating to new structure..."
        
        # Create backup
        local backup_path="${old_statusline_path}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$old_statusline_path" "$backup_path"
        print_status "Created backup: $backup_path"
        
        # Move to new location
        mv "$old_statusline_path" "$STATUSLINE_PATH"
        print_success "✅ Migrated statusline.sh to new location"
        
        # Update settings.json if it exists
        if [ -f "$SETTINGS_PATH" ]; then
            if jq -e '.statusLine.command' "$SETTINGS_PATH" >/dev/null 2>&1; then
                local temp_settings=$(mktemp)
                if jq --arg cmd "bash ~/.claude/statusline/statusline.sh" \
                   '.statusLine.command = $cmd' \
                   "$SETTINGS_PATH" > "$temp_settings"; then
                    mv "$temp_settings" "$SETTINGS_PATH"
                    print_success "Updated settings.json command path"
                else
                    rm -f "$temp_settings"
                    print_warning "Could not update settings.json automatically"
                fi
            fi
        fi
        
        return 0
    else
        print_status "No existing installation found"
        return 1
    fi
}

# Function to generate default Config.toml
generate_default_config() {
    print_status "Generating default Config.toml..."
    
    # Check if statusline script can generate config
    if [ -x "$STATUSLINE_PATH" ]; then
        local error_output
        if error_output=$("$STATUSLINE_PATH" --generate-config "$CONFIG_PATH" 2>&1); then
            print_success "✅ Generated Config.toml at: $CONFIG_PATH"
            print_status "💡 Edit $CONFIG_PATH to customize your statusline"
            return 0
        else
            print_warning "Could not generate Config.toml (statusline will use built-in defaults)"
            if [[ -n "$error_output" ]]; then
                print_warning "Error details: $error_output"
                case "$error_output" in
                    *"Permission denied"*) print_status "💡 Try: chmod +x $STATUSLINE_PATH" ;;
                    *"No such file"*) print_status "💡 Check that $CONFIG_PATH directory exists" ;;
                    *"Invalid"*) print_status "💡 Verify statusline script is not corrupted" ;;
                esac
            fi
            return 1
        fi
    else
        print_warning "Statusline script not executable, skipping Config.toml generation"
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
    
    # Check if all modules exist
    local modules=("core.sh" "security.sh" "config.sh" "themes.sh" "git.sh" "mcp.sh" "cost.sh" "display.sh" "cache.sh")
    local missing_modules=()
    
    for module in "${modules[@]}"; do
        if [ -f "$LIB_DIR/$module" ]; then
            print_status "✓ Module $module found"
        else
            print_error "✗ Module $module missing"
            missing_modules+=("$module")
        fi
    done
    
    if [[ ${#missing_modules[@]} -gt 0 ]]; then
        print_error "Missing modules: ${missing_modules[*]}"
        return 1
    else
        print_success "All modules installed successfully"
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
    echo "  • Config.toml       ← Your configuration file"
    echo
    echo -e "${BLUE}📁 Claude Code settings: ~/.claude/${NC}"
    echo "  • settings.json     ← Claude Code integration"
    echo
    echo -e "${BLUE}🎨 Customize your statusline:${NC}"
    echo "  edit ~/.claude/statusline/Config.toml"
    echo "  ~/.claude/statusline/statusline.sh --test-config"
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
    
    create_claude_directory
    migrate_existing_installation || true  # Don't fail if no existing installation
    download_statusline
    fix_bash_shebang
    make_executable
    configure_settings
    generate_default_config || true  # Don't fail if config generation fails
    
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