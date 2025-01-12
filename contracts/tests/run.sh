#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 [--module MODULE1,MODULE2,...] [--type TYPE1,TYPE2,...] [--exclude-type TYPE1,TYPE2,...] [--quiet]"
    echo
    echo "Options:"
    echo "  --module       pecify comma-separated module names to test (without .pact extension)"
    echo "  --type         Specify which test types to run (auth,unit,main,gas)"
    echo "  --exclude-type Specify which test types to skip (auth,unit,main,gas)"
    echo "  --quiet        Suppress output unless there is a test failure"
    echo
    echo "Examples:"
    echo "  ./run.sh"
    echo "  ./run.sh --module simple-staking"
    echo "  ./run.sh --type unit,main"
    echo "  ./run.sh --exclude-type gas"
    echo "  ./run.sh --quiet"
    exit 1
}

# Parse command line arguments
QUIET=false
MODULES=""
TYPES=""
EXCLUDE_TYPES=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            MODULES="$2"
            shift 2
            ;;
        --type)
            TYPES="$2"
            shift 2
            ;;
        --exclude-type)
            EXCLUDE_TYPES="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Directories
BASE_DIR=".."
MODULE_DIR="$BASE_DIR/modules"
TEST_DIR="."
MODULE_TEST_DIR="$TEST_DIR/modules"
EXCEPTIONS_FILE="$TEST_DIR/test-exceptions.txt"

# Arrays to store test results
declare -a FAILED_TESTS=()
declare -a GAS_TESTS=()

# Function to check if a test type should be run
should_run_test_type() {
    local test_type="$1"

    # If specific types are specified, check if this type is included
    if [ -n "$TYPES" ]; then
        echo "$TYPES" | tr ',' '\n' | grep -q "^$test_type$" || return 1
    fi

    # If excluded types are specified, check if this type is excluded
    if [ -n "$EXCLUDE_TYPES" ]; then
        echo "$EXCLUDE_TYPES" | tr ',' '\n' | grep -q "^$test_type$" && return 1
    fi

    return 0
}

# Function to check if a module is excepted from testing
is_excepted_module() {
    local file_name="$1"
    if [ -f "$EXCEPTIONS_FILE" ]; then
        if grep -v '^#' "$EXCEPTIONS_FILE" | grep -q "^${file_name}$"; then
            if [ "$QUIET" = false ]; then
                echo "Skipping excepted module: $file_name"
            fi
            return 0
        fi
    fi
    return 1
}

# Function to verify main tests exist and aren't empty
verify_main_tests() {
    local module_test_dir="$1"
    local has_valid_tests=false

    # Check main.repl
    if [ -f "$module_test_dir/main.repl" ]; then
        if [ -s "$module_test_dir/main.repl" ]; then
            has_valid_tests=true
        fi
    fi

    # Check main directory
    if [ -d "$module_test_dir/main" ]; then
        if [ "$(find "$module_test_dir/main" -name "*.repl" -type f)" ]; then
            if [ "$has_valid_tests" = true ]; then
                return 2  # Both main.repl and main/ exist
            fi
            has_valid_tests=true
        fi
    fi

    if [ "$has_valid_tests" = true ]; then
        return 0
    fi
    return 1
}

# Function to run a test file and collect results
run_test() {
    local test_file="$1"
    local module_name="$2"
    local test_type="$3"

    if [ "$QUIET" = false ]; then
        echo "Running $test_type test: $test_file"
    fi

    # Capture both stdout and stderr
    output=$(pact "$test_file" 2>&1)
    if [ $? -ne 0 ]; then
        FAILED_TESTS+=("$module_name - $test_type - $test_file")
        if [ "$QUIET" = false ]; then
            echo "Test failed: $test_file"
            echo "Output:"
            echo "$output"
        fi
    fi
}

# Function to run tests of a specific type for a module
run_test_type() {
    local module_name="$1"
    local test_type="$2"
    local module_test_dir="$MODULE_TEST_DIR/$module_name"

    # Skip if this test type shouldn't be run
    should_run_test_type "$test_type" || return 0

    # Handle gas tests separately - we'll run those later
    if [ "$test_type" = "gas" ]; then
        if [ -f "$module_test_dir/gas.repl" ]; then
            GAS_TESTS+=("$module_test_dir/gas.repl")
        fi
        if [ -d "$module_test_dir/gas" ]; then
            while IFS= read -r file; do
                GAS_TESTS+=("$file")
            done < <(find "$module_test_dir/gas" -name "*.repl")
        fi
        return
    fi

    # Run single file if it exists
    if [ -f "$module_test_dir/$test_type.repl" ]; then
        run_test "$module_test_dir/$test_type.repl" "$module_name" "$test_type"
    fi

    # Run directory contents if they exist
    if [ -d "$module_test_dir/$test_type" ]; then
        while IFS= read -r file; do
            run_test "$file" "$module_name" "$test_type"
        done < <(find "$module_test_dir/$test_type" -name "*.repl")
    fi
}

# Function to verify module has required tests
verify_module_tests() {
    local module="$1"
    local module_test_dir="$MODULE_TEST_DIR/$module"

    # Check for main test (required)
    verify_main_tests "$module_test_dir"
    local main_result=$?

    case $main_result in
        0)  return 0 ;;  # Valid main tests exist
        1)  FAILED_TESTS+=("$module - Missing or empty main tests")
            return 1 ;;
        2)  FAILED_TESTS+=("$module - Both main.repl and main/ exist")
            return 1 ;;
    esac
}

# Get list of modules to test
if [ -n "$MODULES" ]; then
    IFS=',' read -ra TEMP_MODULE_LIST <<< "$MODULES"
    for module in "${TEMP_MODULE_LIST[@]}"; do
        if ! is_excepted_module "${module}.pact"; then
            MODULE_LIST+=("$module")
        fi
    done
else
    # Get all modules except those in exceptions file
    while IFS= read -r file; do
        file_name=$(basename "$file")
        if ! is_excepted_module "$file_name"; then
            module_name=$(basename "$file_name" .pact)
            MODULE_LIST+=("$module_name")
        fi
    done < <(find "$MODULE_DIR" -name "*.pact")
fi

# Verify all modules have test directories
for module in "${MODULE_LIST[@]}"; do
    if [ ! -d "$MODULE_TEST_DIR/$module" ]; then
        FAILED_TESTS+=("$module - Missing test directory")
        continue
    fi

    verify_module_tests "$module" || continue

    # Run tests in order: auth, unit, main
    for test_type in auth unit main gas; do
        run_test_type "$module" "$test_type"
    done
done

# Run gas tests last
if should_run_test_type "gas" && [ ${#GAS_TESTS[@]} -gt 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "\nRunning gas tests..."
    fi
    for test in "${GAS_TESTS[@]}"; do
        module_name=$(echo "$test" | sed -E "s|.*/modules/([^/]+)/.*|\1|")
        run_test "$test" "$module_name" "gas"
    done
fi

# Report results
if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo "All tests passed successfully"
    fi
    exit 0
else
    echo -e "\nTest failures:"
    printf '%s\n' "${FAILED_TESTS[@]}"
    exit 1
fi
