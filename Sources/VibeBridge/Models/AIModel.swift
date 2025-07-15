import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(macOS 26.0, iOS 26.0, *)
struct AIModel {
    static func createSession(from transcript: Transcript) throws -> LanguageModelSession {
        Logger.debug("Creating session with default model and guardrails...")
        let session = LanguageModelSession.init(
            model: SystemLanguageModel.default,
            guardrails: LanguageModelSession.Guardrails.default,
            tools: [],
            transcript: transcript
        )
        Logger.debug("Session created successfully")
        return session
    }

    static func createTranscriptAndPrompt(from messages: [[String: Any]]) throws -> (Transcript, String) {
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
        
        var entries: [Transcript.Entry] = []
        
        let transcriptMessages = Array(messages.dropLast())
        Logger.debug("Processing \(transcriptMessages.count) transcript messages...")
        
        for (index, message) in transcriptMessages.enumerated() {
            guard let role = message["role"] as? String,
                  let content = message["content"] as? String else {
                Logger.warning("Skipping message \(index) - invalid format")
                continue
            }
            
            Logger.debug("Processing message \(index): role=\(role), content length=\(content.count)")
            
            let segment = Transcript.Segment.text(
                .init(content: content)
            )
            
            switch role {
            case "system":
                let instructions = Transcript.Instructions.init(segments: [segment], toolDefinitions: [])
                entries.append(.instructions(instructions))
                Logger.debug("Added system instructions")
            case "user":
                let prompt = Transcript.Prompt(segments: [segment])
                entries.append(.prompt(prompt))
                Logger.debug("Added user prompt")
            case "assistant":
                let response = Transcript.Response(assetIDs: [], segments: [segment])
                entries.append(.response(response))
                Logger.debug("Added assistant response")
            default:
                throw NSError(domain: "VibeBridge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid role: \(role)"])
            }
        }
        
        Logger.debug("Created transcript with \(entries.count) entries")
        return (Transcript(entries: entries), userPrompt)
    }

    static func createGenerationOptions(from options: [String: Any]) throws -> GenerationOptions {
        Logger.debug("Creating generation options from: \(options)")
        
        var temperature: Double?
        var maximumResponseTokens: Int?
        var samplingMode: GenerationOptions.SamplingMode = .greedy
        
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
        
        let generationOptions = GenerationOptions(
            sampling: samplingMode,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
        
        Logger.debug("Created generation options: \(generationOptions)")
        return generationOptions
    }
} 