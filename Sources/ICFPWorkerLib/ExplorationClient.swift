import Foundation

/// Protocol defining the interface for exploration operations
/// This abstraction allows for different implementations (HTTP, WebSocket, Mock)
/// and makes the system testable by allowing mock implementations
public protocol ExplorationClient {
    /// Submit exploration plans to the API and receive room labels
    /// - Parameter plans: Array of path strings (e.g., ["012", "345"])
    /// - Returns: ExploreResponse containing room labels for each path
    func explore(plans: [String]) async throws -> ExploreResponse
    
    /// Submit a final map guess to verify if it's correct
    /// - Parameter map: Complete map description with rooms and connections
    /// - Returns: GuessResponse indicating if the map is correct
    func submitGuess(map: MapDescription) async throws -> GuessResponse
}

/// Concrete implementation of ExplorationClient using HTTP
/// Wraps the HTTPTaskClient to provide the ExplorationClient interface
public class HTTPExplorationClient: ExplorationClient {
    private let teamId: String
    private let httpClient: HTTPTaskClient
    
    /// Initialize with team ID and HTTP client
    /// - Parameters:
    ///   - teamId: Team identifier for the contest
    ///   - httpClient: Underlying HTTP client for API calls
    public init(teamId: String, httpClient: HTTPTaskClient) {
        self.teamId = teamId
        self.httpClient = httpClient
    }
    
    /// Forward exploration request to HTTP client
    public func explore(plans: [String]) async throws -> ExploreResponse {
        return try await httpClient.explore(plans: plans)
    }
    
    /// Forward map guess to HTTP client
    public func submitGuess(map: MapDescription) async throws -> GuessResponse {
        return try await httpClient.guess(map: map)
    }
}