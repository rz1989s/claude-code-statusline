# 📋 TODOS.md

**Claude Code Enhanced Statusline - Development Roadmap**

This document outlines planned features, improvements, and maintenance tasks for the claude-code-statusline project. Items are organized by priority and category to guide development efforts effectively.

---

## ✅ **COMPLETED IN v2.0.6** 
*Major architectural achievements and core functionality*

### 🏗️ **Core Architecture** `[COMPLETED]`

1. **Modular System Architecture** ✅
   - **Status**: COMPLETED - 91.5% code reduction from monolithic v1 (3930 lines → 332 lines main + 9 modules)
   - **Implementation**: Complete module loading system with dependency management
   - **Modules**: core.sh, security.sh, cache.sh, config.sh, themes.sh, git.sh, mcp.sh, cost.sh, display.sh
   - **Features**: Include guards, error handling, performance timing

2. **TOML Configuration System** ✅
   - **Status**: COMPLETED - Full flat TOML parsing with dot notation  
   - **Implementation**: Multi-level configuration discovery (env → project → user → XDG → defaults)
   - **Features**: Environment variable overrides (ENV_CONFIG_*), validation, error reporting

3. **Theme System** ✅
   - **Status**: COMPLETED - 3 built-in themes + custom theme support
   - **Implementation**: Classic, Garden, Catppuccin themes with color management
   - **Features**: Theme application via apply_theme(), custom colors via TOML

4. **Git Integration** ✅
   - **Status**: COMPLETED - Full repository status tracking
   - **Implementation**: Branch detection, status checking, commit counting, submodule support
   - **Features**: Repository validation, performance optimized

5. **MCP Monitoring** ✅
   - **Status**: COMPLETED - MCP server health monitoring
   - **Implementation**: Server status detection, health checking, timeout handling
   - **Features**: Real-time status updates, graceful failure handling

6. **Cost Tracking** ✅
   - **Status**: COMPLETED - ccusage integration for cost monitoring  
   - **Implementation**: Session, monthly, weekly, daily cost tracking with live updates
   - **Features**: Block info, reset timing, cost history

7. **Intelligent Caching System** ✅
   - **Status**: COMPLETED - Universal caching with TTL support
   - **Implementation**: Command result caching, cache validation, performance optimization
   - **Features**: Configurable TTLs, automatic cleanup, fallback handling

8. **Security & Input Validation** ✅
   - **Status**: COMPLETED - Comprehensive security hardening
   - **Implementation**: Input sanitization, path validation, secure external command handling
   - **Features**: Timeout protection, safe file operations

### 🎯 **User Interface & Experience** `[COMPLETED]`

9. **Command-line Interface** ✅
   - **Status**: COMPLETED - Full CLI with help, version, testing options
   - **Implementation**: --help, --version, --test-display, --modules commands
   - **Features**: Usage documentation, module status reporting

10. **4-Line Statusline Display** ✅
    - **Status**: COMPLETED - Comprehensive information display
    - **Implementation**: Git info, cost tracking, MCP status, reset info with color formatting
    - **Features**: Modular formatting, theme support, error graceful handling

---

## 🔥 **High Priority** 
*Core features and critical improvements*

### 🚀 **New Feature Requests** *(GitHub Issues)*

**NEW:** **Modular Statusline Layout Configuration** `[ISSUE #28]`
  - **Status**: Feature request created - allow users to customize order of 4 statusline components
  - **Description**: Enable TOML configuration for line ordering (e.g., `line_order = ["mcp", "reset", "git", "cost"]`)
  - **Implementation**: Leverage existing modular display.sh architecture to reorder components
  - **Impact**: High - Major UX customization improvement for different workflows  
  - **Complexity**: Medium
  - **Dependencies**: Current display module system

**NEW:** **Real-time Cost Burn Rate ($/min)** `[ISSUE #29]`
  - **Status**: Feature request created - show cost accumulation rate for active sessions
  - **Description**: Calculate and display `LIVE_COST / SESSION_ELAPSED_TIME` as $/min rate
  - **Implementation**: Extend lib/cost.sh with rate calculation and compact display format
  - **Impact**: High - Critical budget awareness for cost-conscious users
  - **Complexity**: Medium  
  - **Dependencies**: Existing ccusage integration, reset time data

### 🎯 **Planned Features** *(Already Mentioned in Codebase)*

1. **Profile System** `[PLANNED]`
  - **Status**: Mentioned in README.md as "planned for a future release"
  - **Description**: Automatic configuration switching based on context (work/personal/demo)
  - **Implementation**: 
    - Add profile detection logic to `lib/config.sh`
    - Support git-based, directory-based, and time-based profile switching
    - Example: `work-profile.toml`, `personal-profile.toml` in examples/ are ready
  - **Impact**: High - Major UX improvement for users with multiple contexts
  - **Complexity**: Medium
  - **Dependencies**: Current TOML system

