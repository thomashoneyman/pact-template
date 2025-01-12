# Kadena Template

[![Contract Tests](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml/badge.svg)](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml)

A project template for writing smart contracts in the Pact language for use in the Kadena ecosystem. This template is a suitable starting point for new projects, providing:

* A smart contract and associated REPL files demonstrating best practices for testing
* Bootstrap REPL files which mimic the Chainweb environment for more realistic tests
* Continuous integration via GitHub workflows

## Installation

This repository includes a `.pact-version` file suitable for use with [pactup](https://github.com/kadena-community/pactup). The same Pact version is used in continuous integration. You only need Pact and a shell to use this repository.

You can execute tests with:

```sh
./contracts/tests/run.sh
```

## Structure

This template recommends a specific structure for your Pact code:

```
contracts/
├── interfaces/           # Interface definitions
     └── your-iface.pact
├── modules/              # Contract implementations
     ├── constants.pact   # Constant definitions for your modules
     ├── ns.pact          # Definition of your principal namespace
     └── your-module.pact
└── tests/
    ├── bootstrap/        # Chainweb environment simulation
         ├── coin.pact
         └── ...
    ├── bootstrap.repl    # Initialize test environment
    └── your-module/      # Tests grouped by module
        ├── setup.repl    # Module initialization & dependencies
        ├── gas.repl      # Gas consumption measurements
        ├── auth.repl     # Access control tests
        ├── unit/         # Individual function tests
             ├── transfer.repl
             └── stake.repl
        └── main.repl  # Top-level integration/usage tests
```

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

## Running Tests

This project uses a structured testing approach that requires a specific organization of test files. The test runner enforces these conventions to ensure all modules are comprehensively tested.

### Test Organization

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
            ├── auth/          # Alternative to unit.repl
            │   └── capabilities.repl
            ├── unit/          # Alternative to unit.repl
            │   └── basic.repl
            └── gas/           # Alternative to gas.repl
                └── common.repl
```

### Test Types

The test runner recognizes four types of tests:

1. **Main Tests (Required)**
   - A `main.repl` and/or a `main/` directory with .repl files
   - Contains integration tests demonstrating complete module workflows
   - Must be present and non-empty

2. **Auth Tests (Required unless module has no access control)**
   - A `auth.repl` and/or an `auth/` directory with .repl files
   - Tests access control, capabilities, signatures, etc.
   - Test runner does not enforce presence, but should be used for any module that uses capabilities, keysets, etc.

3. **Unit Tests (Required unless module is trivial)**
   - A `unit.repl` and/or a `unit/` directory with .repl files
   - Tests individual function behavior
   - Test runner does not enforce presence, but should be used for all non-trivial modules. Simple modules can just use main.repl.

4. **Gas Tests (Optional)**
   - Either `gas.repl` or a `gas/` directory with .repl files
   - Measures gas consumption of operations

For each test type, you can use either a single .repl file or a directory of .repl files. The main tests are required; all others are optional.

### Running Tests

The test runner provides several options for running tests:

```bash
# Run all tests for all modules
./run.sh

# Run tests for specific modules
./run.sh --module simple-staking,other-module

# Run specific test types
./run.sh --type unit,auth

# Run all tests except gas tests
./run.sh --exclude-type gas

# Run quietly (only show failures)
./run.sh --quiet
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
4. Gas tests (if present, run last due to verbosity)

The runner collects all failures and reports them at the end rather than stopping at the first failure.
