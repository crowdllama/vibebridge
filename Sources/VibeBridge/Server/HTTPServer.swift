import Foundation
import Swifter

// MARK: - HTTP Server with Swifter

class HTTPServer {
    private var server: HttpServer?
    
    func setup() {
        let server = HttpServer()
        
        // Root endpoint
        server.GET["/"] = { request in
            return HttpResponse.ok(.text("VibeBridge API is running!"))
        }
        
        // Health endpoint
        server.GET["/health"] = { request in
            let response = ["status": "healthy"]
            return HttpResponse.ok(.json(response))
        }
        
        // Model endpoint (Ollama-like)
        server.GET["/api/tags"] = { request in
            let model = AIModel(
                id: Constants.Model.id,
                name: Constants.Model.name,
                description: Constants.Model.description,
                contextLength: 8192,
                pricing: nil
            )
            
            let modelResponse = ModelResponse(models: [model])
            
            do {
                let data = try JSONEncoder().encode(modelResponse)
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"], { writer in
                    try writer.write(data)
                })
            } catch {
                let errorResponse = ["error": "Failed to serialize model response"]
                let data = try? JSONSerialization.data(withJSONObject: errorResponse, options: [])
                return HttpResponse.raw(500, "Internal Server Error", ["Content-Type": "application/json"], { writer in
                    if let data = data {
                        try writer.write(data)
                    }
                })
            }
        }
        
        // Chat endpoint
        server.POST["/api/chat"] = { request in
            do {
                // Record start time when request arrives
                let startTime = DispatchTime.now()
                
                // Parse the request body
                let body = request.body
                let jsonString = String(bytes: body, encoding: .utf8) ?? ""
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    let errorResponse: [String: Any] = [
                        "error": "Invalid request body encoding"
                    ]
                    return HttpResponse.badRequest(.json(errorResponse))
                }
                
                let chatRequest = try JSONDecoder().decode(ChatRequest.self, from: jsonData)
                
                // Validate that the requested model matches our available model
                guard chatRequest.model == Constants.Model.name else {
                    let errorResponse: [String: Any] = [
                        "error": "model \"\(chatRequest.model)\" not found, try pulling it first"
                    ]
                    return HttpResponse.badRequest(.json(errorResponse))
                }
                
                // Check if FoundationModels is available
                #if canImport(FoundationModels)
                if #available(macOS 26.0, iOS 26.0, *) {
                    // Use semaphore to handle async AI model call in synchronous context
                    let semaphore = DispatchSemaphore(value: 0)
                    var aiResponse: String = ""
                    var aiError: Error?
                    
                    Task {
                        do {
                            aiResponse = try await AIModelHandler.generateResponse(for: chatRequest)
                        } catch {
                            aiError = error
                        }
                        semaphore.signal()
                    }
                    
                    // Wait for the async task to complete (with timeout)
                    let timeoutResult = semaphore.wait(timeout: .now() + Constants.Server.requestTimeout) // 30 second timeout
                    
                                        if timeoutResult == .timedOut {
                        let errorResponse: [String: Any] = [
                            "error": "Request timed out after \(Int(Constants.Server.requestTimeout)) seconds"
                        ]
                        return HttpResponse.badRequest(.json(errorResponse))
                    }
                    
                                        if let error = aiError {
                        let errorResponse: [String: Any] = [
                            "error": "Failed to process request: \(error.localizedDescription)"
                        ]
                        return HttpResponse.badRequest(.json(errorResponse))
                    }
                    
                    // Calculate total duration in nanoseconds
                    let endTime = DispatchTime.now()
                    let totalDuration = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    
                    let response: [String: Any] = [
                        "model": Constants.Model.name,
                        "created_at": ISO8601DateFormatter().string(from: Date()),
                        "message": [
                            "role": "assistant",
                            "content": aiResponse
                        ],
                        "done_reason": "stop",
                        "done": true,
                        "total_duration": totalDuration,
                        "load_duration": NSNull(),
                        "prompt_eval_count": NSNull(),
                        "prompt_eval_duration": NSNull(),
                        "eval_count": NSNull(),
                        "eval_duration": NSNull()
                    ]
                    return HttpResponse.ok(.json(response))
                } else {
                    let endTime = DispatchTime.now()
                    let totalDuration = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    
                    let response: [String: Any] = [
                        "model": Constants.Model.name,
                        "created_at": ISO8601DateFormatter().string(from: Date()),
                        "message": [
                            "role": "assistant",
                            "content": "Apple Intelligence requires macOS 26.0 or iOS 26.0 or later."
                        ],
                        "done_reason": "stop",
                        "done": true,
                        "total_duration": totalDuration,
                        "load_duration": NSNull(),
                        "prompt_eval_count": NSNull(),
                        "prompt_eval_duration": NSNull(),
                        "eval_count": NSNull(),
                        "eval_duration": NSNull()
                    ]
                    return HttpResponse.ok(.json(response))
                }
                #else
                let endTime = DispatchTime.now()
                let totalDuration = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                
                let response: [String: Any] = [
                    "model": Constants.Model.name,
                    "created_at": ISO8601DateFormatter().string(from: Date()),
                    "message": [
                        "role": "assistant",
                        "content": "FoundationModels framework not available."
                    ],
                    "done_reason": "stop",
                    "done": true,
                    "total_duration": totalDuration,
                    "load_duration": NSNull(),
                    "prompt_eval_count": NSNull(),
                    "prompt_eval_duration": NSNull(),
                    "eval_count": NSNull(),
                    "eval_duration": NSNull()
                ]
                return HttpResponse.ok(.json(response))
                #endif
            } catch let decodingError as DecodingError {
                let errorResponse: [String: Any] = [
                    "error": "Invalid JSON format: \(decodingError.localizedDescription)"
                ]
                return HttpResponse.badRequest(.json(errorResponse))
            } catch {
                let errorResponse: [String: Any] = [
                    "error": "Failed to process request: \(error.localizedDescription)"
                ]
                return HttpResponse.badRequest(.json(errorResponse))
            }
        }
        
        self.server = server
    }
    
    func start(port: UInt16 = Constants.Server.defaultPort) throws {
        guard let server = server else {
            throw NSError(domain: "HTTPServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server not initialized"])
        }
        
        try server.start(port, forceIPv4: false, priority: .default)
        print("Server started successfully on port \(port)")
    }
    
    func stop() {
        server?.stop()
        print("Server stopped")
    }
} 