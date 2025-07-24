# testscript - Script-driven Testing Library

[![Go Reference](https://pkg.go.dev/badge/github.com/gfanton/testscript.svg)](https://pkg.go.dev/github.com/gfanton/testscript)

`testscript` is a Go testing library for script-driven tests, heavily inspired by and adapted from the [testscript](https://pkg.go.dev/github.com/rogpeppe/go-internal/testscript) package originally developed by [Roger Peppe](https://github.com/rogpeppe). The library enables complex integration and system testing scenarios using `.tsar` files (testscript archive format).

The command-line tool is named `tsar` (short for "testscript archive"), while the project and library retain the name `testscript` to honor the original package.

## Features

- **Script-based Testing**: Define tests using simple script files with `.tsar` extension
- **Command-line Tool**: `tsar` command for running test scripts directly
- **Isolated Environments**: Each test runs in a fresh temporary directory
- **Custom Commands**: Register your own commands alongside built-in ones
- **Conditional Execution**: Support for platform-specific and conditional test execution
- **Archive Support**: Embed files directly in test scripts using txtar format
- **Environment Variables**: Full support for environment variable configuration
- **Extensible**: Easy to integrate with existing Go test suites

## Installation

### Library
```bash
go get github.com/gfanton/testscript
```

### Command-line Tool
```bash
go install github.com/gfanton/testscript/cmd/tsar@latest
```

## Quick Start

### 1. Create a test script file

Create a file `testdata/example.tsar`:

```bash
# Test basic file operations
mkdir testdir
cd testdir
echo "Hello World" > hello.txt

# Check that file exists and contains expected content
exists hello.txt
grep "Hello World" hello.txt

# Test with embedded archive data
-- input.txt --
This is test input data
for the archive section
-- expected.txt --
This is expected output
```

### 2. Write a Go test

```go
package mypackage

import (
    "testing"
    "github.com/gfanton/testscript"
)

func TestMyCommand(t *testing.T) {
    testscript.Run(t, testscript.Params{
        Dir: "testdata",
        Commands: map[string]func(*testscript.TestScript, bool, []string){
            "mycommand": handleMyCommand,
        },
    })
}

func handleMyCommand(ts *testscript.TestScript, neg bool, args []string) {
    // Your custom command implementation
    if len(args) < 2 {
        ts.Fatalf("usage: mycommand <arg>")
    }
    // ... implement your command logic
}
```

### 3. Run the tests

Using Go test:
```bash
go test
```

Using the `tsar` command:
```bash
tsar testdata/              # Run all .tsar files in directory
tsar testdata/example.tsar  # Run specific file
tsar --verbose testdata/    # Verbose output
```

## Usage

### Command-line Tool: `tsar`

The `tsar` command provides a standalone way to run test scripts without writing Go code:

```bash
# Run all .tsar files in a directory
tsar testdata/

# Run a specific test file
tsar testdata/mytest.tsar

# Command-line flags
tsar --verbose testdata/         # Enable verbose output
tsar --short testdata/           # Run tests in short mode
tsar --test-work testdata/       # Preserve work directories
tsar --workdir-root /tmp testdata/  # Custom work directory root

# Environment variables (with TSAR_ prefix)
TSAR_VERBOSE=true tsar testdata/
TSAR_TEST_WORK=true tsar testdata/
TSAR_WORKDIR_ROOT=/tmp tsar testdata/
```

Available flags:
- `-v, --verbose`: Enable verbose output
- `-s, --short`: Run tests in short mode
- `--test-work`: Preserve work directories after tests
- `-w, --workdir-root`: Root directory for work directories
- `-c, --continue-on-error`: Continue executing tests after an error
- `-e, --require-explicit-exec`: Require explicit 'exec' for command execution
- `-u, --require-unique-names`: Require unique test names

### Basic API

The main entry point is `testscript.Run()`:

```go
testscript.Run(t, testscript.Params{
    Dir: "testdata",           // Directory containing .tsar files
    Commands: customCommands,   // Your custom commands
    TestWork: false,           // Keep work directories after tests
    Setup: setupFunc,          // Optional setup function
    Condition: conditionFunc,  // Custom condition evaluator
})
```

### Custom Commands

Register custom commands by providing a map of command names to handler functions:

```go
commands := map[string]func(*testscript.TestScript, bool, []string){
    "echo": func(ts *testscript.TestScript, neg bool, args []string) {
        // Implementation for 'echo' command
        if len(args) < 2 {
            ts.Fatalf("usage: echo text...")
        }
        // Your echo implementation here
    },
}
```

### Built-in Commands

The library provides several built-in commands:

- `cd <dir>` - Change directory
- `mkdir <dir>...` - Create directories
- `rm <file>...` - Remove files/directories
- `exists <file>` - Check if file exists
- `env <key>=<value>` - Set environment variable
- `exec <cmd> <args>...` - Execute external command
- `grep <pattern> <file>` - Search for pattern in file
- `skip [message]` - Skip the test
- `stop` - Stop test execution
- `wait` - Wait for background commands

### Conditional Execution

Use conditions to run commands only under certain circumstances:

```bash
[!windows] mkdir unix-only-dir
[short] skip "skipping in short mode"
[!short] exec long-running-command
```

Built-in conditions:
- `short` - Running with `go test -short`
- `windows`, `darwin`, `linux` - Operating system
- `!condition` - Negation of any condition

### Archive Support

Embed files directly in your test scripts:

```bash
# Your test commands here
mkdir testdata

-- testdata/input.txt --
This content will be written to testdata/input.txt
when the test runs.

-- testdata/config.json --
{
    "key": "value"
}
```

### TestScript API

Within custom commands, you have access to the `TestScript` context:

```go
func myCommand(ts *testscript.TestScript, neg bool, args []string) {
    // File operations
    content := ts.ReadFile("somefile.txt")
    
    // Environment
    workDir := ts.Getenv("WORK")
    ts.Setenv("MYVAR", "value")
    
    // Directory operations
    ts.Chdir("subdir")
    
    // Logging and errors
    ts.Logf("Processing %d items", len(args))
    if someError {
        ts.Fatalf("command failed: %v", err)
    }
    
    // Execute external commands
    if err := ts.Exec("go", "version"); err != nil {
        ts.Fatalf("go command failed: %v", err)
    }
}
```

## Examples

See the [`examples/`](examples/) directory for complete working examples:

- [Basic usage](examples/basic_test.go) - Simple custom commands
- [Integration example](examples/testdata/) - Real-world test scenarios

### Example: Using the `tsar` command

Create a test file `hello.tsar`:
```bash
# Create a simple Go program
mkdir hello
cd hello

-- go.mod --
module hello

go 1.21

-- main.go --
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}

# Test that files were created
exists go.mod
exists main.go

# Run the program (if exec is enabled)
[!short] exec go run main.go
[!short] stdout 'Hello, World!'
```

Run it with:
```bash
tsar hello.tsar          # Basic execution
tsar -v hello.tsar       # Verbose output
tsar --test-work hello.tsar  # Keep work directory for inspection
```

## Integration Examples

This library is designed to be used for integration testing where you need to:

- Test command-line tools with complex scenarios
- Verify file system operations and outputs
- Run tests in isolated, reproducible environments
- Combine multiple commands and assertions in a single test

The `.tsar` format allows you to define both the test steps and any required test files in a single, readable script.

## Attribution

This library is heavily inspired by and adapted from the [testscript](https://pkg.go.dev/github.com/rogpeppe/go-internal/testscript) package:

- **Original Author**: [Roger Peppe](https://github.com/rogpeppe) <rogpeppe@gmail.com>
- **Original Package**: https://pkg.go.dev/github.com/rogpeppe/go-internal/testscript
- **License**: Original testscript package license applies

The core design patterns, API structure, and implementation approach have been preserved while adapting the functionality to work with `.tsar` files and custom command registration.

## Dependencies

- `golang.org/x/tools/txtar` - For parsing embedded archive sections in test scripts

## License

This project maintains compatibility with the original testscript package licensing. See the original package for license details.

## Contributing

Contributions are welcome! Please ensure that:

1. New features maintain compatibility with the testscript API where applicable
2. Tests are provided for new functionality
3. Documentation is updated accordingly
4. Proper attribution to original authors is maintained