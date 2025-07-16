import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Data Models

struct AIModel: Codable {
    let model: String
    let name: String
    let contextLength: Int?
    let pricing: Pricing?
    let size: Int
    let details: [String: String]
    
    struct Pricing: Codable {
        let input: Double?
        let output: Double?
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool?
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let topK: Int?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let topK: Int?
}

struct ChatResponse: Codable {
    let model: String
    let created_at: String
    let message: ChatRequest.Message
    let done_reason: String
    let done: Bool
    let total_duration: Int64
    let load_duration: Int64?
    let prompt_eval_count: Int?
    let prompt_eval_duration: Int64?
    let eval_count: Int?
    let eval_duration: Int64?
}

struct ModelResponse: Codable {
    let models: [AIModel]
}

// MARK: - AI Model Integration

@available(macOS 26.0, iOS 26.0, *)
struct AIModelHandler {
    static func createSession(from transcript: FoundationModels.Transcript) throws -> FoundationModels.LanguageModelSession {
        Logger.debug("Creating session with default model and guardrails...")
        let session = FoundationModels.LanguageModelSession.init(
            model: FoundationModels.SystemLanguageModel.default,
            guardrails: FoundationModels.LanguageModelSession.Guardrails.default,
            tools: [],
            transcript: transcript
        )
        Logger.debug("Session created successfully")
        return session
    }

    static func createTranscriptAndPrompt(from messages: [[String: Any]]) throws -> (FoundationModels.Transcript, String) {
        Logger.debug("Creating transcript from \(messages.count) messages...")
        
        guard !messages.isEmpty else {
            throw NSError(domain: "VibeBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Messages array cannot be empty"])
        }
        
        guard let lastMessage = messages.last,
              let lastRole = lastMessage["role"] as? String,
              let userPrompt = lastMessage["content"] as? String,
              lastRole == "user" else {
            throw NSError(domain: "VibeBridge", code: 2, userInfo: [NSLocalizedDescriptionKey: "Last message must be from user role"])
        }
        
        var entries: [FoundationModels.Transcript.Entry] = []
        
        let transcriptMessages = Array(messages.dropLast())
        Logger.debug("Processing \(transcriptMessages.count) transcript messages...")
        
        for (index, message) in transcriptMessages.enumerated() {
            guard let role = message["role"] as? String,
                  let content = message["content"] as? String else {
                Logger.warning("Skipping message \(index) - invalid format")
                continue
            }
            
            Logger.debug("Processing message \(index): role=\(role), content length=\(content.count)")
            
            let segment = FoundationModels.Transcript.Segment.text(
                .init(content: content)
            )
            
            switch role {
            case "system":
                let instructions = FoundationModels.Transcript.Instructions.init(segments: [segment], toolDefinitions: [])
                entries.append(.instructions(instructions))
                Logger.debug("Added system instructions")
            case "user":
                let prompt = FoundationModels.Transcript.Prompt(segments: [segment])
                entries.append(.prompt(prompt))
                Logger.debug("Added user prompt")
            case "assistant":
                let response = FoundationModels.Transcript.Response(assetIDs: [], segments: [segment])
                entries.append(.response(response))
                Logger.debug("Added assistant response")
            default:
                throw NSError(domain: "VibeBridge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid role: \(role)"])
            }
        }
        
        Logger.debug("Created transcript with \(entries.count) entries")
        return (FoundationModels.Transcript(entries: entries), userPrompt)
    }

    static func createGenerationOptions(from options: [String: Any]) throws -> FoundationModels.GenerationOptions {
        Logger.debug("Creating generation options from: \(options)")
        
        var temperature: Double?
        var maximumResponseTokens: Int?
        var samplingMode: FoundationModels.GenerationOptions.SamplingMode = .greedy
        
        if let temp = options["temperature"] as? Double {
            temperature = temp
            Logger.debug("Set temperature to: \(temp)")
        }
        
        if let maxTokens = options["maxTokens"] as? Int {
            maximumResponseTokens = maxTokens
            Logger.debug("Set max tokens to: \(maxTokens)")
        }
        
        let topP = options["topP"] as? Double
        let topK = options["topK"] as? Int
        
        if topP != nil && topK != nil {
            throw NSError(domain: "VibeBridge", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot use both topP and topK"])
        }
        
        if let topP {
            samplingMode = .random(probabilityThreshold: topP)
            Logger.debug("Set sampling mode to random with topP: \(topP)")
        } else if let topK {
            samplingMode = .random(top: topK)
            Logger.debug("Set sampling mode to random with topK: \(topK)")
        } else {
            Logger.debug("Using default greedy sampling mode")
        }
        
        let generationOptions = FoundationModels.GenerationOptions(
            sampling: samplingMode,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
        
        Logger.debug("Created generation options: \(generationOptions)")
        return generationOptions
    }
    
    static func generateResponse(for request: ChatRequest) async throws -> String {
        Logger.info("Generating AI response for chat request")
        
        // Convert messages to the format expected by AIModelHandler
        let messages: [[String: Any]] = request.messages.map { message in
            ["role": message.role, "content": message.content]
        }
        
        // Create generation options
        var options: [String: Any] = [:]
        if let temperature = request.temperature {
            options["temperature"] = temperature
        }
        if let maxTokens = request.maxTokens {
            options["maxTokens"] = maxTokens
        }
        if let topP = request.topP {
            options["topP"] = topP
        }
        if let topK = request.topK {
            options["topK"] = topK
        }
        
        // Create transcript and prompt
        let (transcript, userPrompt) = try createTranscriptAndPrompt(from: messages)
        
        // Create session
        let session = try createSession(from: transcript)
        
        // Create generation options
        let generationOptions = try createGenerationOptions(from: options)
        
        Logger.debug("Sending prompt: \(userPrompt)")
        
        // Generate response
        let response = try await session.respond(to: userPrompt, options: generationOptions)
        
        Logger.success("AI response generated successfully")
        return response.content
    }
    
    static func generateResponse(for request: GenerateRequest) async throws -> String {
        Logger.info("Generating AI response for generate request")
        
        // Create generation options
        var options: [String: Any] = [:]
        if let temperature = request.temperature {
            options["temperature"] = temperature
        }
        if let maxTokens = request.maxTokens {
            options["maxTokens"] = maxTokens
        }
        if let topP = request.topP {
            options["topP"] = topP
        }
        if let topK = request.topK {
            options["topK"] = topK
        }
        
        // Create empty transcript and use the prompt directly
        let transcript = FoundationModels.Transcript(entries: [])
        let userPrompt = request.prompt
        
        // Create session
        let session = try createSession(from: transcript)
        
        // Create generation options
        let generationOptions = try createGenerationOptions(from: options)
        
        Logger.debug("Sending prompt: \(userPrompt)")
        
        // Generate response
        let response = try await session.respond(to: userPrompt, options: generationOptions)
        
        Logger.success("AI response generated successfully")
        return response.content
    }
} 