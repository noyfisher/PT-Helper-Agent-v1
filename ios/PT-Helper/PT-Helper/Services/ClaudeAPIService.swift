import Foundation

// MARK: - Error Types

enum ClaudeAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int, String)
    case decodingError(Error)
    case noContent
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription). Please check your internet connection."
        case .invalidResponse(let statusCode, let details):
            // Parse the API error message if possible
            if let data = details.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = json["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                return "API error (\(statusCode)): \(message)"
            }
            return "Server returned an error (status \(statusCode)). Please try again."
        case .decodingError:
            return "Failed to process the AI response. Please try again."
        case .noContent:
            return "The AI returned an empty response. Please try again."
        case .rateLimited:
            return "The service is busy. Please wait a moment and try again."
        }
    }
}

// MARK: - API Request/Response Models

struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Decodable {
    let content: [ContentBlock]
    let stop_reason: String?

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

// MARK: - Claude API Service

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private init() {}

    /// Send a message to the Claude API and return the text response
    func sendMessage(systemPrompt: String, userMessage: String) async throws -> String {
        guard let url = URL(string: APIConfig.anthropicBaseURL) else {
            throw ClaudeAPIError.invalidURL
        }

        // Build the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90

        // Set headers
        request.setValue(APIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConfig.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // Build the request body
        let requestBody = ClaudeRequest(
            model: APIConfig.anthropicModel,
            max_tokens: APIConfig.maxTokens,
            system: systemPrompt,
            messages: [
                ClaudeMessage(role: "user", content: userMessage)
            ]
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        // Make the API call
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeAPIError.networkError(error)
        }

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse(0, "Invalid HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 429:
            throw ClaudeAPIError.rateLimited
        default:
            // Parse the error body for a useful message
            let errorBody = String(data: data, encoding: .utf8) ?? "No error details"
            print("Claude API Error (\(httpResponse.statusCode)): \(errorBody)")
            throw ClaudeAPIError.invalidResponse(httpResponse.statusCode, errorBody)
        }

        // Decode the response
        let claudeResponse: ClaudeResponse
        do {
            claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            throw ClaudeAPIError.decodingError(error)
        }

        // Extract text from the first content block
        guard let textBlock = claudeResponse.content.first(where: { $0.type == "text" }),
              let text = textBlock.text, !text.isEmpty else {
            throw ClaudeAPIError.noContent
        }

        // Clean up the response — strip markdown code fences if present
        return cleanJSONResponse(text)
    }

    /// Strip markdown code fences from the response
    private func cleanJSONResponse(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove ```json ... ``` wrapping
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
