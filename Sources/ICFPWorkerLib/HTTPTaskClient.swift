import Foundation
import FoundationNetworking

public class HTTPTaskClient {
    private let baseURL: String
    private let teamId: String

    public init(config: EnvConfig) {
        self.baseURL = config.apiUrl
        self.teamId = config.teamId
    }

    // MARK: - API Methods
    public func register(name: String, pl: String, email: String) async throws -> RegisterResponse {
        let request = RegisterRequest(name: name, pl: pl, email: email)
        return try await post(endpoint: "/register", body: request)
    }

    public func selectProblem(problemName: String) async throws -> SelectResponse {
        let request = SelectRequest(id: self.teamId, problemName: problemName)
        return try await post(endpoint: "/select", body: request)
    }

    public func explore(plans: [String]) async throws -> ExploreResponse {
        let request = ExploreRequest(id: self.teamId, plans: plans)
        return try await post(endpoint: "/explore", body: request)
    }

    public func guess(map: MapDescription) async throws -> GuessResponse {
        let request = GuessRequest(id: self.teamId, map: map)
        return try await post(endpoint: "/guess", body: request)
    }

    // MARK: - Private Helper Methods
    private func post<T: Codable, R: Codable>(endpoint: String, body: T) async throws -> R {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(R.self, from: data)
    }
}
