import Foundation

/// Mock implementation of ExplorationClient for testing
/// Simulates a predefined hexagonal graph structure
///
public class MockExplorationClient: ExplorationClient {
    
    
    /// Labels for each room in the mock graph
    private var roomLabels: [Int] = [0, 1, 2, 3, 0, 1]
    /// Room connections: roomId -> [door -> targetRoom]
    private var roomConnections: [Int: [Int: Int]] = [:]
    /// Track number of exploration queries (for testing efficiency)
    private var queryCount: Int = 0
    /// The correct map structure for validation
    private var correctMap: MapDescription?
    
    /// Initialize with optional simple hexagon structure
    /// - Parameter simpleHexagon: If true, creates a 6-room hexagonal graph
    public init(simpleHexagon: Bool = true) {
        if simpleHexagon {
            setupSimpleHexagon()
        }
    }
    
    /// Simulate problem selection
    public func selectProblem(problemName: String) async throws -> ICFPWorkerLib.SelectResponse {
        return SelectResponse(problemName: problemName)
    }
    
    /// Setup a simple 6-room hexagonal graph for testing
    /// Each room connects to others in a predefined pattern
    private func setupSimpleHexagon() {
        roomLabels = [0, 1, 2, 3, 0, 1]
        
        // Define connections for each room
        // Format: door number -> destination room
        roomConnections[0] = [
            0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 0
        ]
        roomConnections[1] = [
            0: 2, 1: 3, 2: 4, 3: 0, 4: 5, 5: 1
        ]
        roomConnections[2] = [
            0: 3, 1: 4, 2: 5, 3: 1, 4: 0, 5: 2
        ]
        roomConnections[3] = [
            0: 4, 1: 5, 2: 0, 3: 2, 4: 1, 5: 3
        ]
        roomConnections[4] = [
            0: 5, 1: 0, 2: 1, 3: 3, 4: 2, 5: 4
        ]
        roomConnections[5] = [
            0: 0, 1: 1, 2: 2, 3: 4, 4: 3, 5: 5
        ]
        
        var connections: [Connection] = []
        for (fromRoom, doors) in roomConnections {
            for (fromDoor, toRoom) in doors {
                if let toDoors = roomConnections[toRoom] {
                    for (toDoor, backRoom) in toDoors {
                        if backRoom == fromRoom {
                            connections.append(Connection(
                                from: RoomDoor(room: fromRoom, door: fromDoor),
                                to: RoomDoor(room: toRoom, door: toDoor)
                            ))
                            break
                        }
                    }
                }
            }
        }
        
        correctMap = MapDescription(
            rooms: roomLabels,
            startingRoom: 0,
            connections: connections
        )
    }
    
    /// Simulate exploration of paths in the mock graph
    /// Returns room labels observed along each path
    public func explore(plans: [String]) async throws -> ExploreResponse {
        queryCount += 1
        var results: [[Int]] = []
        
        // Process each exploration path
        for plan in plans {
            let labels = explorePath(plan)
            results.append(labels)
        }
        
        return ExploreResponse(results: results, queryCount: queryCount)
    }
    
    /// Simulate walking a path through the graph
    /// - Parameter path: Sequence of door numbers to traverse
    /// - Returns: Array of room labels encountered
    private func explorePath(_ path: String) -> [Int] {
        var currentRoom = 0  // Always start from room 0
        var labels: [Int] = [roomLabels[currentRoom]]
        
        // Walk through each door in the path
        for doorChar in path {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            // Follow the connection if it exists
            if let nextRoom = roomConnections[currentRoom]?[door] {
                currentRoom = nextRoom
                if currentRoom < roomLabels.count {
                    labels.append(roomLabels[currentRoom])
                } else {
                    labels.append(0)  // Default label for undefined rooms
                }
            } else {
                labels.append(0)  // Unknown connection
            }
        }
        
        return labels
    }
    
    public func submitGuess(map: MapDescription) async throws -> GuessResponse {
        if let correct = correctMap {
            let isCorrect = mapsAreEquivalent(map1: map, map2: correct)
            return GuessResponse(correct: isCorrect)
        }
        
        return GuessResponse(correct: false)
    }
    
    private func mapsAreEquivalent(map1: MapDescription, map2: MapDescription) -> Bool {
        guard map1.rooms.count == map2.rooms.count else { return false }
        
        let sortedRooms1 = map1.rooms.sorted()
        let sortedRooms2 = map2.rooms.sorted()
        
        return sortedRooms1 == sortedRooms2
    }
}

/// Mock client that always fails - for testing error handling
class MockFailingClient: ExplorationClient {
    func selectProblem(problemName: String) async throws -> ICFPWorkerLib.SelectResponse {
        throw URLError(.badServerResponse)
    }
    
    /// Always throws an error
    func explore(plans: [String]) async throws -> ExploreResponse {
        throw URLError(.badServerResponse)
    }
    
    /// Always throws an error
    func submitGuess(map: MapDescription) async throws -> GuessResponse {
        throw URLError(.badServerResponse)
    }
}

/// Mock client that returns empty results - for edge case testing
class MockEmptyClient: ExplorationClient {
    func selectProblem(problemName: String) async throws -> ICFPWorkerLib.SelectResponse {
        return SelectResponse(problemName: problemName)
    }
    
    /// Returns empty label arrays for all paths
    func explore(plans: [String]) async throws -> ExploreResponse {
        return ExploreResponse(results: plans.map { _ in [] }, queryCount: 0)
    }
    
    /// Always returns incorrect
    func submitGuess(map: MapDescription) async throws -> GuessResponse {
        return GuessResponse(correct: false)
    }
}