2. **Theme Inheritance System** `[PLANNED]`
  - **Status**: Mentioned in docs/themes.md as "Future Feature"
  - **Description**: Allow themes to inherit from base themes and override specific colors
  - **Implementation**: Extend `apply_theme()` in `lib/themes.sh` with inheritance logic
  - **Impact**: High - Enables easier custom theme creation
  - **Complexity**: Low-Medium
  - **Dependencies**: Current theme system

3. **Ocean Theme Full Integration** `[READY]`
  - **Status**: Complete theme exists in `examples/sample-configs/ocean-theme.toml`
  - **Description**: Make Ocean theme available as built-in option alongside classic/garden/catppuccin
  - **Implementation**: 
    - Add ocean color definitions to `lib/themes.sh`
    - Update theme selection logic
    - Add ocean theme documentation
  - **Impact**: Medium - More theme variety for users
  - **Complexity**: Low
  - **Dependencies**: None

### 🚨 **Critical Infrastructure Gaps**

4. **CI/CD Pipeline Setup** `[MISSING]`
  - **Status**: No `.github/workflows/` directory exists
  - **Description**: Automated testing, linting, and release process
  - **Implementation**:
    - Create `.github/workflows/ci.yml` for testing
    - Create `.github/workflows/release.yml` for automated releases
    - Multi-OS testing (macOS, Ubuntu, WSL)
    - Version bump automation
  - **Impact**: High - Essential for project quality and maintenance
  - **Complexity**: Medium
  - **Dependencies**: Current npm test scripts

5. **Release Automation** `[MISSING]`
  - **Status**: Manual release process currently
  - **Description**: Automated version bumping, changelog generation, and GitHub releases
  - **Implementation**:
    - Integrate with centralized version management (`version.txt`)
    - Automated changelog generation from conventional commits
    - GitHub release creation with assets
  - **Impact**: High - Reduces maintenance burden
  - **Complexity**: Medium
  - **Dependencies**: CI/CD pipeline, version.txt system

---

## ⚡ **Medium Priority**
*Significant enhancements and user experience improvements*

### 🎨 **User Experience Enhancements**

6. **Interactive Setup Wizard** `[NEW]`
  - **Description**: Guided setup process for new users with dependency checking and configuration
  - **Implementation**: 
    - Extend `install.sh` with interactive mode enhancements
    - Create `./statusline.sh --setup-wizard` command
    - Step-by-step theme selection, feature toggles, dependency installation
  - **Impact**: High - Dramatically improves first-time user experience
  - **Complexity**: Medium
  - **Files to modify**: `install.sh`, `statusline.sh`, new setup module

7. **Configuration GUI Tool** `[NEW]`
  - **Description**: Web-based or terminal-based GUI for configuration management
  - **Implementation**: 
    - Simple HTML interface that generates TOML configs
    - Or terminal-based TUI using `dialog`/`whiptail`
    - Real-time preview of statusline changes
  - **Impact**: Medium - Appeals to less technical users
  - **Complexity**: High
  - **Dependencies**: Web server (simple) or TUI libraries

8. **Theme Preview Mode** `[NEW]`
  - **Description**: Preview themes without changing configuration
  - **Implementation**: `./statusline.sh --preview-theme <theme-name>` command
  - **Impact**: Medium - Better theme selection experience
  - **Complexity**: Low
  - **Files to modify**: `statusline.sh`, `lib/themes.sh`

### 🔌 **Integration & Extensibility**

9. **Plugin System** `[NEW]`
  - **Description**: Allow custom modules to extend statusline functionality
  - **Implementation**:
    - Plugin directory structure: `~/.claude/statusline/plugins/`
    - Plugin API specification for custom data sources
    - Plugin loading and validation system
  - **Impact**: High - Enables community contributions and customization
  - **Complexity**: High
  - **Files to modify**: `lib/core.sh`, new plugin loader

10. **Shell Completion** `[NEW]`
  - **Description**: Bash/Zsh completion for statusline commands and options
  - **Implementation**: 
    - Generate completion scripts for `--help`, config options, themes
    - Installation integration in `install.sh`
  - **Impact**: Medium - Better developer experience
  - **Complexity**: Low-Medium
  - **Files to create**: `completions/bash_completion`, `completions/zsh_completion`

11. **GitHub Actions Integration** `[NEW]`
  - **Description**: Display CI/CD status, PR information, workflow status in statusline
  - **Implementation**:
    - New `lib/github.sh` module
    - GitHub API integration with timeout handling
    - Optional feature (disabled by default)
  - **Impact**: Medium - Valuable for developers using GitHub
  - **Complexity**: Medium
  - **Dependencies**: GitHub API, authentication

