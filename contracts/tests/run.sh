#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 [--module MODULE_NAME] [--type TYPE1,TYPE2,...] [--quiet]"
    echo
    echo "Options:"
    echo "  --module   Specify a module name to run only its tests"
    echo "  --type     Specify test types to run (unit,auth,gas,integration)"
    echo "  --quiet    Suppress output unless there is a test failure"
    echo
    echo "If no arguments are provided, runs all test files except bootstrap* and setup*"
    exit 1
}

# Parse command line arguments
QUIET=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            MODULE="$2"
            shift 2
            ;;
        --type)
            TYPES="$2"
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

# Base directory (current directory since script is in tests/)
TEST_DIR="."

# Function to run test file
run_test() {
    if [ "$QUIET" = false ]; then
        echo "Running test: $1"
    fi

    # Capture both stdout and stderr
    output=$(pact "$1" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Test failed: $1"
        echo "Output:"
        echo "$output"
        exit 1
    fi
}

# Run tests based on arguments
if [ -n "$MODULE" ]; then
    if [ -n "$TYPES" ]; then
        # Run specific types for specific module
        IFS=',' read -ra TYPE_ARRAY <<< "$TYPES"
        for type in "${TYPE_ARRAY[@]}"; do
            case $type in
                unit)
                    if [ -f "$TEST_DIR/modules/$MODULE/unit.repl" ]; then
                        run_test "$TEST_DIR/modules/$MODULE/unit.repl"
                    fi
                    ;;
                auth)
                    if [ -f "$TEST_DIR/modules/$MODULE/auth.repl" ]; then
                        run_test "$TEST_DIR/modules/$MODULE/auth.repl"
                    fi
                    ;;
                gas)
                    if [ -f "$TEST_DIR/modules/$MODULE/gas.repl" ]; then
                        run_test "$TEST_DIR/modules/$MODULE/gas.repl"
                    fi
                    ;;
                integration)
                    if [ -f "$TEST_DIR/$MODULE.repl" ]; then
                        run_test "$TEST_DIR/$MODULE.repl"
                    fi
                    ;;
                *)
                    echo "Unknown test type: $type"
                    exit 1
                    ;;
            esac
        done
    else
        # Run all tests for specific module
        if [ -d "$TEST_DIR/modules/$MODULE" ]; then
            while IFS= read -r file; do
                run_test "$file"
            done < <(find "$TEST_DIR/modules/$MODULE" -name "*.repl" ! -name "setup.repl")
        fi
        if [ -f "$TEST_DIR/$MODULE.repl" ]; then
            run_test "$TEST_DIR/$MODULE.repl"
        fi
    fi
elif [ -n "$TYPES" ]; then
    # Run specific types for all modules
    IFS=',' read -ra TYPE_ARRAY <<< "$TYPES"
    for type in "${TYPE_ARRAY[@]}"; do
        case $type in
            unit)
                while IFS= read -r file; do
                    run_test "$file"
                done < <(find "$TEST_DIR" -name "unit.repl")
                ;;
            auth)
                while IFS= read -r file; do
                    run_test "$file"
                done < <(find "$TEST_DIR" -name "auth.repl")
                ;;
            gas)
                while IFS= read -r file; do
                    run_test "$file"
                done < <(find "$TEST_DIR" -name "gas.repl")
                ;;
            integration)
                while IFS= read -r file; do
                    run_test "$file"
                done < <(find "$TEST_DIR" -maxdepth 1 -name "*.repl" ! -name "bootstrap*.repl" ! -name "setup*.repl")
                ;;
            *)
                echo "Unknown test type: $type"
                exit 1
                ;;
        esac
    done
else
    # Run all tests except bootstrap and setup
    while IFS= read -r file; do
        run_test "$file"
    done < <(find "$TEST_DIR" -name "*.repl" ! -name "bootstrap*.repl" ! -name "setup*.repl")
fi

if [ "$QUIET" = false ]; then
    echo "All tests passed successfully"
fi
