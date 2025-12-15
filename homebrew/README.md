# Homebrew Installation

## Quick Install (Once Tap is Set Up)

```bash
brew tap rz1989s/tap
brew install claude-code-statusline
```

## Setting Up the Tap

1. Create a new repository: `https://github.com/rz1989s/homebrew-tap`

2. Copy the formula to the tap:
   ```bash
   mkdir -p Formula
   cp claude-code-statusline.rb Formula/
   ```

3. Update the SHA256 hash when creating a release:
   ```bash
   # Download the release tarball
   curl -sL https://github.com/rz1989s/claude-code-statusline/archive/refs/tags/v2.11.6.tar.gz -o v2.11.6.tar.gz

   # Calculate SHA256
   shasum -a 256 v2.11.6.tar.gz

   # Update the formula with the hash
   ```

## Updating the Formula

When releasing a new version:

1. Update version in formula URL
2. Calculate new SHA256 from release tarball
3. Update sha256 in formula
4. Push to tap repository

## Testing Locally

```bash
# Install from local formula
brew install --build-from-source ./claude-code-statusline.rb

# Test the installation
claude-statusline --help

# Uninstall
brew uninstall claude-code-statusline
```

## Alternative: Direct Install

The curl-based installer is still recommended for full setup:

```bash
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash
```
