# Optivem Test Java Library

[![Commit Stage](https://github.com/optivem/optivem-test-java/actions/workflows/commit-stage.yml/badge.svg)](https://github.com/optivem/optivem-test-java/actions/workflows/commit-stage.yml)
[![Acceptance Stage](https://github.com/optivem/optivem-test-java/actions/workflows/acceptance-stage.yml/badge.svg)](https://github.com/optivem/optivem-test-java/actions/workflows/acceptance-stage.yml)

A simple calculator library built with Java 21 and Gradle for testing and demonstration purposes.

## Features

- Basic arithmetic operations (add, subtract, multiply, divide)
- Comprehensive unit tests with JaCoCo coverage
- Automated CI/CD with GitHub Actions
- Maven publishing to GitHub Packages

## Usage

### Add as Dependency

#### Gradle
```gradle
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/optivem/optivem-test-java")
        credentials {
            username = project.findProperty("gpr.user") ?: System.getenv("USERNAME")
            password = project.findProperty("gpr.key") ?: System.getenv("TOKEN")
        }
    }
}

dependencies {
    implementation 'com.optivem:optivem-test:1.0.0'
}
```

#### Maven
```xml
<dependency>
    <groupId>com.optivem</groupId>
    <artifactId>optivem-test</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Code Example

```java
import com.optivem.calculator.CalculatorService;

public class Example {
    public static void main(String[] args) {
        CalculatorService calculator = new CalculatorService();
        
        double result = calculator.add(5.0, 3.0);
        System.out.println("5 + 3 = " + result); // Output: 5 + 3 = 8.0
        
        result = calculator.multiply(4.0, 2.5);
        System.out.println("4 * 2.5 = " + result); // Output: 4 * 2.5 = 10.0
    }
}
```

## Development

### Requirements
- Java 21 or higher
- Gradle 9.1.0 (included via wrapper)

### Building
```bash
./gradlew build
```

### Running Tests
```bash
./gradlew test
```

### Publishing Locally
```bash
./gradlew publishToMavenLocal
```

## Releasing

To create a new release:

1. Create and push a version tag:
```bash
git tag v1.1.0
git push origin v1.1.0
```

2. The GitHub Actions workflow will automatically:
   - Build and test the library
   - Publish to GitHub Packages
   - Create a GitHub release with artifacts

## API Documentation

### CalculatorService

The main calculator class with the following methods:

- `add(double a, double b)` - Returns the sum of two numbers
- `subtract(double a, double b)` - Returns the difference of two numbers  
- `multiply(double a, double b)` - Returns the product of two numbers
- `divide(double a, double b)` - Returns the quotient of two numbers
  - Throws `IllegalArgumentException` if divisor is zero

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
