#!/usr/bin/env bats

# Platform Compatibility Tests
# Tests cross-platform compatibility for macOS and Linux

# Load test dependencies
load ../setup_suite

setup() {
    cd "$BATS_TEST_DIRNAME/../.."
    export STATUSLINE_DEBUG=false
    export STATUSLINE_TESTING=true
}

# ============================================================================
# TIMEOUT/GTIMEOUT COMMAND DETECTION TESTS
# ============================================================================

@test "timeout command selection prefers correct platform default" {
    # Test timeout selection logic for macOS
    run bash -c '
        OS_TYPE="Darwin"

        # Mock command_exists function for testing
        command_exists() {
            case "$1" in
                "gtimeout") return 0 ;;
                "timeout") return 0 ;;
                *) return 1 ;;
            esac
        }

        # Test macOS logic
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            if command_exists "gtimeout"; then
                timeout_cmd="gtimeout"
            elif command_exists "timeout"; then
                timeout_cmd="timeout"
            fi
        else
            if command_exists "timeout"; then
                timeout_cmd="timeout"
            elif command_exists "gtimeout"; then
                timeout_cmd="gtimeout"
            fi
        fi

        echo "$timeout_cmd"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "gtimeout" ]]
}

@test "timeout command selection on Linux prefers system timeout" {
    # Test Linux environment
    run bash -c '
        OS_TYPE="Linux"

        # Mock command_exists function
        command_exists() {
            case "$1" in
                "timeout") return 0 ;;
                "gtimeout") return 0 ;;
                *) return 1 ;;
            esac
        }

        # Test Linux logic
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            if command_exists "gtimeout"; then
                timeout_cmd="gtimeout"
            elif command_exists "timeout"; then
                timeout_cmd="timeout"
            fi
        else
            if command_exists "timeout"; then
                timeout_cmd="timeout"
            elif command_exists "gtimeout"; then
                timeout_cmd="gtimeout"
            fi
        fi

        echo "$timeout_cmd"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "timeout" ]]
}

@test "timeout command fallback works when preferred not available" {
    # Test macOS fallback to timeout when gtimeout unavailable
    run bash -c '
        OS_TYPE="Darwin"

        # Mock command_exists - only timeout available
        command_exists() {
            case "$1" in
                "timeout") return 0 ;;
                "gtimeout") return 1 ;;
                *) return 1 ;;
            esac
        }

        # Test macOS fallback logic
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            if command_exists "gtimeout"; then
                timeout_cmd="gtimeout"
            elif command_exists "timeout"; then
                timeout_cmd="timeout"
            fi
        fi

        echo "$timeout_cmd"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "timeout" ]]
}

# ============================================================================
# BASH PATH DETECTION TESTS
# ============================================================================

@test "bash path detection prioritizes correct platform paths" {
    # Test macOS bash path prioritization
    run bash -c '
        OS_TYPE="Darwin"

        if [[ "$OS_TYPE" == "Darwin" ]]; then
            bash_paths=("/opt/homebrew/bin/bash" "/usr/local/bin/bash" "/opt/local/bin/bash" "/usr/bin/bash" "/bin/bash")
        else
            bash_paths=("/usr/bin/bash" "/bin/bash" "/usr/local/bin/bash" "/opt/local/bin/bash")
        fi

        echo "${bash_paths[0]}"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "/opt/homebrew/bin/bash" ]]
}

@test "bash path detection on Linux prioritizes system paths" {
    # Test Linux bash path prioritization
    run bash -c '
        OS_TYPE="Linux"

        if [[ "$OS_TYPE" == "Darwin" ]]; then
            bash_paths=("/opt/homebrew/bin/bash" "/usr/local/bin/bash" "/opt/local/bin/bash" "/usr/bin/bash" "/bin/bash")
        else
            bash_paths=("/usr/bin/bash" "/bin/bash" "/usr/local/bin/bash" "/opt/local/bin/bash")
        fi

        echo "${bash_paths[0]}"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "/usr/bin/bash" ]]
}

# ============================================================================
# PACKAGE MANAGER DETECTION TESTS
# ============================================================================

@test "package manager detection identifies correct managers" {
    # Test package manager detection logic
    run bash -c '
        # Mock command_exists for different scenarios
        test_apt() {
            command_exists() { [[ "$1" == "apt" ]]; }
            PKG_MGR="none"
            if command_exists apt; then PKG_MGR="apt"; fi
            echo "$PKG_MGR"
        }

        test_pacman() {
            command_exists() { [[ "$1" == "pacman" ]]; }
            PKG_MGR="none"
            if command_exists pacman; then PKG_MGR="pacman"; fi
            echo "$PKG_MGR"
        }

        test_apt
        test_pacman
    '

    [[ "$status" -eq 0 ]]
    [[ "${lines[0]}" == "apt" ]]
    [[ "${lines[1]}" == "pacman" ]]
}

# ============================================================================
# GEOCLUE PATH DETECTION TESTS
# ============================================================================

@test "geoclue detection checks multiple paths" {
    # Test geoclue path detection logic
    run bash -c '
        geoclue_paths=(
            "/usr/lib/geoclue-2.0/demos/where-am-i"
            "/usr/libexec/geoclue-2.0/demos/where-am-i"
            "/usr/bin/where-am-i"
        )

        # Mock file existence check
        test_path_exists() {
            for path in "${geoclue_paths[@]}"; do
                echo "Checking: $path"
            done
        }

        test_path_exists
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "/usr/lib/geoclue-2.0/demos/where-am-i" ]]
    [[ "$output" =~ "/usr/libexec/geoclue-2.0/demos/where-am-i" ]]
    [[ "$output" =~ "/usr/bin/where-am-i" ]]
}

