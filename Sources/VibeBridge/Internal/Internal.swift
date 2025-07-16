import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Internal Apple Foundation Functions

struct Internal {
    
    /// Check if Apple Foundation Models are available
    /// Returns true if FoundationModels framework is available and SystemLanguageModel is accessible
    static func isAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }
} 