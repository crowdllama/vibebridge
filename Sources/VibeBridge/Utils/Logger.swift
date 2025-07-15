import Foundation

struct Logger {
    static func info(_ message: String) {
        print("ℹ️ \(message)")
    }
    
    static func success(_ message: String) {
        print("✅ \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ \(message)")
    }
    
    static func warning(_ message: String) {
        print("⚠️ \(message)")
    }
    
    static func debug(_ message: String) {
        print("🔧 \(message)")
    }
    
    static func step(_ message: String) {
        print("🔄 \(message)")
    }
    
    static func model(_ message: String) {
        print("🤖 \(message)")
    }
    
    static func separator() {
        print(String(repeating: "=", count: 50))
    }
    
    static func section(_ message: String) {
        print("\n📋 \(message)")
        print(String(repeating: "-", count: 40))
    }
    
    static func details(_ message: String) {
        print("📊 \(message)")
    }
} 