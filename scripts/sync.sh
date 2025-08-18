#!/bin/bash

# Sync script to update public repository with latest changes from dotfiles
# This script copies the statusline-enhanced.sh from your private dotfiles
# to this public repository for sharing with the community.

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Syncing statusline script from dotfiles...${NC}"

# Source and destination paths
SOURCE_PATH="$HOME/dotfiles/claude/.claude/statusline-enhanced.sh"
DEST_PATH="$HOME/local-dev/claude-code-statusline/statusline-enhanced.sh"

# Check if source file exists
if [ ! -f "$SOURCE_PATH" ]; then
    echo -e "${RED}❌ Error: Source file not found at $SOURCE_PATH${NC}"
    exit 1
fi

# Create backup of current public version
if [ -f "$DEST_PATH" ]; then
    BACKUP_PATH="${DEST_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DEST_PATH" "$BACKUP_PATH"
    echo -e "${BLUE}📋 Created backup: $(basename $BACKUP_PATH)${NC}"
fi

# Copy the updated script
cp "$SOURCE_PATH" "$DEST_PATH"

# Verify the copy
if [ -f "$DEST_PATH" ]; then
    echo -e "${GREEN}✅ Successfully synced statusline script!${NC}"
    
    # Show file info
    echo -e "${BLUE}📊 File details:${NC}"
    ls -lh "$DEST_PATH"
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review the changes: git diff"
    echo "2. Commit changes: git add . && git commit -m 'Update statusline script'"
    echo "3. Push to GitHub: git push origin main"
else
    echo -e "${RED}❌ Error: Failed to copy script${NC}"
    exit 1
fi