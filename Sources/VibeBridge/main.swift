import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct VibeBridge {
    static func main() async {
        Logger.info("VibeBridge - Apple Foundation Models CLI")
        Logger.separator()
        
        // Parse command line arguments
        let arguments = CommandLine.arguments.dropFirst()
        
        if arguments.isEmpty {
            Logger.info("Usage: vibebridge <prompt>")
            Logger.info("Example: vibebridge 'What is machine learning?'")
            return
        }
        
        let userPrompt = arguments.joined(separator: " ")
        
#if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            await runAppleFoundationModelsDemo(prompt: userPrompt)
        } else {
            Logger.error("Apple Intelligence requires macOS 26.0 or iOS 26.0 or later")
        }
#else
        Logger.error("FoundationModels framework not available")
#endif
        
        Logger.separator()
        Logger.success("VibeBridge completed!")
    }
    
    @available(macOS 26.0, iOS 26.0, *)
    static func runAppleFoundationModelsDemo(prompt: String) async {
        // Declare variables outside try block so they're accessible in catch blocks
        var userPrompt: String = prompt
        var generationOptions: GenerationOptions!
        var session: LanguageModelSession!
        var transcript: Transcript!
        
        do {
            Logger.success("Apple Intelligence model is available")
            Logger.details("Model availability: \(SystemLanguageModel.default.availability)")
            
            // Create a simple user message
            let messages: [[String: Any]] = [
                ["role": "user", "content": prompt]
            ]
            
            Logger.details("Messages: \(messages)")
            
            // Create transcript and prompt
            Logger.step("Creating transcript and prompt...")
            let (transcriptResult, prompt) = try AIModel.createTranscriptAndPrompt(from: messages)
            transcript = transcriptResult
            userPrompt = prompt
            Logger.success("Successfully created transcript and prompt")
            Logger.details("User prompt: \(userPrompt)")
            
            // Create session
            Logger.step("Creating language model session...")
            session = try AIModel.createSession(from: transcript)
            Logger.success("Successfully created language model session")
            
            // Create generation options
            Logger.step("Creating generation options...")
            generationOptions = try AIModel.createGenerationOptions(from: [:])
            Logger.success("Successfully created generation options")
            
            Logger.details("Sending prompt: \(userPrompt)")
            Logger.step("About to call session.respond...")
            
            // Generate response
            let response = try await session.respond(to: userPrompt, options: generationOptions)
            
            Logger.section("Model Response")
            Logger.model(response.content)
            Logger.success("Text generation completed successfully!")
            
        } catch let generationError as LanguageModelSession.GenerationError {
            Logger.section("GenerationError Details")
            Logger.error("GenerationError Code: \(generationError)")
            Logger.error("GenerationError Localized Description: \(generationError.localizedDescription)")
            
            // Log the objects that were created before the error
            Logger.section("Objects Before Error")
            Logger.details("User Prompt: \(userPrompt)")
            if let options = generationOptions {
                Logger.details("Generation Options: \(options)")
            }
            
            Logger.section("Debug Information")
            Logger.details("Model Availability: \(SystemLanguageModel.default.availability)")
            if let session = session {
                Logger.details("Session Created: Yes")
            } else {
                Logger.details("Session Created: No")
            }
            if let transcript = transcript {
                Logger.details("Transcript Created: Yes")
            } else {
                Logger.details("Transcript Created: No")
            }
            
        } catch let nsError as NSError {
            Logger.section("NSError Details")
            Logger.error("Error Domain: \(nsError.domain)")
            Logger.error("Error Code: \(nsError.code)")
            Logger.error("Error Description: \(nsError.localizedDescription)")
            Logger.error("Error User Info: \(nsError.userInfo)")
            
            // Log the objects that were created before the error
            Logger.section("Objects Before Error")
            Logger.details("User Prompt: \(userPrompt)")
            if let options = generationOptions {
                Logger.details("Generation Options: \(options)")
            }
            
        } catch {
            Logger.section("Unexpected Error Details")
            Logger.error("Error Type: \(type(of: error))")
            Logger.error("Error Description: \(error.localizedDescription)")
            Logger.error("Error Details: \(error)")
            
            // Log the objects that were created before the error
            Logger.section("Objects Before Error")
            Logger.details("User Prompt: \(userPrompt)")
            if let options = generationOptions {
                Logger.details("Generation Options: \(options)")
            }
        }
    }

}

// Main entry point
let task = Task {
    await VibeBridge.main()
}
await task.value