import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case refreshTokenExpired
    case unknown
}

final class APIService {
    static let shared = APIService()
    private let baseURL = "https://airdrop.tari.com/api"
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken = UserManager.shared.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<T, Error> in
                if case APIError.unauthorized = error {
                    return self.refreshToken()
                        .flatMap { _ in
                            self.request(endpoint: endpoint, method: method, body: body)
                        }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func refreshToken() -> AnyPublisher<Void, Error> {
        guard let refreshToken = UserManager.shared.refreshToken else {
            UserManager.shared.clearTokens()
            return Fail(error: APIError.refreshTokenExpired).eraseToAnyPublisher()
        }

        guard let url = URL(string: "\(baseURL)/auth/local/refresh") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode == 401 {
                    UserManager.shared.clearTokens()
                    throw APIError.refreshTokenExpired
                }

                guard httpResponse.statusCode == 200 else {
                    throw APIError.unknown
                }

                struct TokenResponse: Decodable {
                    let accessToken: String
                    let refreshToken: String?
                }

                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                UserManager.shared.accessToken = tokenResponse.accessToken
                if let newRefreshToken = tokenResponse.refreshToken {
                    UserManager.shared.refreshToken = newRefreshToken
                }
            }
            .eraseToAnyPublisher()
    }
}
