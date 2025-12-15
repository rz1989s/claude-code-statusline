# Homebrew formula for Claude Code Enhanced Statusline
# To use: brew tap rz1989s/tap && brew install claude-code-statusline
#
# For tap setup, create repo: https://github.com/rz1989s/homebrew-tap
# and copy this file to Formula/claude-code-statusline.rb

class ClaudeCodeStatusline < Formula
  desc "Enhanced statusline for Claude Code with themes, cost tracking, and prayer times"
  homepage "https://github.com/rz1989s/claude-code-statusline"
  url "https://github.com/rz1989s/claude-code-statusline/archive/refs/tags/v2.11.6.tar.gz"
  sha256 "PLACEHOLDER_SHA256"  # Update with: shasum -a 256 v2.11.6.tar.gz
  license "MIT"
  head "https://github.com/rz1989s/claude-code-statusline.git", branch: "main"

  depends_on "jq"
  depends_on "coreutils" if OS.mac?  # For gtimeout

  def install
    # Install all files to libexec
    libexec.install Dir["*"]

    # Create wrapper script in bin
    (bin/"claude-statusline").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/statusline.sh" "$@"
    EOS

    # Install config template
    (share/"claude-code-statusline").install "Config.toml"
  end

  def post_install
    # Create user config directory
    config_dir = Pathname.new(Dir.home)/".claude/statusline"
    config_dir.mkpath unless config_dir.exist?

    # Copy default config if not exists
    user_config = config_dir/"Config.toml"
    unless user_config.exist?
      cp share/"claude-code-statusline/Config.toml", user_config
      ohai "Created default config at #{user_config}"
    end

    # Copy version file
    version_file = config_dir/"version.txt"
    (libexec/"version.txt").cp(version_file) if (libexec/"version.txt").exist?
  end

  def caveats
    <<~EOS
      To complete setup, add to your Claude Code settings.json:

        "env": {
          "CLAUDE_CODE_STATUSLINE": "~/.claude/statusline/statusline.sh"
        }

      Or run the full installer for automatic setup:
        curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

      Configuration file: ~/.claude/statusline/Config.toml
      Documentation: https://github.com/rz1989s/claude-code-statusline
    EOS
  end

  test do
    # Basic test - check help output
    assert_match "Claude Code Enhanced Statusline", shell_output("#{bin}/claude-statusline --help 2>&1", 0)
  end
end
