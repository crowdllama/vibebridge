import Foundation
import Swifter

// MARK: - HTTP Server with Swifter

class HTTPServer {
    private var server: HttpServer?
    
    // Helper method to handle common AI response generation logic
    private func handleAIResponse<T: Codable>(request: T, modelName: String, generateFunction: @escaping (T) async throws -> String, startTime: DispatchTime, isGenerateEndpoint: Bool = false) -> HttpResponse {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            // Use semaphore to handle async AI model call in synchronous context
            let semaphore = DispatchSemaphore(value: 0)
            var aiResponse: String = ""
            var aiError: Error?
            
            Task {
                do {
                    aiResponse = try await generateFunction(request)
                } catch {
                    aiError = error
                }
                semaphore.signal()
            }
            
            // Wait for the async task to complete (with timeout)
            let timeoutResult = semaphore.wait(timeout: .now() + Constants.Server.requestTimeout)
            
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
            
            var response: [String: Any] = [
                "model": modelName,
                "created_at": ISO8601DateFormatter().string(from: Date()),
                "done_reason": "stop",
                "done": true,
                "total_duration": totalDuration
            ]
            
            if isGenerateEndpoint {
                // Generate endpoint format: direct "response" field
                response["response"] = aiResponse
            } else {
                // Chat endpoint format: "message" object
                response["message"] = [
                    "role": "assistant",
                    "content": aiResponse
                ]
                response["load_duration"] = NSNull()
                response["prompt_eval_count"] = NSNull()
                response["prompt_eval_duration"] = NSNull()
                response["eval_count"] = NSNull()
                response["eval_duration"] = NSNull()
            }
            
            return HttpResponse.ok(.json(response))
        } else {
            let endTime = DispatchTime.now()
            let totalDuration = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            
            var response: [String: Any] = [
                "model": modelName,
                "created_at": ISO8601DateFormatter().string(from: Date()),
                "done_reason": "stop",
                "done": true,
                "total_duration": totalDuration
            ]
            
            if isGenerateEndpoint {
                response["response"] = "Apple Intelligence requires macOS 26.0 or iOS 26.0 or later."
            } else {
                response["message"] = [
                    "role": "assistant",
                    "content": "Apple Intelligence requires macOS 26.0 or iOS 26.0 or later."
                ]
                response["load_duration"] = NSNull()
                response["prompt_eval_count"] = NSNull()
                response["prompt_eval_duration"] = NSNull()
                response["eval_count"] = NSNull()
                response["eval_duration"] = NSNull()
            }
            
            return HttpResponse.ok(.json(response))
        }
        #else
        let endTime = DispatchTime.now()
        let totalDuration = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        
        var response: [String: Any] = [
            "model": modelName,
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "done_reason": "stop",
            "done": true,
            "total_duration": totalDuration
        ]
        
        if isGenerateEndpoint {
            response["response"] = "FoundationModels framework not available."
        } else {
            response["message"] = [
                "role": "assistant",
                "content": "FoundationModels framework not available."
            ]
            response["load_duration"] = NSNull()
            response["prompt_eval_count"] = NSNull()
            response["prompt_eval_duration"] = NSNull()
            response["eval_count"] = NSNull()
            response["eval_duration"] = NSNull()
        }
        
        return HttpResponse.ok(.json(response))
        #endif
    }
    
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
                
                return self.handleAIResponse(
                    request: chatRequest,
                    modelName: Constants.Model.name,
                    generateFunction: { request in
                        #if canImport(FoundationModels)
                        if #available(macOS 26.0, iOS 26.0, *) {
                            return try await AIModelHandler.generateResponse(for: request)
                        } else {
                            throw NSError(domain: "VibeBridge", code: 5, userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence requires macOS 26.0 or iOS 26.0 or later"])
                        }
                        #else
                        throw NSError(domain: "VibeBridge", code: 6, userInfo: [NSLocalizedDescriptionKey: "FoundationModels framework not available"])
                        #endif
                    },
                    startTime: startTime
                )
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
        
        // Generate endpoint
        server.POST["/api/generate"] = { request in
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
                
                let generateRequest = try JSONDecoder().decode(GenerateRequest.self, from: jsonData)
                
                // Validate that the requested model matches our available model
                guard generateRequest.model == Constants.Model.name else {
                    let errorResponse: [String: Any] = [
                        "error": "model \"\(generateRequest.model)\" not found, try pulling it first"
                    ]
                    return HttpResponse.badRequest(.json(errorResponse))
                }
                
                return self.handleAIResponse(
                    request: generateRequest,
                    modelName: Constants.Model.name,
                    generateFunction: { request in
                        #if canImport(FoundationModels)
                        if #available(macOS 26.0, iOS 26.0, *) {
                            return try await AIModelHandler.generateResponse(for: request)
                        } else {
                            throw NSError(domain: "VibeBridge", code: 5, userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence requires macOS 26.0 or iOS 26.0 or later"])
                        }
                        #else
                        throw NSError(domain: "VibeBridge", code: 6, userInfo: [NSLocalizedDescriptionKey: "FoundationModels framework not available"])
                        #endif
                    },
                    startTime: startTime,
                    isGenerateEndpoint: true
                )
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