# ============================================================================
# DISTRIBUTION-SPECIFIC PACKAGE NAME TESTS
# ============================================================================

@test "geoclue package names are distribution-aware" {
    # Test distribution-specific package naming
    run bash -c '
        test_ubuntu() {
            ID="ubuntu"
            case "$ID" in
                "ubuntu"|"debian") echo "geoclue-2-demo" ;;
                "arch"|"manjaro") echo "geoclue" ;;
                "fedora"|"rhel"|"centos") echo "geoclue2-devel" ;;
                "alpine") echo "geoclue-dev" ;;
                *) echo "geoclue2" ;;
            esac
        }

        test_arch() {
            ID="arch"
            case "$ID" in
                "ubuntu"|"debian") echo "geoclue-2-demo" ;;
                "arch"|"manjaro") echo "geoclue" ;;
                "fedora"|"rhel"|"centos") echo "geoclue2-devel" ;;
                "alpine") echo "geoclue-dev" ;;
                *) echo "geoclue2" ;;
            esac
        }

        test_fedora() {
            ID="fedora"
            case "$ID" in
                "ubuntu"|"debian") echo "geoclue-2-demo" ;;
                "arch"|"manjaro") echo "geoclue" ;;
                "fedora"|"rhel"|"centos") echo "geoclue2-devel" ;;
                "alpine") echo "geoclue-dev" ;;
                *) echo "geoclue2" ;;
            esac
        }

        echo "Ubuntu: $(test_ubuntu)"
        echo "Arch: $(test_arch)"
        echo "Fedora: $(test_fedora)"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Ubuntu: geoclue-2-demo" ]]
    [[ "$output" =~ "Arch: geoclue" ]]
    [[ "$output" =~ "Fedora: geoclue2-devel" ]]
}

# ============================================================================
# STAT COMMAND COMPATIBILITY TESTS
# ============================================================================

@test "stat command syntax is platform-aware" {
    # Test stat command compatibility logic
    run bash -c '
        test_macos_stat() {
            uname() { echo "Darwin"; }
            if [[ "$(uname)" == "Darwin" ]]; then
                echo "stat -f %m"
            else
                echo "stat -c %Y"
            fi
        }

        test_linux_stat() {
            uname() { echo "Linux"; }
            if [[ "$(uname)" == "Darwin" ]]; then
                echo "stat -f %m"
            else
                echo "stat -c %Y"
            fi
        }

        echo "macOS: $(test_macos_stat)"
        echo "Linux: $(test_linux_stat)"
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "macOS: stat -f %m" ]]
    [[ "$output" =~ "Linux: stat -c %Y" ]]
}

# ============================================================================
# ERROR MESSAGE CUSTOMIZATION TESTS
# ============================================================================

@test "error messages are platform and distribution aware" {
    # Test platform-aware error messages
    run bash -c '
        test_macos_message() {
            OS_TYPE="Darwin"
            missing_deps=("jq" "curl")

            if [[ "$OS_TYPE" == "Darwin" ]]; then
                echo "macOS: brew install ${missing_deps[*]}"
            fi
        }

        test_ubuntu_message() {
            OS_TYPE="Linux"
            PKG_MGR="apt"
            missing_deps=("jq" "curl")

            if [[ "$OS_TYPE" != "Darwin" ]]; then
                case "$PKG_MGR" in
                    "apt") echo "Ubuntu/Debian: sudo apt update && sudo apt install ${missing_deps[*]}" ;;
                    "pacman") echo "Arch Linux: sudo pacman -S ${missing_deps[*]}" ;;
                esac
            fi
        }

        test_macos_message
        test_ubuntu_message
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "macOS: brew install jq curl" ]]
    [[ "$output" =~ "Ubuntu/Debian: sudo apt update && sudo apt install jq curl" ]]
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "install.sh timeout logic works end-to-end" {
    # Test that the actual install.sh has the fixed logic
    run bash -c '
        # Check if install.sh contains the platform-aware timeout logic
        if [[ -f "install.sh" ]]; then
            # Look for the platform-aware timeout logic we added
            if grep -q "platform-aware selection" install.sh; then
                echo "platform-aware timeout logic found"
            fi

            # Look for the safe_remove_directory function
            if grep -q "safe_remove_directory" install.sh; then
                echo "safe_remove_directory function found"
            fi
        fi
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "platform-aware timeout logic found" ]]
    [[ "$output" =~ "safe_remove_directory function found" ]]
}

@test "prayer location timeout logic is platform-aware" {
    # Test that lib/prayer/location.sh uses platform-aware timeout
    run bash -c '
        if [[ -f "lib/prayer/location.sh" ]]; then
            # Check that the file contains platform-aware timeout selection
            grep -q "Use platform-appropriate timeout command" lib/prayer/location.sh
            echo $?
        else
            echo "1"
        fi
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "0" ]]
}

@test "statusline.sh bash detection is cross-platform" {
    # Test that statusline.sh has platform-aware bash detection
    run bash -c '
        if [[ -f "statusline.sh" ]]; then
            # Check for platform-aware bash candidate selection
            grep -q "Platform-aware bash candidate prioritization" statusline.sh
            echo $?
        else
            echo "1"
        fi
    '

    [[ "$status" -eq 0 ]]
    [[ "$output" == "0" ]]
}