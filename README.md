<div align="center">
  <img src="logo.png" alt="VibeBridge Logo" width="200"/>
</div>

# VibeBridge

**Expose Apple Foundation Models as an Internet Server**

VibeBridge is a Swift-based HTTP server that exposes Apple's Foundation Models to the Internet, providing a REST API interface for LLM model interactions. This project bridges the gap between Apple's local AI capabilities and web-based applications, allowing you to serve LLM responses over HTTP. This is a proof-of-concept (PoC) to explore making AI models accessible on the Internet and potentially through a P2P network like [crowdllama](https://github.com/crowdllama/crowdllama).

[Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels) are part of [Apple Intelligence](https://www.apple.com/apple-intelligence/), Apple's on-device AI system. These are offline, local language models that run directly on Apple devices including iPhones, iPads, and Macs. They provide powerful AI capabilities while maintaining privacy by keeping all processing on-device, with no data sent to external servers.

## Overview

VibeBridge transforms Apple's Foundation Models into a web service, making it possible to:
- **Serve LLM responses over HTTP** - Access Apple's AI models from any web application
- **Ollama-compatible API** - Use the same API format as Ollama for easy integration
- **Local AI with web accessibility** - Keep your AI processing local while exposing it to the internet
- **Simple deployment** - Single binary that runs as a web server

The project is designed to be lightweight and focused on providing a reliable bridge between Apple's local AI capabilities and internet-accessible applications.

## Requirements

- macOS 26.0+
- Swift 5.9+
- Xcode 15.0+ - currently using [Xcode 26 Beta 3](https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes)

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

3. Run the server:
```bash
# Using swift run
swift run

# Or using the built binary
.build/debug/VibeBridge
```

## Usage

### Starting the Server

The server starts automatically on `http://localhost:8080`:

```bash
# Build and run
swift build
.build/debug/VibeBridge

# Or use swift run
swift run
```

### HTTP API Endpoints

#### Chat API (Ollama Compatible)

The main endpoint for AI interactions:

**Request Parameters:**
- `model` (string, required): The model to use (e.g., "apple").
- `messages` (array, required): Conversation history, each with `role` and `content`.
- `stream` (bool, optional): Whether to stream responses.
- `temperature` (number, optional): Controls randomness of the output. Lower values (e.g., 0.1) make responses more deterministic, higher values (e.g., 1.0) make them more random. Default is model-dependent.
- `maxTokens` (integer, optional): The maximum number of tokens in the generated response. Useful for limiting response length. Default is model-dependent.

**Example Request:**
```bash
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "apple",
    "messages": [
      {
        "role": "user",
        "content": "Why is the sky blue?"
      }
    ],
    "stream": false,
    "temperature": 0.7,
    "maxTokens": 256
  }'
```

**Response:**
```json
{
  "model": "apple",
  "created_at": "2025-07-15T21:19:22.573141Z",
  "message": {
    "role": "assistant",
    "content": "The sky appears blue due to a phenomenon called Rayleigh scattering..."
  },
  "done_reason": "stop",
  "done": true,
  "total_duration": 4144050458,
  "load_duration": null,
  "prompt_eval_count": null,
  "prompt_eval_duration": null,
  "eval_count": null,
  "eval_duration": null
}
```

#### Generate API

A simpler endpoint for single-prompt generation:

**Request Parameters:**
- `model` (string, required): The model to use (e.g., "apple").
- `prompt` (string, required): The text prompt to generate a response for.
- `temperature` (number, optional): Controls randomness of the output. Lower values (e.g., 0.1) make responses more deterministic, higher values (e.g., 1.0) make them more random. Default is model-dependent.
- `maxTokens` (integer, optional): The maximum number of tokens in the generated response. Useful for limiting response length. Default is model-dependent.

**Example Request:**
```bash
curl -X POST http://localhost:8080/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "apple",
    "prompt": "Is the sky blue?",
    "temperature": 0.7,
    "maxTokens": 256
  }'
```

**Response:**
```json
{
  "model": "apple",
  "created_at": "2025-07-15T21:19:22.573141Z",
  "response": "Yes, the sky appears blue due to Rayleigh scattering...",
  "done_reason": "stop",
  "done": true,
  "total_duration": 4144050458
}
```

#### Internal Endpoints

Internal endpoints provide access to Apple Foundation Models' internal functions and capabilities that aren't part of the standard Ollama-compatible API. These endpoints are useful for debugging, monitoring, and accessing advanced Apple-specific features.

**Reasoning:**
- **Debugging**: Check if Foundation Models are available and working
- **Monitoring**: Verify system capabilities and health
- **Development**: Access Apple-specific features not available in standard APIs
- **Integration**: Test compatibility with different Apple devices and OS versions

##### Foundation Models Availability

Check if Apple Foundation Models are available on the current system:

**Request:**
```bash
curl http://localhost:8080/internal/isAvailable
```

**Response:**
```json
{
  "isAvailable": true
}
```

**Response (when not available):**
```json
{
  "isAvailable": false
}
```

**Use Cases:**
- Verify Foundation Models framework is installed
- Check OS version compatibility (macOS 26.0+ / iOS 26.0+)
- Test system readiness before making AI requests
- Debug installation or configuration issues

#### Health Check

```bash
curl http://localhost:8080/health
```

**Response:**
```json
{"status":"healthy"}
```

#### Model Information

```bash
curl http://localhost:8080/api/tags
```

**Response:**
```json
{
  "models": [
    {
      "id": "apple-intelligence",
      "name": "apple",
      "description": "Apple Intelligence powered by FoundationModels",
      "context_length": 8192
    }
  ]
}
```

## Status

⚠️ **Work in Progress**: This is a functional PoC that successfully exposes Foundation Models as an HTTP server. The project is actively being developed and may undergo significant changes.

## Reference Documentation

- [Generating Content and Performing Tasks with Foundation Models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)
- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
