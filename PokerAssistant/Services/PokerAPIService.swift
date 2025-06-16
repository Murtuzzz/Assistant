import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

struct APIResponse: Codable {
    let recommendation: String
    let explanation: String
}

class PokerAPIService {
    // Используйте ваш OpenRouter API-ключ
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let apiKey = "sk-or-v1-" // <-- Вставьте сюда ваш OpenRouter API-ключ
    
    func getRecommendation(for hand: PokerHandModel) async throws -> APIResponse {
        guard let url = URL(string: baseURL) else {
            print("[DEBUG] Invalid URL: \(baseURL)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [ //-0528
            "model": "deepseek/deepseek-r1:free",
            "messages": [
                ["role": "system", "content": "Ты — покерный ассистент. Дай совет по раздаче. Ответь только одним словом (check, bet, call, raise, fold) и коротким объяснением на русском языке."],
                ["role": "user", "content": hand.toUserPrompt()]
            ],
            "stream": false
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        // Debug: print request
        print("[DEBUG] Request URL: \(url)")
        print("[DEBUG] Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("[DEBUG] Request Body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] Response Status Code: \(httpResponse.statusCode)")
                print("[DEBUG] Response Headers: \(httpResponse.allHeaderFields)")
            }
            print("[DEBUG] Response Data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("[DEBUG] Invalid response: \(response)")
                throw APIError.invalidResponse
            }
            
            // OpenRouter возвращает OpenAI-совместимый ответ
            struct OpenRouterResponse: Codable {
                struct Choice: Codable {
                    struct Message: Codable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            let decoder = JSONDecoder()
            let orResponse = try decoder.decode(OpenRouterResponse.self, from: data)
            let content = orResponse.choices.first?.message.content ?? ""
            // Парсим ответ: первое слово — рекомендация, остальное — объяснение
            let parts = content.components(separatedBy: " ")
            let recommendation = parts.first ?? ""
            let explanation = parts.dropFirst().joined(separator: " ")
            return APIResponse(recommendation: recommendation, explanation: explanation)
        } catch let error as DecodingError {
            print("[DEBUG] Decoding error: \(error)")
            throw APIError.decodingError(error)
        } catch {
            print("[DEBUG] Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
} 