### 🚀 **Performance & Monitoring**

12. **Performance Analytics** `[NEW]`
  - **Description**: Optional analytics collection for performance optimization
  - **Implementation**:
    - Timing data collection (opt-in)
    - Performance regression detection
    - Usage pattern analysis (anonymized)
  - **Impact**: Medium - Data-driven optimization opportunities
  - **Complexity**: Medium
  - **Privacy**: Must be opt-in and transparent

13. **Auto-Update System** `[NEW]`
  - **Description**: Check for updates and offer automated upgrade path
  - **Implementation**:
    - `./statusline.sh --check-updates` command
    - Version comparison against GitHub releases
    - Automated backup before updates
  - **Impact**: Medium - Keeps users on latest version
  - **Complexity**: Medium
  - **Dependencies**: GitHub API, backup system

---

## 🌟 **Low Priority**
*Advanced features and long-term vision*

### 🎯 **Advanced Features**

14. **Cost Threshold Notifications** `[NEW]`
  - **Description**: Alert users when costs exceed configured thresholds
  - **Implementation**:
    - Configurable thresholds in TOML
    - Desktop notifications (optional)
    - Email notifications (optional)
  - **Impact**: Low-Medium - Helpful for cost-conscious users
  - **Complexity**: Medium
  - **Dependencies**: Notification systems

15. **Usage History & Analytics** `[NEW]`
  - **Description**: Track and visualize statusline usage patterns over time
  - **Implementation**:
    - Local SQLite database for history
    - Simple charts/graphs generation
    - Export functionality
  - **Impact**: Low - Nice-to-have for power users
  - **Complexity**: High
  - **Dependencies**: SQLite, charting library

16. **Multi-Workspace Support** `[NEW]`
  - **Description**: Manage multiple Claude Code workspaces with different configurations
  - **Implementation**:
    - Workspace detection and switching
    - Workspace-specific configurations
    - Status display for multiple workspaces
  - **Impact**: Low - Useful for advanced users with complex setups
  - **Complexity**: High
  - **Dependencies**: Profile system

### 🌐 **Ecosystem Integration**

17. **Docker Integration** `[NEW]`
  - **Description**: Docker container with statusline for consistent environments
  - **Implementation**:
    - Dockerfile with all dependencies
    - Docker Compose for development
    - Container registry publishing
  - **Impact**: Low - Useful for containerized workflows
  - **Complexity**: Low-Medium
  - **Files to create**: `Dockerfile`, `docker-compose.yml`

18. **IDE Plugins** `[NEW]`
  - **Description**: VS Code, Vim, Emacs plugins showing statusline info
  - **Implementation**:
    - Plugin development for major IDEs
    - JSON API for IDE integration
    - Real-time updates
  - **Impact**: Low - Expands reach beyond terminal users
  - **Complexity**: High
  - **Dependencies**: IDE-specific development

---

## 🛠️ **Infrastructure & Tooling**

### 🤖 **Development Automation**

- **Automated Testing Enhancements**
  - **Cross-platform Testing**: Windows Git Bash support
  - **Performance Regression Tests**: Automated benchmarking in CI
  - **Security Testing**: Regular vulnerability scanning
  - **Load Testing**: High-frequency statusline usage scenarios

- **Code Quality Tools**
  - **ShellCheck Integration**: Enhanced linting rules
  - **Code Coverage Analysis**: Track test coverage improvements
  - **Dependency Vulnerability Scanning**: Regular security audits
  - **Performance Profiling**: Identify bottlenecks

### 🏗️ **Project Infrastructure**

19. **Community Guidelines** `[PARTIAL]`
  - **Files to create**: `CODE_OF_CONDUCT.md`, issue/PR templates (CONTRIBUTING.md ✓ exists)
  - **Description**: Complete community contribution standardization
  - **Impact**: Medium - Enables community growth
  - **Complexity**: Low

20. **Package Manager Integration** `[NEW]`
  - **Description**: Publish to Homebrew, apt repositories, npm
  - **Implementation**:
    - Homebrew formula creation
    - Debian package building
    - npm wrapper package
  - **Impact**: Medium - Easier installation for users
  - **Complexity**: Medium
  - **Dependencies**: Release automation

---

## 📚 **Documentation Improvements**

### 📖 **New Documentation**

21. **Video Tutorial Series** `[NEW]`
  - Installation and setup walkthrough
  - Configuration customization guide
  - Theme creation tutorial
  - Advanced features demonstration

22. **Interactive Examples** `[NEW]`
  - Web-based configuration playground
  - Real-time statusline preview
  - Copy-paste ready configs

23. **API Documentation** `[NEW]`
  - Module API reference for contributors
  - Plugin development guide
  - Integration examples

### 📝 **Documentation Enhancements**

