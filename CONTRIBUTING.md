# 🤝 Contributing to Claude Code Enhanced Statusline

**Assalamu'alaikum and Welcome!** 🌟

Thank you for your interest in contributing to the Claude Code Enhanced Statusline project! This project is built with love for the Claude Code community, and we warmly welcome contributors from all backgrounds and skill levels.

---

## 📋 Table of Contents

- [🌟 Ways to Contribute](#-ways-to-contribute)
- [🚀 Quick Start for Contributors](#-quick-start-for-contributors)
- [🛠️ Development Environment Setup](#️-development-environment-setup)
- [🔄 Development Workflow](#-development-workflow)
- [📝 Code Standards & Guidelines](#-code-standards--guidelines)
- [🧪 Testing Requirements](#-testing-requirements)
- [📦 Pull Request Process](#-pull-request-process)
- [🐛 Issue Guidelines](#-issue-guidelines)
- [🏗️ Project Structure Guide](#️-project-structure-guide)
- [🎨 Theme Contribution Guide](#-theme-contribution-guide)
- [📖 Documentation Contributions](#-documentation-contributions)
- [🚀 Release Process](#-release-process)
- [🌍 Community Guidelines](#-community-guidelines)
- [❓ Getting Help](#-getting-help)

---

## 🌟 Ways to Contribute

We welcome contributions in many forms! Choose what resonates with your skills and interests:

### 🐛 **Bug Reports & Issues**
- **Found a bug?** → [Report it here](https://github.com/rz1989s/claude-code-statusline/issues/new?template=bug_report.md)
- **System compatibility issues** → Help us support more platforms
- **Performance problems** → Share your performance observations
- **Configuration troubles** → Help us improve user experience

### 💡 **Feature Requests & Ideas**
- **Have a brilliant idea?** → [Suggest it here](https://github.com/rz1989s/claude-code-statusline/issues/new?template=feature_request.md)
- **Check our [TODOS.md](TODOS.md)** → Pick an item that interests you
- **Profile system** → High priority feature explicitly planned
- **Plugin system** → Help extend functionality
- **Performance improvements** → Optimization opportunities

### 🎨 **Theme Creation & Design**
- **Create beautiful themes** → Follow our theme system
- **Custom theme development** → Create new themes beyond classic/garden/catppuccin
- **Theme inheritance** → Planned future feature
- **Visual improvements** → Screenshots, icons, ASCII art

### 📖 **Documentation & Tutorials**
- **Improve existing docs** → Fix typos, clarify instructions
- **Create video tutorials** → Installation, configuration, customization
- **Write blog posts** → Share your statusline setup
- **API documentation** → Help document module interfaces

### 🔧 **Code Contributions**
- **Bug fixes** → Resolve reported issues
- **Feature implementation** → Build new functionality
- **Performance optimization** → Improve response times
- **Security improvements** → Enhance safety measures
- **CI/CD pipeline** → Critical infrastructure gap (no .github/workflows/)

### 🧪 **Testing & Quality Assurance**
- **Expand test coverage** → Currently 77 tests, always room for more
- **Cross-platform testing** → Test on different OS environments
- **Load testing** → High-frequency usage scenarios
- **Security testing** → Input validation, path traversal prevention

---

## 🚀 Quick Start for Contributors

### 1️⃣ **Choose Your Contribution Style**

**🔰 First-time contributor?**
- Start with documentation improvements or theme creation
- Look for issues labeled `good first issue` or `help wanted`
- Check [TODOS.md](TODOS.md) for beginner-friendly items

**⚡ Ready to code?**
- Focus on items in [TODOS.md](TODOS.md) marked as **High Priority**
- **Ocean theme integration** → Low complexity, high impact
- **Profile system** → Medium complexity, very high demand

**🧪 Testing enthusiast?**
- Expand test coverage in `tests/` directory
- Create performance benchmarks
- Test edge cases and error scenarios

### 2️⃣ **Read the Roadmap**
- Review [TODOS.md](TODOS.md) for comprehensive development roadmap
- Understand project priorities and planned features
- See implementation hints and complexity estimates

---

## 🛠️ Development Environment Setup

### 📋 **Prerequisites**

1. **Core Requirements**:
   ```bash
   # Essential tools
   bash --version    # 3.2+ minimum (auto-upgrades to modern bash), 5.0+ recommended for development
   jq --version      # 1.5+ required, 1.6+ recommended  
   git --version     # 2.0+ required, 2.30+ recommended
   ```
   
   **🎯 Universal Bash Compatibility**: The statusline includes runtime bash detection that automatically finds and uses modern bash when available, with graceful fallback for older versions.

2. **Testing Framework** (required for development):
   ```bash
   # macOS with Homebrew
   brew install bats-core shellcheck
   
   # Ubuntu/Debian
   sudo apt-get install bats shellcheck
   
   # Alternative: Install via npm
   npm install -g bats
   ```

3. **Optional but Recommended**:
   ```bash
   # For enhanced macOS compatibility
   brew install coreutils  # (macOS only)

   # Cost tracking is built-in (native JSONL) - no extra dependencies
   ```

### 🔧 **Project Setup**

1. **Fork and Clone**:
   ```bash
   # Fork the repository on GitHub first, then:
   git clone https://github.com/YOUR-USERNAME/claude-code-statusline.git
   cd claude-code-statusline
   
   # Add upstream remote
   git remote add upstream https://github.com/rz1989s/claude-code-statusline.git
   ```

2. **Install Dependencies**:
   ```bash
   # Install npm dependencies for testing
   npm install

   # Verify setup by running tests
   npm test
   ```

3. **Setup Pre-commit Hooks** (recommended):
   ```bash
   # Install pre-commit framework
   pip install pre-commit

   # Install hooks (runs shellcheck, validates TOML, etc.)
   pre-commit install

   # Test hooks manually
   pre-commit run --all-files
   ```

4. **Verify Installation**:
   ```bash
   # Test the statusline directly
   ./statusline.sh --help
   
   # Run development workflow
   npm run dev
   ```

### ✅ **Verification Checklist**
- [ ] All tests pass: `npm test`
- [ ] Linting passes: `npm run lint`
- [ ] Statusline runs: `./statusline.sh --help`
- [ ] Can generate config: `cp examples/Config.toml ./Config.toml test.toml`

---

## 🔄 Development Workflow

### 🌿 **Branching Strategy**

**Current Active Branches:**
- **`main`** - Stable production releases
- **`nightly`** - Experimental features for community testing
- **`dev`** - Stable development integration
- **`dev6`** - Current development: Enhanced settings.json management

```bash
# Start from the appropriate base branch
git checkout dev6          # For current development features
git pull upstream dev6

# Alternative: Start from stable dev for general contributions
git checkout dev           # For general development
git pull upstream dev

# Create a feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
# or
git checkout -b docs/documentation-improvement
```

**Branch Selection Guide:**
- **Contributing to settings.json features?** → Base on `dev6`
- **General bug fixes or features?** → Base on `dev`
- **Experimental features?** → Consider `nightly` branch
- **Documentation updates?** → Any branch, prefer `dev6` for current docs

### 🔄 **Development Cycle**

1. **Make Your Changes**:
   ```bash
   # Edit files as needed
   vim lib/themes.sh    # Example: adding Ocean theme
   
   # Test your changes frequently
   ./statusline.sh # Configuration is automatically loaded
   ```

2. **Run Tests & Validation**:
   ```bash
   # Clean environment and run full test suite
   npm run dev
   
   # Run specific test categories
   npm run test:unit          # Fast unit tests
   npm run test:integration   # End-to-end tests
   
   # Code quality checks
   npm run lint               # ShellCheck main script
   npm run lint:all           # Check everything
   ```

3. **Verify Your Changes**:
   ```bash
   # Test with different configurations
   ENV_CONFIG_THEME=garden ./statusline.sh
   ENV_CONFIG_THEME=catppuccin ./statusline.sh

   # Test configuration generation
   cp examples/Config.toml ./Config.toml
   ./statusline.sh --validate-config

   # For dev6 contributors: Test enhanced settings.json features
   # Test standard installation (modifies settings.json)
   ./install.sh --branch=dev6

   # Test preserve functionality (skips settings.json)
   ./install.sh --branch=dev6 --preserve-statusline

   # Verify backup creation
   ls ~/.claude/settings.json.backup.*
   ```

### 📝 **Commit Guidelines**

We follow conventional commit format for consistency:

```bash
# Format: type(scope): description
# 
# Types: feat, fix, docs, style, refactor, test, chore
# Scope: theme, config, mcp, cost, git, security, etc.

# Examples:
git commit -m "feat(themes): add ocean theme integration"
git commit -m "fix(config): resolve TOML parsing edge case"
git commit -m "docs: update installation guide with new dependencies"
git commit -m "test: add security validation test cases"
git commit -m "refactor(display): optimize output formatting performance"
```

**Commit Message Guidelines**:
- **First line**: 50 characters or less
- **Body**: Wrap at 72 characters, explain the "why"
- **Reference issues**: "Closes #123" or "Fixes #456"
- **Breaking changes**: Include "BREAKING CHANGE:" in footer

---

## 📝 Code Standards & Guidelines

### 🏗️ **Modular Architecture Principles**

Our codebase follows a clean modular architecture:

```
statusline.sh           # Main orchestrator (332 lines)
├── lib/core.sh        # Base utilities, module loading
├── lib/security.sh    # Input validation, sanitization
├── lib/config.sh      # TOML configuration management  
├── lib/themes.sh      # Color theme system
├── lib/git.sh         # Repository status, commits
├── lib/mcp.sh         # MCP server monitoring
├── lib/cost.sh        # Cost tracking integration
└── lib/display.sh     # Output formatting
```

### 📋 **Coding Standards**

1. **Shell Scripting Best Practices**:
   ```bash
   # Use strict mode
   set -euo pipefail
   
   # Quote variables
   echo "$variable" not $variable
   
   # Use local variables in functions
   local variable_name="value"
   
   # Handle errors gracefully
   command || handle_error "Command failed" 1 "function_name"
   ```

2. **Function Structure**:
   ```bash
   # Standard function template
   function_name() {
       local param1="$1"
       local param2="${2:-default_value}"
       
       # Validate inputs
       [[ -n "$param1" ]] || { 
           handle_error "Parameter required" 1 "function_name"
           return 1
       }
       
       # Implementation
       # ...
       
       return 0
   }
   ```

3. **Module Guidelines**:
   - Each module must be self-contained
   - Use `[[ "${MODULE_LOADED:-}" == "true" ]] && return 0` to prevent double-loading
   - Export `MODULE_LOADED=true` at the end
   - Follow existing function naming conventions

### 🎨 **Theme Development Standards**

When creating new themes:

```bash
# Theme function structure in lib/themes.sh
apply_THEME_NAME_theme() {
    # Set all required color variables
    export RED="\\033[31m"
    export BLUE="\\033[34m"
    # ... all basic colors
    
    # Extended colors
    export ORANGE="\\033[38;5;208m"
    # ... extended colors
    
    # Set theme name for display
    export CURRENT_THEME="theme-name"
}
```

### 🔐 **Security Guidelines**

- **Input validation**: Use `sanitize_path_secure()` for all paths
- **Command injection prevention**: Quote all variables, use arrays
- **Timeout protection**: All external commands must have timeouts
- **Error handling**: Never expose sensitive information in error messages

### 📊 **Performance Standards**

- **Caching**: Use intelligent caching for expensive operations
- **Timeouts**: All network operations must have configurable timeouts
- **Parallel execution**: Independent operations should run in parallel
- **Memory efficiency**: Avoid large temporary files

---

## 🧪 Testing Requirements

### 📋 **Test Coverage Expectations**

Our project maintains high test coverage standards:

- **Unit Tests**: 95%+ function coverage
- **Integration Tests**: All major user scenarios
- **Security Tests**: All input validation paths
- **Performance Tests**: Response time validation

### 🏃 **Running Tests**

```bash
# Complete test suite (77 tests)
npm test

# Specific test categories  
npm run test:unit          # Individual function tests
npm run test:integration   # End-to-end scenarios
bats tests/benchmarks/     # Performance tests

# Individual test files
bats tests/unit/test_git_functions.bats
bats tests/integration/test_toml_integration.bats
```

### ✍️ **Writing New Tests**

1. **Unit Test Template**:
   ```bash
   #!/usr/bin/env bats
   
   load '../setup_suite'
   load '../helpers/test_helpers'
   
   setup() {
       common_setup
       setup_mock_environment
   }
   
   teardown() {
       common_teardown
   }
   
   @test "function should handle normal input correctly" {
       # Arrange
       local input="test input"
       
       # Act
       run my_function "$input"
       
       # Assert
       assert_success
       assert_output_contains "expected output"
   }
   ```

2. **Integration Test Template**:
   ```bash
   @test "full statusline with ocean theme configuration" {
       # Setup ocean theme config
       create_test_config_file "ocean"
       
       # Run statusline with test input
       echo "$TEST_INPUT_JSON" | run ./statusline.sh
       
       # Validate output structure
       assert_success
       validate_statusline_format "$output"
       assert_output_contains "ocean colors"
   }
   ```

### 🛠️ **Test Utilities Available**

```bash
# Mock functions (in helpers/test_helpers.bash)
setup_mock_git_repo()              # Create mock git repository
setup_mock_ccusage()               # Mock ccusage commands  
setup_mock_mcp()                   # Mock MCP server responses
create_mock_command()              # Mock any command
validate_statusline_format()       # Validate 4-line output
strip_ansi_codes()                 # Remove colors for testing
```

### ✅ **Test Requirements for PRs**

Before submitting a pull request:

- [ ] All existing tests pass: `npm test`
- [ ] New functionality has corresponding tests
- [ ] Test coverage remains above 90%
- [ ] Performance tests pass (if applicable)
- [ ] Security tests pass for new input handling

---

## 📦 Pull Request Process

### 🎯 **Before You Submit**

1. **Complete the Development Checklist**:
   - [ ] Code follows project standards
   - [ ] All tests pass: `npm test`
   - [ ] Linting passes: `npm run lint:all`
   - [ ] Documentation updated (if needed)
   - [ ] [TODOS.md](TODOS.md) updated (if implementing a TODO item)

2. **Test Your Changes Thoroughly**:
   ```bash
   # Test with different configurations
   ./statusline.sh # Configuration is automatically loaded
   ENV_CONFIG_THEME=garden ./statusline.sh
   ENV_CONFIG_THEME=catppuccin ./statusline.sh
   
   # Test edge cases
   ./statusline.sh --help
   cp examples/Config.toml ./Config.toml
   ```

### 📋 **PR Submission Guidelines**

1. **PR Title Format**:
   ```
   feat(themes): add ocean theme integration
   fix(config): resolve TOML parsing edge case
   docs: update contributing guidelines
   ```

2. **PR Description Template**:
   ```markdown
   ## 📋 Summary
   Brief description of changes and motivation.
   
   ## 🔄 Changes Made
   - [ ] Added ocean theme integration
   - [ ] Updated lib/themes.sh with ocean colors
   - [ ] Added ocean theme tests
   - [ ] Updated documentation
   
   ## 🧪 Testing
   - [ ] All existing tests pass
   - [ ] Added new tests for ocean theme
   - [ ] Tested with multiple configurations
   - [ ] Manual testing completed
   
   ## 📖 Documentation  
   - [ ] Updated relevant documentation
   - [ ] Added theme examples
   - [ ] Updated TODOS.md (if applicable)
   
   ## 🔗 Related Issues
   Closes #123
   Related to #456
   
   ## 📸 Screenshots (if applicable)
   [Add screenshots of visual changes]
   ```

3. **PR Size Guidelines**:
   - **Small PRs preferred** → Easier to review, faster to merge
   - **One feature per PR** → Focused changes, clear purpose
   - **Documentation updates** → Can be combined with related code changes

### 🔍 **Review Process**

1. **Automated Checks**:
   - All tests must pass
   - Linting must pass
   - No security vulnerabilities detected

2. **Human Review**:
   - Code quality and style consistency
   - Adherence to architectural principles
   - Test coverage and quality
   - Documentation completeness

3. **Merge Requirements**:
   - At least one maintainer approval
   - All CI checks passing
   - Conflicts resolved
   - Up-to-date with target branch

---

## 🐛 Issue Guidelines

### 🐛 **Bug Reports**

**Use the bug report template** and include:

1. **Environment Information**:
   ```bash
   # Run this diagnostic command
   ./statusline.sh --help
   bash --version
   jq --version
   uname -a
   ```

2. **Reproduction Steps**:
   - Clear, step-by-step instructions
   - Minimal test case if possible
   - Expected vs. actual behavior

3. **Configuration Details**:
   ```bash
   # Include your Config.toml (remove sensitive data)
   cat Config.toml
   
   # Or show relevant environment overrides
   ENV_CONFIG_THEME=garden ./statusline.sh
   ```

### 💡 **Feature Requests**

**Use the feature request template** and include:

1. **Problem Statement**: What problem does this solve?
2. **Proposed Solution**: How should it work?
3. **Alternative Solutions**: What other approaches did you consider?
4. **Use Cases**: Who would benefit from this feature?
5. **Implementation Ideas**: Any technical suggestions?

### 🏷️ **Issue Labels**

We use these labels to organize issues:

- `bug` → Something isn't working
- `enhancement` → New feature or improvement
- `documentation` → Documentation related
- `good first issue` → Great for newcomers
- `help wanted` → Community help needed
- `priority: high` → Critical issues
- `theme` → Theme-related changes
- `config` → Configuration system changes
- `security` → Security-related issues
- `performance` → Performance improvements

---

## 🏗️ Project Structure Guide

### 📁 **Directory Overview**

```
claude-code-statusline/
├── statusline.sh              # Main orchestrator script (332 lines)
├── lib/                       # Modular components (8 modules)
│   ├── core.sh               # Base utilities, module loading
│   ├── security.sh           # Input sanitization, validation
│   ├── config.sh             # TOML configuration parsing
│   ├── themes.sh             # Color theme management
│   ├── git.sh                # Repository status, commits
│   ├── mcp.sh                # MCP server monitoring
│   ├── cost.sh               # Cost tracking integration
│   └── display.sh            # Output formatting
├── tests/                     # Comprehensive test suite (77 tests)
│   ├── unit/                 # Individual function tests
│   ├── integration/          # End-to-end scenarios
│   ├── benchmarks/           # Performance tests
│   ├── fixtures/             # Mock data and outputs
│   └── helpers/              # Test utilities
├── docs/                      # Documentation
├── examples/                  # Sample configurations
│   └── sample-configs/       # Theme examples (Ocean ready!)
├── Config.toml               # Configuration file
├── version.txt               # Centralized version management
├── TODOS.md                  # Development roadmap
└── install.sh                # Automated installer
```

### 🔄 **Module Loading System**

Understanding how modules work:

1. **Core Module** (`lib/core.sh`):
   - Loaded first by `statusline.sh`
   - Provides `load_module()` function
   - Contains shared utilities and constants

2. **Module Dependencies**:
   ```
   core.sh → (required first)
   security.sh → (required by most modules)
   config.sh → themes.sh, git.sh, mcp.sh, cost.sh
   themes.sh → display.sh  
   git.sh, mcp.sh, cost.sh → display.sh
   display.sh → (loaded last)
   ```

3. **Adding New Modules**:
   ```bash
   # Create new module: lib/mymodule.sh
   #!/bin/bash
   [[ "${MYMODULE_LOADED:-}" == "true" ]] && return 0
   
   # Your module code here
   
   export MYMODULE_LOADED=true
   
   # Load in statusline.sh:
   load_module "mymodule" || exit 1
   ```

### 🎨 **Theme System Architecture**

```bash
# Theme system in lib/themes.sh
apply_theme() {
    case "${CONFIG_THEME:-classic}" in
        "classic")   apply_classic_theme ;;
        "garden")    apply_garden_theme ;;
        "catppuccin") apply_catppuccin_theme ;;
        "ocean")     apply_ocean_theme ;;    # Ready to implement!
        "custom")    apply_custom_theme ;;
        *)           apply_classic_theme ;;
    esac
}
```

---

## 🎨 Theme Contribution Guide

### 🌊 **High Priority: Ocean Theme Integration**

The Ocean theme is **ready to implement** - it exists in `examples/sample-configs/ocean-theme.toml` but needs integration:

1. **Implementation Steps**:
   ```bash
   # Add to lib/themes.sh
   apply_ocean_theme() {
       # Copy colors from examples/sample-configs/ocean-theme.toml
       export BLUE="\\033[38;2;0;119;190m"     # Deep ocean blue
       export TEAL="\\033[38;2;0;150;136m"     # Teal depths
       # ... etc
   }
   
   # Update apply_theme() case statement
   "ocean") apply_ocean_theme ;;
   ```

2. **Testing Requirements**:
   ```bash
   # Test ocean theme
   ENV_CONFIG_THEME=ocean ./statusline.sh
   
   # Add ocean theme test
   bats tests/integration/test_ocean_theme.bats
   ```

### 🎨 **Creating Custom Themes**

1. **Design Principles**:
   - **Readability**: Ensure good contrast in terminals
   - **Consistency**: Use a coherent color palette
   - **Accessibility**: Consider color-blind users
   - **Terminal compatibility**: Test in different terminal emulators

2. **Theme Structure**:
   ```bash
   apply_THEME_NAME_theme() {
       # Basic ANSI colors (required)
       export RED="\\033[31m"
       export GREEN="\\033[32m"
       export YELLOW="\\033[33m"
       export BLUE="\\033[34m"
       export MAGENTA="\\033[35m"
       export CYAN="\\033[36m"
       export WHITE="\\033[37m"
       
       # Extended colors (optional but recommended)
       export ORANGE="\\033[38;5;208m"
       export PURPLE="\\033[95m"
       export LIGHT_GRAY="\\033[38;5;248m"
       export BRIGHT_GREEN="\\033[92m"
       
       # Formatting (required)
       export DIM="\\033[2m"
       export RESET="\\033[0m"
       
       # Theme identification
       export CURRENT_THEME="theme-name"
   }
   ```

3. **Testing Your Theme**:
   ```bash
   # Quick test
   ENV_CONFIG_THEME=your_theme ./statusline.sh
   
   # Generate config with your theme
   cp examples/Config.toml ./Config.toml
   # Edit Config.toml to set theme.name = "your_theme"
   ./statusline.sh # Configuration is automatically loaded
   ```

### 📸 **Theme Documentation Requirements**

When contributing themes:
- Add theme to examples/sample-configs/
- Include screenshots in assets/screenshots/
- Update README.md theme gallery
- Add theme tests
- Document color meanings and inspiration

---

## 📖 Documentation Contributions

### 📋 **Documentation Standards**

1. **Style Guide**:
   - Use **emoji sections** for visual organization 🎯
   - **Code blocks** with syntax highlighting
   - **Clear examples** with expected outputs
   - **Cross-references** between related sections

2. **Structure Requirements**:
   - Table of contents for long documents
   - Step-by-step instructions where applicable
   - Troubleshooting sections
   - Links to related documentation

### 🎯 **High-Priority Documentation Needs**

1. **Performance Tuning Guide** → [TODOS.md](TODOS.md)
2. **API Documentation** → Module interface documentation
3. **Plugin Development Guide** → For future plugin system
4. **Video Tutorial Series** → Installation, configuration, themes
5. **Best Practices Guide** → Configuration recommendations

### 📝 **Documentation Workflow**

1. **Update Related Files**:
   - README.md → For user-facing changes
   - CLAUDE.md → For development-related changes
   - docs/ → For detailed guides
   - TODOS.md → Remove completed items

2. **Validation**:
   ```bash
   # Test all code examples in documentation
   # Validate all links work
   # Check spelling and grammar
   # Ensure screenshots are current
   ```

---

## 🚀 Release Process

### 📋 **Version Management**

We use **centralized version management** with `version.txt`:

```bash
# Current version
cat version.txt        # Example: 1.5.2

# Version sync commands  
./statusline.sh --version-sync       # Sync package.json with version.txt
./statusline.sh --version-check      # Verify consistency
```

### 🔄 **Release Workflow**

1. **Pre-release Checklist**:
   - [ ] All tests passing: `npm test`
   - [ ] Documentation updated
   - [ ] [TODOS.md](TODOS.md) updated with completed items
   - [ ] Version bumped appropriately
   - [ ] Changelog draft prepared

2. **Version Bump Guidelines**:
   - **Major (X.0.0)**: Breaking changes, API removal
   - **Minor (0.X.0)**: New features, backward-compatible
   - **Patch (0.0.X)**: Bug fixes, small improvements

3. **Release Process** *(For Maintainers)*:
   ```bash
   # Update version.txt
   echo "1.6.0" > version.txt
   
   # Sync package.json
   ./statusline.sh --version-sync
   
   # Create release commit
   git commit -am "release: v1.6.0"
   git tag v1.6.0
   git push origin dev --tags
   ```

### 📋 **Release Notes Format**

```markdown
## v1.6.0 - Ocean Theme Integration 🌊

### ✨ New Features
- Added Ocean theme as built-in option
- Profile system implementation
- Enhanced theme inheritance

### 🐛 Bug Fixes  
- Fixed TOML parsing edge case
- Resolved timeout validation issue

### 📖 Documentation
- Updated theme gallery
- Added contributing guidelines
- Enhanced installation guide

### 🏗️ Internal Improvements
- Improved test coverage to 82%
- Enhanced CI/CD pipeline
- Code quality improvements
```

---

## 🌍 Community Guidelines

### 🤲 **Our Values**

This project is built with Islamic values and community spirit:

- **Respect**: Treat all contributors with dignity and kindness
- **Patience (Sabr)**: Be patient with newcomers and different skill levels
- **Gratitude (Shukr)**: Appreciate all contributions, big and small
- **Excellence (Ihsan)**: Strive for quality in all work
- **Cooperation (Ta'awun)**: Work together for the benefit of the community

### 🗣️ **Communication Guidelines**

1. **Be Welcoming**:
   - Use inclusive language
   - Welcome newcomers warmly
   - Share knowledge generously
   - Celebrate contributions

2. **Be Respectful**:
   - Disagree respectfully about code, not people  
   - Assume good intentions
   - Give constructive feedback
   - Be open to learning

3. **Be Helpful**:
   - Answer questions when you can
   - Point to relevant documentation
   - Share useful resources
   - Mentor newcomers

### 🚫 **Unacceptable Behavior**

- Harassment, discrimination, or offensive language
- Personal attacks or trolling
- Spam or off-topic discussions  
- Sharing others' private information
- Any behavior that creates a hostile environment

### 📞 **Reporting Issues**

If you experience or witness unacceptable behavior:
- Contact maintainers directly
- Use GitHub's reporting features
- GitHub: [https://github.com/rz1989s](https://github.com/rz1989s)

---

## ❓ Getting Help

### 🆘 **Where to Get Help**

1. **Documentation First**:
   - [README.md](README.md) → Installation and basic usage
   - [CLAUDE.md](CLAUDE.md) → Development guidelines  
   - [TODOS.md](TODOS.md) → Implementation roadmap
   - docs/ → Detailed guides

2. **Community Support**:
   - [GitHub Issues](https://github.com/rz1989s/claude-code-statusline/issues) → Bug reports and questions
   - [GitHub Discussions](https://github.com/rz1989s/claude-code-statusline/discussions) → General discussion
   - Pull Request comments → Code-specific questions

3. **Development Help**:
   - Check existing tests for examples
   - Look at similar implementations in the codebase
   - Review [Project Structure Guide](#️-project-structure-guide)

### 🤔 **Common Questions**

**Q: I'm new to shell scripting. Can I still contribute?**  
A: Absolutely! Start with documentation, themes, or testing. Everyone's contributions are valuable.

**Q: How do I test my changes without affecting my system?**  
A: Use the test environment and temporary configurations: `./statusline.sh # Configuration is automatically loaded test.toml`

**Q: What if I break something?**  
A: Don't worry! That's what tests are for. Run `npm test` to catch issues early, and the community will help fix any problems.

**Q: Can I implement multiple TODO items in one PR?**  
A: It's better to focus on one feature per PR for easier review. Exception: closely related items can be grouped.

---

## 🌟 Thank You!

**Jazakallahu khairan** for your interest in contributing! Your efforts help make this project better for the entire Claude Code community.

Whether you're fixing a typo, implementing a major feature, or helping other contributors, your work matters. Every contribution, no matter how small, makes a difference.

**Barakallahu feek** and happy coding! 🚀

---

**Made with ❤️ for the Claude Code community**