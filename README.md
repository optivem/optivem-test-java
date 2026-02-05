# Optivem Testing Java Library

[![Commit Stage](https://github.com/optivem/optivem-testing-java/actions/workflows/commit-stage.yml/badge.svg)](https://github.com/optivem/optivem-testing-java/actions/workflows/commit-stage.yml)
[![Acceptance Stage](https://github.com/optivem/optivem-testing-java/actions/workflows/acceptance-stage.yml/badge.svg)](https://github.com/optivem/optivem-testing-java/actions/workflows/acceptance-stage.yml)
[![Release Stage](https://github.com/optivem/optivem-testing-java/actions/workflows/release-stage.yml/badge.svg)](https://github.com/optivem/optivem-testing-java/actions/workflows/release-stage.yml)

A testing library to support Acceptance Testing in Java.

## Usage

### Add as Dependency

The library is available on Maven Central https://mvnrepository.com/artifact/com.optivem/optivem-testing

#### Gradle
```gradle
dependencies {
    implementation 'com.optivem:optivem-testing:1.0.3'
}
```

#### Maven
```xml
<dependency>
    <groupId>com.optivem</groupId>
    <artifactId>optivem-testing</artifactId>
    <version>1.0.3</version>
</dependency>
```

### Code Example

```java
import com.optivem.testing.Channel;

public class Example {
    public static void main(String[] args) {
        Channel channel = new Channel("test-channel");
        
        String name = channel.getName();
        System.out.println("Channel name: " + name);  // Output: test-channel
    }
}
```

## Development

### Requirements
- Java 21 or higher
- Gradle 9.1.0 (included via wrapper)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
