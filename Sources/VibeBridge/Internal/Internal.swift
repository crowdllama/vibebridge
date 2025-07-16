import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct SupportedLanguageInfo: Codable {
    let languageCode: String
    let script: String?
    let region: String?
}

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
    
    /// Get supported languages from the default SystemLanguageModel
    /// Returns an array of SupportedLanguageInfo
    static func supportedLanguages() -> [SupportedLanguageInfo] {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            let model = SystemLanguageModel.default
            let languages = model.supportedLanguages
            
            var result: [SupportedLanguageInfo] = []
            for language in languages {
                let comps = Locale.Language.Components(language: language)
                let languageCode = comps.languageCode?.identifier ?? ""
                let script = comps.script?.identifier
                let region = comps.region?.identifier
                result.append(SupportedLanguageInfo(languageCode: languageCode, script: script, region: region))
            }
            return result
        } else {
            return []
        }
        #else
        return []
        #endif
    }
} 