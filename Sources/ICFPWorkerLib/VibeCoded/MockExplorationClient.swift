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
    internal private(set) var correctMap: MapDescription?

    public enum RoomLayout {
        case hexagon
        case threeRooms
    }

    /// Initialize with optional simple hexagon structure
    /// - Parameter simpleHexagon: If true, creates a 6-room hexagonal graph

    public init(layout: RoomLayout = .hexagon) {
        switch layout {
        case .hexagon:
            setupSimpleHexagon()
        case .threeRooms:
            setupThreeRooms()
        }
    }

    private func setupThreeRooms() {
        // Generate the correct map for validation
        correctMap = Self.generateThreeRooms()
    }

    static func generateThreeRooms(offset: Int = 0) -> MapDescription {
        var roomLabels = [0, 1, 2]

        func idx(_ i: Int) -> Int {
            return (i + offset) % roomLabels.count
        }

        roomLabels[idx(0)] = 0
        roomLabels[idx(1)] = 1
        roomLabels[idx(2)] = 2

        var connections: [Connection] = []
        connections.connect(room: idx(0), door: 0, toRoom: idx(0), toDoor: 0)
        connections.connect(room: idx(0), door: 1, toRoom: idx(0), toDoor: 1)
        connections.connect(room: idx(0), door: 2, toRoom: idx(0), toDoor: 2)
        connections.connect(room: idx(0), door: 3, toRoom: idx(0), toDoor: 3)
        connections.connect(room: idx(0), door: 4, toRoom: idx(0), toDoor: 4)
        connections.connect(room: idx(0), door: 5, toRoom: idx(1), toDoor: 0)

        // connections.connect(room: idx(1), door: 0, toRoom: idx(0), toDoor: 5)
        connections.connect(room: idx(1), door: 1, toRoom: idx(1), toDoor: 1)
        connections.connect(room: idx(1), door: 2, toRoom: idx(1), toDoor: 2)
        connections.connect(room: idx(1), door: 3, toRoom: idx(1), toDoor: 3)
        connections.connect(room: idx(1), door: 4, toRoom: idx(1), toDoor: 4)
        connections.connect(room: idx(1), door: 5, toRoom: idx(2), toDoor: 0)

        // connections.connect(room: idx(2), door: 0, toRoom: idx(1), toDoor: 5)
        connections.connect(room: idx(2), door: 1, toRoom: idx(2), toDoor: 1)
        connections.connect(room: idx(2), door: 2, toRoom: idx(2), toDoor: 2)
        connections.connect(room: idx(2), door: 3, toRoom: idx(2), toDoor: 3)
        connections.connect(room: idx(2), door: 4, toRoom: idx(2), toDoor: 4)
        connections.connect(room: idx(2), door: 5, toRoom: idx(2), toDoor: 5)

        return MapDescription(rooms: roomLabels, startingRoom: idx(0), connections: connections)
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
            0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 0,
        ]
        roomConnections[1] = [
            0: 2, 1: 3, 2: 4, 3: 0, 4: 5, 5: 1,
        ]
        roomConnections[2] = [
            0: 3, 1: 4, 2: 5, 3: 1, 4: 0, 5: 2,
        ]
        roomConnections[3] = [
            0: 4, 1: 5, 2: 0, 3: 2, 4: 1, 5: 3,
        ]
        roomConnections[4] = [
            0: 5, 1: 0, 2: 1, 3: 3, 4: 2, 5: 4,
        ]
        roomConnections[5] = [
            0: 0, 1: 1, 2: 2, 3: 4, 4: 3, 5: 5,
        ]

        var connections: [Connection] = []
        for (fromRoom, doors) in roomConnections {
            for (fromDoor, toRoom) in doors {
                if let toDoors = roomConnections[toRoom] {
                    for (toDoor, backRoom) in toDoors {
                        if backRoom == fromRoom {
                            connections.append(
                                Connection(
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

    func mapsAreEquivalent(map1: MapDescription, map2: MapDescription) -> Bool {
        guard map1.rooms.count == map2.rooms.count else { return false }

        var roomsMappingBetweenMaps: [Int: Int] = [:]
        roomsMappingBetweenMaps[map1.startingRoom] = map2.startingRoom

        var indexesToCheck = (0..<map1.rooms.count).map { $0 }

        while indexesToCheck.count > 0 {

            // Find first index for which we have mapping
            let idx = indexesToCheck.first { roomsMappingBetweenMaps[$0] != nil }
            guard let idx = idx else {
                print("No more indexes with mapping found, but some rooms are still unmapped.")
                return false
            }
            indexesToCheck.removeAll { $0 == idx }

            let room1 = idx
            let room2 = roomsMappingBetweenMaps[room1]!

            for door in 0...5 {

                /// Find connection for door1 in map1
                var destinationForMap1: Int?
                if let connection1 = map1.connections.first(where: {
                    $0.from.room == room1 && $0.from.door == door
                }) {
                    destinationForMap1 = connection1.to.room
                } else if let connection1 = map1.connections.first(where: {
                    $0.to.room == room1 && $0.to.door == door
                }) {
                    destinationForMap1 = connection1.from.room
                } else {
                    print("No connection found for door \(door) in room \(room1)")
                    return false
                }

                var destinationForMap2: Int?
                if let connection2 = map2.connections.first(where: {
                    $0.from.room == room2 && $0.from.door == door
                }) {
                    destinationForMap2 = connection2.to.room
                } else if let connection2 = map2.connections.first(where: {
                    $0.to.room == room2 && $0.to.door == door
                }) {
                    destinationForMap2 = connection2.from.room
                } else {
                    print("No connection found for door \(door) in room \(room2)")
                    return false
                }

                let indexOfMap1 = destinationForMap1!
                let indexOfMap2 = destinationForMap2!

                if let existingIndex = roomsMappingBetweenMaps[indexOfMap1] {
                    if existingIndex != indexOfMap2 {
                        print(
                            "Room \(indexOfMap1) in map1 is not the same as room \(indexOfMap2) in map2"
                        )
                        return false
                    }
                } else {
                    roomsMappingBetweenMaps[indexOfMap1] = indexOfMap2
                }

                let label1 = map1.rooms[indexOfMap1]
                let label2 = map2.rooms[indexOfMap2]

                guard label1 == label2 else {
                    print(
                        "Labels do not match for rooms \(indexOfMap1) and \(indexOfMap2): \(label1) vs \(label2)"
                    )
                    return false
                }
            }

        }
        return true
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
