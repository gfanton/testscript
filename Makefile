# Makefile for tstar project

.PHONY: all build test clean lint fmt vet mod-tidy help

# Default target
all: fmt vet test

# Build the project
build:
	@echo "Building..."
	@go build ./...

# Run tests
test:
	@echo "Running tests..."
	@go test -v ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@go test -v -race -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run benchmarks
bench:
	@echo "Running benchmarks..."
	@go test -bench=. -benchmem ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@go clean
	@rm -f coverage.out coverage.html

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	@golangci-lint run

# Install golangci-lint if not present
install-lint:
	@which golangci-lint > /dev/null || { \
		echo "Installing golangci-lint..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.54.2; \
	}

# Vet code
vet:
	@echo "Vetting code..."
	@go vet ./...

# Tidy modules
mod-tidy:
	@echo "Tidying modules..."
	@go mod tidy

# Check for security issues
sec:
	@echo "Checking for security issues..."
	@gosec ./...

# Install gosec if not present
install-sec:
	@which gosec > /dev/null || { \
		echo "Installing gosec..."; \
		go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest; \
	}

# Run all checks (fmt, vet, lint, test)
check: fmt vet lint test

# Install development tools
install-tools: install-lint install-sec
	@echo "All development tools installed"

# Run tests in short mode
test-short:
	@echo "Running tests in short mode..."
	@go test -short ./...

# Show help
help:
	@echo "Available targets:"
	@echo "  all           - Run fmt, vet, and test (default)"
	@echo "  build         - Build the project"
	@echo "  test          - Run all tests"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  test-short    - Run tests in short mode"
	@echo "  bench         - Run benchmarks"
	@echo "  clean         - Clean build artifacts"
	@echo "  fmt           - Format code"
	@echo "  lint          - Lint code (requires golangci-lint)"
	@echo "  vet           - Vet code"
	@echo "  mod-tidy      - Tidy Go modules"
	@echo "  sec           - Check for security issues (requires gosec)"
	@echo "  check         - Run fmt, vet, lint, and test"
	@echo "  install-tools - Install development tools"
	@echo "  install-lint  - Install golangci-lint"
	@echo "  install-sec   - Install gosec"
	@echo "  help          - Show this help message"