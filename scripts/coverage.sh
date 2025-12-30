#!/bin/bash
# ============================================================================
# Test Coverage Script for Claude Code Statusline
# ============================================================================
# Uses kcov to generate coverage reports for bash scripts.
#
# Usage:
#   ./scripts/coverage.sh          # Run coverage and show summary
#   ./scripts/coverage.sh --html   # Generate HTML report
#
# Requirements:
#   - kcov (brew install kcov / apt install kcov)
#   - bats (already installed via npm)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COVERAGE_DIR="$PROJECT_ROOT/coverage"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check if kcov is installed
check_kcov() {
  if ! command -v kcov &>/dev/null; then
    print_error "kcov is not installed"
    echo ""
    echo "Install kcov:"
    echo "  macOS:  brew install kcov"
    echo "  Ubuntu: apt install kcov"
    echo "  Arch:   pacman -S kcov"
    echo ""
    exit 1
  fi
  print_success "kcov found: $(kcov --version 2>&1 | head -1)"
}

# Check if bats is installed
check_bats() {
  if ! command -v bats &>/dev/null; then
    print_error "bats is not installed"
    echo "Run: npm install"
    exit 1
  fi
  print_success "bats found: $(bats --version)"
}

# Clean previous coverage data
clean_coverage() {
  if [[ -d "$COVERAGE_DIR" ]]; then
    rm -rf "$COVERAGE_DIR"
    print_info "Cleaned previous coverage data"
  fi
  mkdir -p "$COVERAGE_DIR"
}

# Run tests with coverage
run_coverage() {
  local test_type="${1:-unit}"
  local test_path="$PROJECT_ROOT/tests/${test_type}"

  if [[ ! -d "$test_path" ]]; then
    print_error "Test directory not found: $test_path"
    return 1
  fi

  print_info "Running $test_type tests with coverage..."

  # Run kcov with bats
  # --include-path: Only track coverage for lib/ directory
  # --exclude-pattern: Exclude test files and external dependencies
  kcov \
    --include-path="$PROJECT_ROOT/lib" \
    --exclude-pattern=".bats,.bash,/tests/,/node_modules/" \
    "$COVERAGE_DIR/$test_type" \
    bats "$test_path"/*.bats 2>/dev/null || true
}

# Merge coverage from multiple test runs
merge_coverage() {
  print_info "Merging coverage reports..."

  # kcov automatically merges when outputting to same directory
  kcov --merge "$COVERAGE_DIR/merged" "$COVERAGE_DIR"/*/

  print_success "Coverage merged to $COVERAGE_DIR/merged"
}

# Print coverage summary
print_summary() {
  local merged_dir="$COVERAGE_DIR/merged"

  if [[ ! -d "$merged_dir" ]]; then
    merged_dir="$COVERAGE_DIR/unit"
  fi

  if [[ ! -f "$merged_dir/coverage.json" ]]; then
    print_warning "No coverage data found"
    return
  fi

  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "                    COVERAGE SUMMARY"
  echo "════════════════════════════════════════════════════════════"

  # Parse coverage.json for summary
  if command -v jq &>/dev/null; then
    local total_lines covered_lines percent
    total_lines=$(jq -r '.total_lines // 0' "$merged_dir/coverage.json" 2>/dev/null || echo "0")
    covered_lines=$(jq -r '.covered_lines // 0' "$merged_dir/coverage.json" 2>/dev/null || echo "0")
    percent=$(jq -r '.percent_covered // "0"' "$merged_dir/coverage.json" 2>/dev/null || echo "0")

    echo "Total Lines:   $total_lines"
    echo "Covered Lines: $covered_lines"
    echo "Coverage:      ${percent}%"

    # Color-coded result
    if (( $(echo "$percent >= 70" | bc -l 2>/dev/null || echo 0) )); then
      print_success "Target coverage (70%) achieved!"
    elif (( $(echo "$percent >= 50" | bc -l 2>/dev/null || echo 0) )); then
      print_warning "Coverage below target (70%)"
    else
      print_error "Coverage needs improvement"
    fi
  else
    print_warning "Install jq for detailed coverage summary"
    echo "Report available at: $merged_dir/index.html"
  fi

  echo "════════════════════════════════════════════════════════════"
}

# Open HTML report
open_html_report() {
  local report="$COVERAGE_DIR/merged/index.html"

  if [[ ! -f "$report" ]]; then
    report="$COVERAGE_DIR/unit/index.html"
  fi

  if [[ ! -f "$report" ]]; then
    print_error "No HTML report found"
    return 1
  fi

  print_success "Opening coverage report..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$report"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$report"
  else
    echo "Report: $report"
  fi
}

# Main
main() {
  local html_mode=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --html|-h)
        html_mode=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║        Claude Code Statusline - Test Coverage              ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""

  # Pre-flight checks
  check_kcov
  check_bats

  # Clean and run
  clean_coverage
  run_coverage "unit"

  # Show summary
  print_summary

  # Open HTML if requested
  if [[ "$html_mode" == true ]]; then
    open_html_report
  else
    echo ""
    print_info "Run 'npm run test:coverage:html' to open HTML report"
  fi
}

main "$@"
