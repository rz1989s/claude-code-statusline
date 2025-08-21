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

# Script configuration
REPO_URL="https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
STATUSLINE_DIR="$CLAUDE_DIR/statusline"
STATUSLINE_PATH="$STATUSLINE_DIR/statusline.sh"
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

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
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
    
    print_success "All dependencies are available"
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

# Function to download statusline script
download_statusline() {
    print_status "Downloading statusline.sh from repository..."
    
    if curl -fsSL "$REPO_URL" -o "$STATUSLINE_PATH"; then
        print_success "Downloaded statusline.sh to $STATUSLINE_PATH"
    else
        print_error "Failed to download statusline.sh"
        exit 1
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

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if statusline.sh exists and is executable
    if [ -x "$STATUSLINE_PATH" ]; then
        print_success "statusline.sh is installed and executable"
    else
        print_error "statusline.sh is not properly installed or not executable"
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

# Function to create statusline directory
create_statusline_directory() {
    if [ ! -d "$STATUSLINE_DIR" ]; then
        print_status "Creating statusline directory: $STATUSLINE_DIR"
        mkdir -p "$STATUSLINE_DIR"
        print_success "Created directory: $STATUSLINE_DIR"
    else
        print_status "Statusline directory already exists: $STATUSLINE_DIR"
    fi
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
        if "$STATUSLINE_PATH" --generate-config "$CONFIG_PATH" >/dev/null 2>&1; then
            print_success "✅ Generated Config.toml at: $CONFIG_PATH"
            print_status "💡 Edit $CONFIG_PATH to customize your statusline"
            return 0
        else
            print_warning "Could not generate Config.toml (statusline will use built-in defaults)"
            return 1
        fi
    else
        print_warning "Statusline script not executable, skipping Config.toml generation"
        return 1
    fi
}

# Function to show completion message
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
    echo -e "${BLUE}Claude Code Enhanced Statusline - Automated Installer${NC}"
    echo "=================================================="
    echo
    
    check_dependencies
    create_claude_directory
    create_statusline_directory
    migrate_existing_installation || true  # Don't fail if no existing installation
    download_statusline
    make_executable
    configure_settings
    generate_default_config || true  # Don't fail if config generation fails
    
    echo
    if verify_installation; then
        show_completion
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Handle script interruption
trap 'echo; print_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"