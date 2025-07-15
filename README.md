# VibeBridge

<div align="center">
  <img src="logo.png" alt="VibeBridge Logo" width="200"/>
</div>

A minimal Proof of Concept (PoC) CLI application that exposes Apple Foundation Models to the Internet. This project is currently a Work in Progress (WIP) exploring the integration of Apple's AI capabilities through a command-line interface.

## Overview

VibeBridge serves as a bridge between Apple's Foundation Models and external applications, providing a simple CLI interface to interact with Apple's AI models. The project is designed to be lightweight and focused on demonstrating the core functionality without extensive features.

## Features

- 🚀 Simple command-line interface
- 🤖 Apple Foundation Models integration
- 📝 Basic prompt processing
- 🔧 Error handling and logging
- 🧪 Unit tests

## Requirements

- macOS 26.0+
- Swift 5.9+
- Xcode 15.0+

## Compatibility & Support

⚠️ **Guarantee**: This software is guaranteed to work on my computer. Your mileage may vary! 

- ✅ **Tested on**: My MacBook (macOS Tahoe 26.0, Xcode 26 Beta 3)
- ❓ **Other platforms**: ¯\\_(ツ)_/¯
- 🎯 **Support policy**: "It works on my machine" - the classic developer guarantee
- 🐛 **Bug reports**: Will be met with "works fine here" until proven otherwise

## Installation

1. Clone the repository:
```bash
git clone https://github.com/crowdllama/vibebridge
cd vibebridge
```

2. Build the project:
```bash
swift build
```

3. Run the application:
```bash
swift run vibebridge "Your prompt here"
```

## Usage

### Basic Usage

```bash
# Simple prompt
swift run vibebridge "What is machine learning?"

# Multi-word prompt
swift run vibebridge "Explain the benefits of artificial intelligence in healthcare"
```

## Development

TBD

### Running Tests

```bash
swift test
```

### Adding Dependencies

Edit `Package.swift` to add external dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/example/package.git", from: "1.0.0")
],
targets: [
    .executableTarget(
        name: "VibeBridge",
        dependencies: ["PackageName"]
    )
]
```

## Status

⚠️ **Work in Progress**: This is a minimal PoC and should not be used in production. The project is actively being developed and may undergo significant changes.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple Foundation Models framework
- Swift Package Manager
- The Swift community 