24. **Performance Tuning Guide** `[NEW]`
  - Optimization recommendations
  - Troubleshooting slow performance
  - Network timeout configuration

25. **Best Practices Guide** `[NEW]`
  - Configuration recommendations
  - Security considerations
  - Maintenance tips

---

## 🧪 **Testing Improvements**

### 🔬 **Test Coverage Expansion**

- **Security Testing**
  - Input validation fuzzing
  - Path traversal attack prevention
  - Command injection testing
  - File permission validation

- **Edge Case Coverage**
  - Very long directory paths
  - Special characters in paths
  - Concurrent statusline executions
  - Resource limitation scenarios
  - Network partition scenarios

- **Integration Testing**
  - Real MCP server integration tests
  - Actual ccusage integration tests
  - Multi-OS compatibility testing
  - Version upgrade/downgrade testing

---

## 🔒 **Security Enhancements**

### 🛡️ **Advanced Security**

26. **Configuration Encryption** `[NEW]`
  - **Description**: Optional encryption for sensitive configuration data
  - **Implementation**: GPG-based config encryption
  - **Impact**: Low - Security-conscious users
  - **Complexity**: Medium

27. **Audit Logging** `[NEW]`
  - **Description**: Optional logging of statusline operations for security monitoring
  - **Implementation**: Configurable audit trail
  - **Impact**: Low - Enterprise/security-focused environments
  - **Complexity**: Low-Medium

28. **Sandboxing** `[NEW]`
  - **Description**: Run statusline operations in restricted environment
  - **Implementation**: Use of restricted shells or containers
  - **Impact**: Low - High-security environments
  - **Complexity**: High

---

## 🚀 **Performance Optimizations**

### ⚡ **Speed Improvements**

- **Parallel Execution Enhancement**
  - More aggressive parallelization of independent operations
  - Background prefetching of common data
  - Smarter caching strategies

- **Memory Optimization**
  - Reduce memory footprint for large repositories
  - Streaming processing for large outputs
  - Cache size management

- **Network Optimization**
  - Request batching where possible
  - Better connection pooling
  - Intelligent retry strategies

---

## 🎭 **Theme & Customization**

### 🎨 **Extended Theme System**

29. **Dynamic Themes** `[NEW]`
  - Time-based theme switching (day/night)
  - Weather-based color adaptation
  - Context-aware theme selection

30. **Theme Marketplace** `[NEW]`
  - Community theme sharing
  - Theme rating and discovery
  - Easy theme installation

- **Advanced Customization**
  - Per-line color customization
  - Conditional formatting rules
  - Rich text formatting support

---

## 📊 **Metrics & Analytics**

### 📈 **Usage Insights**

31. **Usage Pattern Analysis**
  - Most used features identification
  - Performance bottleneck detection
  - User behavior insights (opt-in)

32. **Error Reporting**
  - Anonymous error collection (opt-in)
  - Crash reporting and recovery
  - Performance issue reporting

---

## 🔧 **Implementation Notes**

### 🏁 **Getting Started** *(Updated for v2.0.6)*

**Current State**: Core architecture and functionality are COMPLETE ✅
- Modular system (9 modules), TOML config, themes, caching, git/MCP/cost tracking all working

**Recommended Next Steps**:
1. **GitHub Issues #28 & #29** - New user-requested features with high impact
2. **CI/CD Pipeline** - Critical infrastructure gap (no `.github/workflows/` exists)
3. **Profile System** - Most requested advanced feature (mentioned in codebase)
4. **Ocean Theme** - Low-hanging fruit (theme exists in examples/, needs integration)

### 📝 **Development Guidelines**

- Maintain backward compatibility with existing configurations
- Follow existing code patterns and module structure
- Add comprehensive tests for all new features
- Update documentation with new features
- Consider security implications of all changes

### 🎯 **Success Criteria**

- **User Experience**: Features should feel intuitive and well-integrated
- **Performance**: New features should not significantly impact statusline speed
- **Reliability**: All features should gracefully handle failure scenarios
- **Security**: Security should be considered in all implementations
- **Documentation**: All features should be well-documented with examples

---

**Last Updated**: 2025-01-28 (Updated for v2.0.6 modular architecture completion)  
**Next Review**: Plan quarterly review of priorities based on user feedback and development progress

**Contributing**: Core architecture is complete! Focus on GitHub Issues #28 & #29 for immediate user impact, or tackle CI/CD infrastructure. See individual TODO items for implementation hints.

**Architecture Note**: v2.0.6 represents a major milestone - the transition from monolithic to modular architecture is complete with 91.5% code reduction and full feature parity. Future development can focus on enhancements rather than core infrastructure.

---

*Bismillah! May Allah facilitate the successful implementation of these improvements for the benefit of the Claude Code community. Barakallahu feek to all contributors! 🌟*