import XCTest
@testable import VibeBridge

final class HTTPServerTests: XCTestCase {
    var server: HTTPServer!
    var testPort: UInt16 = 8081
    
    override func setUp() {
        server = HTTPServer()
        server.setup()
    }
    
    override func tearDown() {
        server.stop()
    }
    
    func testHealthEndpoint() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Health endpoint test")
        
        let url = URL(string: "http://localhost:\(testPort)/health")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200)
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                XCTAssertEqual(json["status"], "healthy")
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testModelsEndpoint() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Models endpoint test")
        
        let url = URL(string: "http://localhost:\(testPort)/api/tags")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200)
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]],
               let firstModel = models.first {
                XCTAssertEqual(firstModel["name"] as? String, "apple")
                XCTAssertEqual(firstModel["id"] as? String, "apple-intelligence")
                XCTAssertNotNil(firstModel["description"])
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testChatEndpointWithSimpleLLMPrompt() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Chat endpoint with simple LLM prompt test")
        
        let requestBody = ChatRequest(
            model: "apple",
            messages: [
                ChatRequest.Message(role: "user", content: "1+1")
            ],
            stream: false,
            temperature: nil,
            maxTokens: nil,
            topP: nil,
            topK: nil
        )
        
        let url = URL(string: "http://localhost:\(testPort)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200)
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Validate response structure without checking the actual LLM answer
                XCTAssertEqual(json["model"] as? String, "apple")
                XCTAssertNotNil(json["created_at"])
                XCTAssertNotNil(json["message"])
                
                if let message = json["message"] as? [String: Any] {
                    XCTAssertEqual(message["role"] as? String, "assistant")
                    XCTAssertNotNil(message["content"])
                    // Don't validate the actual content - just ensure it exists
                }
                
                XCTAssertEqual(json["done_reason"] as? String, "stop")
                XCTAssertEqual(json["done"] as? Bool, true)
                XCTAssertGreaterThan(json["total_duration"] as? Int64 ?? 0, 0)
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 30.0) // Increased timeout for LLM processing
    }
    
    func testChatEndpointWithInvalidModel() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Invalid model test")
        
        let requestBody = ChatRequest(
            model: "llama3.2",
            messages: [
                ChatRequest.Message(role: "user", content: "Hello")
            ],
            stream: false,
            temperature: nil,
            maxTokens: nil,
            topP: nil,
            topK: nil
        )
        
        let url = URL(string: "http://localhost:\(testPort)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 400)
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testChatEndpointWithEmptyMessages() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Empty messages test")
        
        let requestBody = ChatRequest(
            model: "apple",
            messages: [],
            stream: false,
            temperature: nil,
            maxTokens: nil,
            topP: nil,
            topK: nil
        )
        
        let url = URL(string: "http://localhost:\(testPort)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 400)
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testChatEndpointWithNonUserLastMessage() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Non-user last message test")
        
        let requestBody = ChatRequest(
            model: "apple",
            messages: [
                ChatRequest.Message(role: "assistant", content: "Hello")
            ],
            stream: false,
            temperature: nil,
            maxTokens: nil,
            topP: nil,
            topK: nil
        )
        
        let url = URL(string: "http://localhost:\(testPort)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 400)
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testChatEndpointWithInvalidJSON() throws {
        try server.start(port: testPort)
        defer { server.stop() }
        
        let expectation = XCTestExpectation(description: "Invalid JSON test")
        
        let url = URL(string: "http://localhost:\(testPort)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "invalid json".data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            XCTAssertNil(error)
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 400)
            }
        }
        
        task.resume()
        wait(for: [expectation], timeout: 5.0)
    }
} 