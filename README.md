# Pact Template

[![Contract Tests](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml/badge.svg)](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml)

A project template for writing smart contracts in the Pact language for use in the Kadena ecosystem. This template is a suitable starting point for new projects, providing:

* A smart contract and associated REPL files demonstrating best practices for testing
* Bootstrap REPL files which mimic the Chainweb environment for more realistic tests
* Continuous integration via GitHub workflows

## Installation & Use

This repository is a template, so you should feel free to copy and modify it for your needs.

The root includes a `.pact-version` file suitable for use with [pactup](https://github.com/kadena-community/pactup). The same Pact version is used in continuous integration. There are no dependencies for this project except `pact` and a shell.

There is an included test runner that will execute module tests. This is particularly useful with `watchexec` to execute tests while you work on particular modules. There are more details about how this script works in the **Test Structure** section.

```sh
# the 'test runner'
./contracts/tests/run.sh
```

## Project Structure

This template recommends a specific structure for your Pact code:

```tree
contracts/
├── interfaces/          # Interface definitions
     └── your-iface.pact
├── modules/             # Contract implementations
     ├── constants.pact  # Constant definitions for your modules
     ├── ns.pact         # Definition of your principal namespace
     └── your-module.pact
└── tests/
    ├── bootstrap/       # Chainweb environment simulation
         ├── coin.pact
         └── ...
    ├── bootstrap.repl   # Initialize test environment
    └── modules/         # Tests grouped by module
        └── your-module/ # Tests for specific module
            ├── setup.repl    # Module initialization & dependencies
            ├── gas.repl      # Gas consumption measurements
            ├── auth.repl     # Access control tests
            ├── unit/         # Individual function tests
                 ├── transfer.repl
                 └── stake.repl
            └── main.repl     # Top-level integration/usage tests
```

## Test Structure

Each module in `modules` must have a corresponding test directory in `tests/modules`, unless explicitly excluded via the exceptions file.

### Test Types

The test runner recognizes four types of tests:

1. **Main Tests (Required)**
   - Either `main.repl` or a `main/` directory with .repl files
   - Contains integration tests demonstrating complete module workflows
   - Must be present and non-empty

2. **Auth Tests (Optional for modules without auth)**
   - Either `auth.repl` or an `auth/` directory
   - Tests access control, capabilities, signatures, etc.
   - Recommended for any module that uses capabilities or keysets

3. **Unit Tests (Optional for trivial modules)**
   - Either `unit.repl` or a `unit/` directory
   - Tests individual function behavior
   - Recommended for all non-trivial modules

4. **Gas Tests (Optional)**
   - Either `gas.repl` or a `gas/` directory
   - Measures gas consumption of operations

For each test type, you may use either a single .repl file or a directory of .repl files. Main tests are required; all others are optional but recommended where appropriate.

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
