import Foundation

// MARK: - Application Constants

struct Constants {
    
    // MARK: - AI Model Configuration
    
    struct Model {
        /// The name of the AI model used in API responses
        static let name = "apple"
        
        /// Default model ID for API responses
        static let id = "apple-intelligence"
        
        /// Default model description
        static let description = "Apple Intelligence powered by FoundationModels"
    }
    
    // MARK: - Server Configuration
    
    struct Server {
        /// Default port for the HTTP server
        static let defaultPort: UInt16 = 8080
        
        /// Request timeout in seconds
        static let requestTimeout: TimeInterval = 30.0
    }
    
    // MARK: - API Configuration
    
    struct API {
        /// Base path for API endpoints
        static let basePath = "/api"
        
        /// Health endpoint path
        static let healthPath = "/health"
        
        /// Models endpoint path
        static let modelsPath = "/tags"
        
        /// Chat endpoint path
        static let chatPath = "/chat"
    }
} 