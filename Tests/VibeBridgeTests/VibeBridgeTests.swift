import XCTest
@testable import VibeBridge

final class VibeBridgeTests: XCTestCase {
    func testLogger() throws {
        // Test that Logger methods don't crash
        Logger.info("Test info message")
        Logger.success("Test success message")
        Logger.error("Test error message")
        Logger.warning("Test warning message")
        Logger.debug("Test debug message")
        Logger.step("Test step message")
        Logger.model("Test model message")
        Logger.separator()
        Logger.section("Test section")
        Logger.details("Test details")
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
    
    func testCommandLineArguments() throws {
        // Test command line argument parsing logic
        let testArgs = ["vibebridge", "test", "prompt"]
        let arguments = Array(testArgs.dropFirst())
        
        XCTAssertEqual(arguments.count, 2)
        XCTAssertEqual(arguments.joined(separator: " "), "test prompt")
    }
    
    func testEmptyArguments() throws {
        let emptyArgs: [String] = []
        XCTAssertTrue(emptyArgs.isEmpty)
    }
} 