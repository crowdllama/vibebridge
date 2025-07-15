import Foundation
import Swifter

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