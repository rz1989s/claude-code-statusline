# 🧪 Testing Documentation

Comprehensive test suite for Claude Code Enhanced Statusline using the Bats testing framework.

## 📋 Test Structure

```
tests/
├── README.md                    # This file
├── setup_suite.bash             # Global test setup and utilities
├── helpers/
│   └── test_helpers.bash        # Test helper functions
├── unit/                        # Unit tests for individual functions
│   ├── test_git_functions.bats  # Git-related function tests
│   ├── test_mcp_parsing.bats    # MCP server parsing tests
│   ├── test_cost_calculations.bats # Cost tracking logic tests
│   ├── test_security.bats       # Security and validation tests
│   └── test_utilities.bats      # Utility function tests
├── integration/                 # End-to-end integration tests
│   ├── test_full_statusline.bats # Complete statusline output tests
│   ├── test_toml_integration.bats # Comprehensive TOML configuration tests
│   ├── test_toml_simple.bats     # Basic TOML parsing and structure tests
│   └── test_optimized_extraction.bats # Single-pass jq optimization tests
├── benchmarks/                  # Performance regression prevention
│   └── test_performance.bats    # Performance benchmarks and monitoring
│   ├── test_error_handling.bats # Error scenario tests
│   └── test_performance.bats    # Performance and timeout tests
└── fixtures/                   # Test data and mock responses
    ├── sample_outputs/          # Sample command outputs
    ├── mock_responses/          # Mock API responses
    └── test_configs/            # Test configuration files
```

## 🚀 Running Tests

### Prerequisites

1. **Install Bats** (if not already installed):
   ```bash
   # macOS with Homebrew
   brew install bats-core
   
   # Ubuntu/Debian
   apt-get install bats
   
   # Or install via npm
   npm install -g bats
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

### Running All Tests

```bash
# Run complete test suite
npm test

# Or directly with bats
bats tests/**/*.bats
```

### Running Specific Test Categories

```bash
# Unit tests only
npm run test:unit

# Integration tests only
npm run test:integration

# Specific test file
bats tests/unit/test_git_functions.bats
```

### Development Testing

```bash
# Run tests with verbose output
bats tests/**/*.bats --tap

# Clean and test (removes cache files first)
npm run dev

# Continuous testing during development
npm run test:watch
```

## 🔍 Test Categories

### Unit Tests

Test individual functions in isolation with mocked dependencies:

- **Git Functions**: Repository status, branch detection, commit counting
- **MCP Parsing**: Server status parsing, connection state detection
- **Cost Calculations**: ccusage data processing, cost formatting
- **Security**: Input validation, path sanitization
- **Utilities**: Date handling, caching, configuration loading

### Integration Tests

Test complete statusline functionality with realistic scenarios:

- **Full Statusline**: End-to-end output testing with various configurations
- **Error Handling**: Network timeouts, missing dependencies, malformed input
- **Performance**: Response time testing, concurrent execution

### Fixtures and Mocking

Tests use realistic mock data stored in `fixtures/`:

- **Sample Outputs**: Real command outputs for reproducible testing
- **Mock Responses**: Simulated API responses for different scenarios
- **Test Configs**: Various configuration combinations

## 🛠️ Writing New Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load test framework
load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    setup_full_mock_environment
}

teardown() {
    common_teardown
}

@test "function should handle normal input correctly" {
    # Setup
    local input="test input"
    
    # Execute
    run my_function "$input"
    
    # Assert
    assert_success
    assert_output_contains "expected output"
}
```

### Test Helper Functions

Available helper functions from `test_helpers.bash`:

- `setup_mock_git_repo()` - Create mock git repository
- `setup_mock_ccusage()` - Mock ccusage commands
- `setup_mock_mcp()` - Mock MCP server responses
- `validate_statusline_format()` - Validate output structure
- `strip_ansi_codes()` - Remove color codes for testing
- `extract_line_from_output()` - Get specific output lines

### Mocking External Commands

```bash
# Mock successful command
create_mock_command "git" "* main" 0

# Mock failing command
create_failing_mock_command "claude" "connection failed" 1

# Mock from fixture file
create_mock_command_from_file "claude" "$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_connected.txt"
```

## 📊 Test Scenarios

### Positive Test Cases

- ✅ Clean git repository with all features working
- ✅ Dirty repository with multiple MCP servers
- ✅ Cost tracking with active billing blocks
- ✅ All themes rendering correctly
- ✅ Proper caching behavior

### Error Handling Test Cases

- ❌ Network timeouts for external services
- ❌ Missing dependencies (bc, python3, bunx)
- ❌ Malformed JSON responses
- ❌ Invalid git repositories
- ❌ Corrupted cache files

### Edge Cases

- 🔍 Empty MCP server configurations
- 🔍 Very long directory paths
- 🔍 Special characters in paths
- 🔍 Concurrent statusline executions
- 🔍 System resource limitations

## 🚨 Debugging Failed Tests

### Verbose Output

```bash
# Run with detailed output
bats tests/unit/test_git_functions.bats --verbose

# Show all command output
bats tests/ --show-output-of-passing-tests
```

### Manual Testing

```bash
# Source test environment
source tests/setup_suite.bash
common_setup

# Test individual functions
setup_mock_git_repo "/tmp/test_repo" "clean"
cd /tmp/test_repo

# Test the statusline manually
echo '{"workspace":{"current_dir":"/tmp/test_repo"},"model":{"display_name":"Test"}}' | ./statusline.sh
```

### Debug Environment Variables

```bash
# Enable debug mode
export CONFIG_DEBUG=true

# Use test cache location
export CONFIG_VERSION_CACHE_FILE="/tmp/test_cache"

# Shorter timeouts for testing
export CONFIG_MCP_TIMEOUT="1s"
```

## 📈 Coverage Goals

### Current Coverage Targets

- **Unit Tests**: 95%+ function coverage
- **Integration Tests**: All major user scenarios
- **Error Handling**: All timeout and failure scenarios
- **Security Tests**: All input validation paths

### Adding Coverage

When adding new features:

1. **Write tests first** (TDD approach)
2. **Test both success and failure cases**
3. **Include edge cases and boundary conditions**
4. **Mock external dependencies appropriately**
5. **Document test scenarios in comments**

## 🔧 Continuous Integration

Tests run automatically on:

- **Pull Requests**: All tests must pass
- **Main Branch**: Comprehensive test suite
- **Releases**: Extended test matrix with performance benchmarks

### CI Configuration

See `.github/workflows/test.yml` for the complete CI setup including:

- **Multiple OS testing**: macOS, Ubuntu
- **Shell compatibility**: bash 4.0+, 5.0+
- **Dependency variations**: With and without optional tools
- **Performance benchmarks**: Response time validation

## 💡 Best Practices

1. **Keep tests focused**: One concept per test
2. **Use descriptive test names**: Clearly state what is being tested
3. **Clean up after tests**: Use proper teardown functions
4. **Mock external dependencies**: Don't rely on real network calls
5. **Test error conditions**: Ensure graceful failure handling
6. **Document complex test scenarios**: Add comments for unusual cases

## 🆘 Getting Help

- **Test failures**: Check the test output and debug with `--verbose`
- **Bats syntax**: See [Bats documentation](https://bats-core.readthedocs.io/)
- **Mock issues**: Review `test_helpers.bash` for available functions
- **New test scenarios**: Follow existing patterns in `unit/` and `integration/`

---

**Happy Testing!** Well-tested code is reliable code. 🎉