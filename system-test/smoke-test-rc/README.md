# Acceptance Test Module

This module performs acceptance tests by downloading and using the published `optivem-test` package from external repositories.

## Purpose

This acceptance test module verifies that:
1. The `optivem-test` package can be successfully downloaded from Maven Central
2. The package can be downloaded from GitHub Packages (when configured)
3. The downloaded package's API works correctly from a consumer's perspective
4. All functionality is preserved in the published package

## Running Tests

### Test downloading from Maven Central
```bash
# Run the acceptance tests
./gradlew system-test:smoke-test-rc:test

# Verify dependencies can be resolved
./gradlew system-test:smoke-test-rc:verifyDependencies
```

### Test downloading from GitHub Packages

1. Set up environment variables:
```bash
export GITHUB_USERNAME=your-username
export GITHUB_READ_PACKAGES_TOKEN=your-personal-access-token
```

2. Uncomment the GitHub Packages repository in `build.gradle`:
```gradle
repositories {
    mavenCentral()
    
    maven {
        url = uri("https://maven.pkg.github.com/optivem/optivem-test-java")
        credentials {
            username = System.getenv("GITHUB_USERNAME")
            password = System.getenv("GITHUB_READ_PACKAGES_TOKEN")
        }
    }
}
```

3. Update the dependency version if needed:
```gradle
dependencies {
    testImplementation 'com.optivem:optivem-test:1.0.1' // or whatever version is in GitHub Packages
}
```

4. Run the tests:
```bash
./gradlew system-test:smoke-test-rc:test
```

## Test Structure

- `PackageDownloadIntegrationTest.java`: Main acceptance test that downloads and tests the package
  - Tests basic calculator operations
  - Tests edge cases (zero, negative numbers)
  - Tests error conditions (division by zero)

## Verification Tasks

- `verifyDependencies`: Checks that the optivem-test dependency is properly resolved and available in the classpath

## Notes

- The tests use the same API as the main library, ensuring compatibility
- Both Maven Central and GitHub Packages sources are supported
- The module is isolated from the main library build to simulate a real consumer experience