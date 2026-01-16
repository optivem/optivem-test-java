# System Tests

This module contains smoke tests for validating artifact availability from different sources.

## Test Modules

### GitHub Packages Tests
- **smoke-test-rc-github**: Tests RC versions from GitHub Packages
- **smoke-test-release-github**: Tests release versions from GitHub Packages

### Maven Central Tests  
- **smoke-test-rc-mavencentral**: Tests RC versions from Maven Central
- **smoke-test-release-mavencentral**: Tests release versions from Maven Central

## Usage

### Running all tests
```bash
./gradlew system-test:test
```

### Running specific source tests
```bash
# Test GitHub Packages availability
./gradlew system-test:smoke-test-rc-github:test
./gradlew system-test:smoke-test-release-github:test

# Test Maven Central availability (use specific version)
./gradlew system-test:smoke-test-rc-mavencentral:test -Pversion=1.0.5-rc.123
./gradlew system-test:smoke-test-release-mavencentral:test -Pversion=1.0.5
```

## Integration with CI/CD

### Immediate Testing (GitHub Packages)
- **acceptance-stage.yml**: Tests GitHub Packages immediately after publication
- Uses dynamic version resolution (latest RC/release)

### Delayed Testing (Maven Central) 
- **maven-central-verification.yml**: Tests Maven Central after propagation delay
- Uses event-driven triggers with configurable timing
- See [Maven Central Verification Documentation](../docs/maven-central-verification.md)

## Test Structure

Each test module:
1. Configures appropriate repository (GitHub Packages or Maven Central)
2. Resolves the target version of `com.optivem:optivem-test`
3. Runs a simple smoke test to verify the library loads correctly
4. Reports success/failure for CI/CD validation