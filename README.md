# Pact Template

[![Contract Tests](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml/badge.svg)](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml)

A project template for writing smart contracts in the Pact language for use in the Kadena ecosystem. This template is a suitable starting point for new projects, providing:

* A smart contract and associated REPL files demonstrating best practices for testing
* Bootstrap REPL files which mimic the Chainweb environment for more realistic tests
* Continuous integration via GitHub workflows

## Installation

This repository includes a `.pact-version` file suitable for use with [pactup](https://github.com/kadena-community/pactup). The same Pact version is used in continuous integration. You only need Pact and a shell to use this repository.

## Test Structure

Each module in `contracts/modules` must have a corresponding test directory in `contracts/tests/modules`, unless explicitly excluded via the exceptions file. For example:

```
contracts/
├── modules/
│   ├── simple-staking.pact
│   └── other-module.pact
└── tests/
    └── modules/
        ├── simple-staking/
        │   ├── main.repl      # Required integration tests
        │   ├── auth.repl      # Optional auth tests
        │   ├── unit.repl      # Optional unit tests
        │   └── gas.repl       # Optional gas tests
        └── other-module/
            ├── main/          # Alternative to main.repl
            │   ├── test1.repl
            │   └── test2.repl
            ├── auth/          # Alternative to auth.repl
            │   └── caps.repl
            ├── unit/          # Alternative to unit.repl
            │   └── basic.repl
            └── gas/           # Alternative to gas.repl
                └── common.repl
```

### Test Types

The test runner recognizes four types of tests:

1. **Main Tests (Required)**
   - Either `main.repl` or a `main/` directory with .repl files, but not both
   - Contains integration tests demonstrating complete module workflows
   - Must be present and non-empty

2. **Auth Tests (Optional)**
   - Either `auth.repl` or an `auth/` directory with .repl files
   - Tests access control, capabilities, signatures, etc.
   - Recommended for any module that uses capabilities or keysets

3. **Unit Tests (Optional)**
   - Either `unit.repl` or a `unit/` directory with .repl files
   - Tests individual function behavior
   - Recommended for all non-trivial modules

4. **Gas Tests (Optional)**
   - Either `gas.repl` or a `gas/` directory with .repl files
   - Measures gas consumption of operations
   - Run last due to verbose output

For each test type, you may use either a single .repl file or a directory of .repl files, but not both. Main tests are required; all others are optional but recommended where appropriate.

### Running Tests

The test runner provides several options for running tests:

```bash
# Run all tests for all modules
./run.sh

# Run tests for specific modules
./run.sh --module simple-staking,other-module

# Run specific test types
./run.sh --type unit,auth

# Skip specific test types
./run.sh --exclude-type gas
```

### Verbosity Options

The test runner supports different verbosity levels:

```bash
# Normal mode (default) - shows which tests are running
./run.sh

# Quiet mode - only shows output on failure
./run.sh --quiet

# Verbose mode - shows all Pact output
./run.sh --verbose

# Debug mode - shows all output and enables Pact trace mode
./run.sh --debug
```

### Excluding Modules from Testing

To exclude modules from testing requirements (e.g., utility modules), list their filenames in `contracts/tests/test-exceptions.txt`:

```txt
# List modules that don't require tests (one per line)
ns.pact
constants.pact
```

### Test Execution Order

The test runner executes tests in this order:

1. Auth tests (if present)
2. Unit tests (if present)
3. Main tests (required)
4. Gas tests (if present, run last)

The runner collects all failures and reports them at the end rather than stopping at the first failure.

## Testing Environment

The `bootstrap.repl` file creates a local testing environment that mimics the Chainweb blockchain. This includes:

- Basic Kadena contracts (coin, ns, etc.)
- Standard namespaces (free, util, kip, etc.)
- Test accounts with funded KDA
- A principal namespace for your project's contracts

### Using in Tests

To use this environment in your tests:

```repl
;; First load the bootstrap environment
(load "../bootstrap.repl")

;; Now you can use the pre-configured accounts and namespaces
(begin-tx)
(use base)  ;; Access environment constants

;; Test your contract
(expect "Transfer should succeed"
  "Write succeeded"
  (your-contract.transfer ALICE BOB 100.0))

(expect "Bob's balance increased"
  100.0
  (your-contract.get-balance BOB))
```

The base module provides constants for accounts, keys, and guards - see `bootstrap.repl` for all available values.
