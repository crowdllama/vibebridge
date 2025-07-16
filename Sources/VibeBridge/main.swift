import Foundation
import Swifter

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Global Variables

var globalServer: HTTPServer?

// MARK: - Signal Handler

func signalHandler(_ signal: Int32) {
    print("\nShutting down server...")
    globalServer?.stop()
    exit(0)
}

// MARK: - Main Entry Point

@main
struct Main {
    static func main() {
        // Check FoundationModels availability
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            print("FoundationModels.SystemLanguageModel.isAvailable: true (framework and OS version supported)")
        } else {
            print("FoundationModels.SystemLanguageModel.isAvailable: false (requires macOS 26.0 or iOS 26.0)")
        }
        #else
        print("FoundationModels.SystemLanguageModel.isAvailable: false (FoundationModels framework not available)")
        #endif
        
        let server = HTTPServer()
        server.setup()
        globalServer = server
        
        // Handle graceful shutdown
        signal(SIGINT, signalHandler)
        
        print("Server running on http://localhost:\(Constants.Server.defaultPort)")
        
        // Start the server and keep it running
        do {
            try server.start(port: Constants.Server.defaultPort)
            
            // Keep the main thread alive
            RunLoop.main.run()
        } catch {
            print("Failed to start server: \(error)")
            exit(1)
        }
    }
} 