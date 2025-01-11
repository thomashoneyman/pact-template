# Kadena Template

[![Contract Tests](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml/badge.svg)](https://github.com/thomashoneyman/pact-template/actions/workflows/pact.yaml)

A project template for writing smart contracts in the Pact language for use in the Kadena ecosystem. This template is a suitable starting point for new projects, providing:

* A smart contract and associated REPL files demonstrating best practices for testing
* Bootstrap REPL files which mimic the Chainweb environment for more realistic tests
* Continuous integration via GitHub workflows

## Installation

This repository includes a `.pact-version` file suitable for use with [pactup](https://github.com/kadena-community/pactup). The same Pact version is used in continuous integration. You only need Pact and a shell to use this repository.

## Running tests

The project includes a test runner script at [`contracts/tests/run.sh`](contracts/tests/run.sh) that can be used in several ways. Assuming you are in the tests directory:

```bash
# Run all tests (automatically excludes setup and bootstrap files)
./run.sh

# Run all tests for simple-staking module
./run.sh --module simple-staking

# Run only unit and gas tests for simple-staking
./run.sh --module simple-staking --type unit,gas

# Run all integration tests
./run.sh --type integration
```

## Structure

This template recommends a specific structure for your Pact code:

```
contracts/
├── interfaces/           # Interface definitions
     └── example.pact     # e.g., your-interface-v1
├── modules/              # Contract implementations
     ├── constants.pact   # Constant definitions for your modules
     ├── ns.pact          # Definition of your principal namespace
     └── example.pact     # e.g., your-module-v1
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
        └── your-module.repl  # Top-level integration/usage tests
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

## Test Organization

Each module should have a dedicated test directory with:

1. **setup.repl** - If needed, handles:
   - Loading module dependencies
   - Initializing module state
   - Creating test data/accounts
   - Any other test prerequisites

2. **gas.repl** - Measures gas consumption of key operations:
   - Critical path operations
   - Expensive computations
   - Common user interactions
   - Helps identify potential optimization needs

3. **auth.repl or auth/** - Ensures proper access control:
   - Tests all capability guards
   - Verifies admin-only functions
   - Checks user permission boundaries
   - Attempts unauthorized access
   - Validates signature requirements
   - One file for simple modules, multiple for complex ones.

4. **top level or unit/** - Individual function tests:
   - Validates expected behavior
   - Tests edge cases
   - Checks error conditions
   - Can be the top-level file for simple modules, or a directory with one test file per function for complex modules.

5. **top level** - Integration and usage examples:
   - Shows intended function workflow
   - Demonstrates typical user interactions
   - Tests interrelated functions
   - Provides usage documentation
   - For simple modules this can be the unit tests, with no separate directory

### Example Test Structure

```repl
;; auth.repl
(load "../bootstrap.repl")

(begin-tx)
(use base)

(expect-failure "Only admin can initialize"
  "Keyset failure"
  (your-module.initialize BOB_GUARD))

(expect "Admin can initialize"
  "Write succeeded"
  (your-module.initialize ADMIN_GUARD))
(commit-tx)

;; unit/stake.repl
(load "../bootstrap.repl")

(begin-tx)
(use base)

(expect "Can stake minimum amount"
  "Stake successful"
  (your-module.stake ALICE MIN_STAKE))

(expect-failure "Cannot stake below minimum"
  "Stake amount too low"
  (your-module.stake ALICE (- MIN_STAKE 0.1)))
(commit-tx)

;; your-module.repl
(load "bootstrap.repl")

(begin-tx)
(use base)

;; Show complete staking workflow
(your-module.stake ALICE 1000.0)
(expect "Stake recorded"
  1000.0
  (your-module.get-stake ALICE))

;; After lockup period
(chain-time (add-time (now) LOCKUP_PERIOD))
(your-module.unstake ALICE)
(expect "Stake released"
  0.0
  (your-module.get-stake ALICE))
(commit-tx)
```
