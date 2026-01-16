# Smoke Test Release Maven Central

This module contains smoke tests that verify the Maven Central release version of optivem-test library.

## Purpose

- Tests the published release version from Maven Central
- Ensures the library is correctly published and accessible
- Validates basic functionality of the released artifacts

## Running Tests

```bash
./gradlew system-test:smoke-test-release-mavencentral:test
```