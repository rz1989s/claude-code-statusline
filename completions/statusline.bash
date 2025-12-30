#!/bin/bash
# ============================================================================
# Bash Completion for Claude Code Statusline
# ============================================================================
#
# Installation:
#   Add to ~/.bashrc or ~/.bash_profile:
#   source ~/.claude/statusline/completions/statusline.bash
#
# Or copy to system completions:
#   sudo cp statusline.bash /etc/bash_completion.d/statusline
# ============================================================================

_statusline_completions() {
  local cur prev opts themes formats
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Main options
  opts="--help --version --modules --test-display --health --health=json --health-json --metrics --metrics=json --metrics=prometheus --metrics=prom --list-themes --preview-theme --check-updates --setup-wizard"

  # Available themes
  themes="classic garden catppuccin ocean custom"

  # Metrics formats
  formats="json prometheus prom"

  # Health formats
  health_formats="json"

  # Handle option arguments
  case "$prev" in
    --health)
      COMPREPLY=($(compgen -W "json" -- "$cur"))
      return 0
      ;;
    --metrics)
      COMPREPLY=($(compgen -W "$formats" -- "$cur"))
      return 0
      ;;
    --preview-theme)
      COMPREPLY=($(compgen -W "$themes" -- "$cur"))
      return 0
      ;;
  esac

  # Handle = style options
  case "$cur" in
    --health=*)
      local prefix="${cur%=*}="
      local suffix="${cur#*=}"
      COMPREPLY=($(compgen -W "json" -P "$prefix" -- "$suffix"))
      return 0
      ;;
    --metrics=*)
      local prefix="${cur%=*}="
      local suffix="${cur#*=}"
      COMPREPLY=($(compgen -W "$formats" -P "$prefix" -- "$suffix"))
      return 0
      ;;
    --preview-theme=*)
      local prefix="${cur%=*}="
      local suffix="${cur#*=}"
      COMPREPLY=($(compgen -W "$themes" -P "$prefix" -- "$suffix"))
      return 0
      ;;
  esac

  # Complete options
  if [[ "$cur" == -* ]]; then
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    return 0
  fi

  # Default: no completion
  return 0
}

# Register completion for statusline.sh and common aliases
complete -F _statusline_completions statusline.sh
complete -F _statusline_completions statusline
complete -F _statusline_completions ./statusline.sh

# Environment variable completion for themes
_statusline_env_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "$cur" == ENV_CONFIG_THEME=* ]]; then
    local prefix="ENV_CONFIG_THEME="
    local suffix="${cur#*=}"
    COMPREPLY=($(compgen -W "classic garden catppuccin custom" -P "$prefix" -- "$suffix"))
  fi
}
