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
        case twoRoomsSingleConnection
        case twoRoomsFullyConnected
        case threeRoomsOneSelfLoop
        case threeRoomsTwoSelfLoops
        case threeRoomsThreeSelfLoops
        case threeRoomsFourSelfLoops
        case threeRoomsFiveSelfLoops
        case fromFile(String)  // Load from a map file
    }

    /// Initialize with optional simple hexagon structure
    /// - Parameter simpleHexagon: If true, creates a 6-room hexagonal graph

    public init(layout: RoomLayout = .hexagon) {
        switch layout {
        case .hexagon:
            setupSimpleHexagon()
        case .threeRooms:
            setupThreeRooms()
        case .twoRoomsSingleConnection:
            setupTwoRoomsSingleConnection()
        case .twoRoomsFullyConnected:
            setupTwoRoomsFullyConnected()
        case .threeRoomsOneSelfLoop:
            setupThreeRoomsOneSelfLoop()
        case .threeRoomsTwoSelfLoops:
            setupThreeRoomsTwoSelfLoops()
        case .threeRoomsThreeSelfLoops:
            setupThreeRoomsThreeSelfLoops()
        case .threeRoomsFourSelfLoops:
            setupThreeRoomsFourSelfLoops()
        case .threeRoomsFiveSelfLoops:
            setupThreeRoomsFiveSelfLoops()
        case .fromFile(let filename):
            setupFromFile(filename)
        }
    }
    
    private func setupFromFile(_ filename: String) {
        do {
            let config = try MapFileLoader.loadMap(from: filename)
            
            // Set room labels
            roomLabels = config.roomLabels
            
            // Build connections dictionary
            for (i, roomId) in config.roomIds.enumerated() {
                roomConnections[i] = [:]
            }
            
            // Map room IDs to indices
            let roomIdToIndex = Dictionary(uniqueKeysWithValues: config.roomIds.enumerated().map { ($1, $0) })
            
            // Process connections
            for conn in config.connections {
                if let fromIndex = roomIdToIndex[conn.from],
                   let toIndex = roomIdToIndex[conn.to] {
                    roomConnections[fromIndex]?[conn.fromDoor] = toIndex
                }
            }
            
            // Build correct map for validation
            let startIndex = roomIdToIndex[config.startRoom] ?? 0
            correctMap = buildMapDescription(startingRoom: startIndex)
            
        } catch {
            print("Error loading map from file \(filename): \(error)")
            // Fallback to simple hexagon
            setupSimpleHexagon()
        }
    }
    
    private func buildMapDescription(startingRoom: Int) -> MapDescription {
        var connections: [Connection] = []
        var processedPairs = Set<String>()
        
        for (fromRoom, doors) in roomConnections {
            for (fromDoor, toRoom) in doors {
                // Find the return door
                var toDoor = fromDoor  // Default to same door
                if let targetDoors = roomConnections[toRoom] {
                    for (targetDoor, targetRoom) in targetDoors {
                        if targetRoom == fromRoom && fromDoor == targetDoor {
                            toDoor = targetDoor
                            break
                        }
                    }
                }
                
                // Create unique key for this connection
                let key = fromRoom < toRoom ? "\(fromRoom):\(fromDoor)-\(toRoom):\(toDoor)" : 
                                              "\(toRoom):\(toDoor)-\(fromRoom):\(fromDoor)"
                
                if !processedPairs.contains(key) {
                    processedPairs.insert(key)
                    connections.append(Connection(
                        from: RoomDoor(room: fromRoom, door: fromDoor),
                        to: RoomDoor(room: toRoom, door: toDoor)
                    ))
                }
            }
        }
        
        return MapDescription(rooms: roomLabels, startingRoom: startingRoom, connections: connections)
    }

    private func setupThreeRooms() {
        roomLabels = [0, 1, 2]
        
        // Room connections matching the generated map
        roomConnections[0] = [
            0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 1
        ]
        roomConnections[1] = [
            0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 2
        ]
        roomConnections[2] = [
            0: 1, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2
        ]
        
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

    private func setupTwoRoomsSingleConnection() {
        roomLabels = [0, 1]
        
        // Only door 0 of room 0 connects to door 3 of room 1
        roomConnections[0] = [
            0: 1,  // Door 0 connects to room 1
            1: 0, 2: 0, 3: 0, 4: 0, 5: 0  // Self-loops
        ]
        roomConnections[1] = [
            0: 1, 1: 1, 2: 1,  // Self-loops
            3: 0,  // Door 3 connects back to room 0
            4: 1, 5: 1  // Self-loops
        ]
        
        correctMap = Self.generateTwoRoomsSingleConnection()
    }
    
    static func generateTwoRoomsSingleConnection() -> MapDescription {
        let roomLabels = [0, 1]
        var connections: [Connection] = []
        
        // Room 0 connections
        connections.connect(room: 0, door: 0, toRoom: 1, toDoor: 3)  // Single connection
        connections.connect(room: 0, door: 1, toRoom: 0, toDoor: 1)  // Self-loops
        connections.connect(room: 0, door: 2, toRoom: 0, toDoor: 2)
        connections.connect(room: 0, door: 3, toRoom: 0, toDoor: 3)
        connections.connect(room: 0, door: 4, toRoom: 0, toDoor: 4)
        connections.connect(room: 0, door: 5, toRoom: 0, toDoor: 5)
        
        // Room 1 connections (door 3 already connected via room 0)
        connections.connect(room: 1, door: 0, toRoom: 1, toDoor: 0)  // Self-loops
        connections.connect(room: 1, door: 1, toRoom: 1, toDoor: 1)
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 4, toRoom: 1, toDoor: 4)
        connections.connect(room: 1, door: 5, toRoom: 1, toDoor: 5)
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    private func setupTwoRoomsFullyConnected() {
        roomLabels = [0, 1]
        
        // All doors connect to the other room
        roomConnections[0] = [
            0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1
        ]
        roomConnections[1] = [
            0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0
        ]
        
        correctMap = Self.generateTwoRoomsFullyConnected()
    }
    
    static func generateTwoRoomsFullyConnected() -> MapDescription {
        let roomLabels = [0, 1]
        var connections: [Connection] = []
        
        // All doors connect between the two rooms
        for door in 0...5 {
            connections.connect(room: 0, door: door, toRoom: 1, toDoor: door)
        }
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    // MARK: - Three Rooms with Varying Self-Loops
    
    private func setupThreeRoomsOneSelfLoop() {
        roomLabels = [0, 1, 2]
        
        // Each room has 1 self-loop, 5 connections to other rooms
        // Ensuring bidirectional consistency: if A:x -> B:y then B:y -> A:x
        roomConnections[0] = [
            0: 0,  // Self-loop (0:0 -> 0:0)
            1: 1,  // To room 1 door 0 (0:1 -> 1:0)
            2: 1,  // To room 1 door 1 (0:2 -> 1:1)
            3: 2,  // To room 2 door 0 (0:3 -> 2:0)
            4: 2,  // To room 2 door 1 (0:4 -> 2:1)
            5: 2   // To room 2 door 2 (0:5 -> 2:2)
        ]
        roomConnections[1] = [
            0: 0,  // To room 0 door 1 (1:0 -> 0:1)
            1: 0,  // To room 0 door 2 (1:1 -> 0:2)
            2: 1,  // Self-loop (1:2 -> 1:2)
            3: 2,  // To room 2 door 3 (1:3 -> 2:3)
            4: 2,  // To room 2 door 4 (1:4 -> 2:4)  
            5: 2   // To room 2 door 5 (1:5 -> 2:5)
        ]
        roomConnections[2] = [
            0: 0,  // To room 0 door 3 (2:0 -> 0:3)
            1: 0,  // To room 0 door 4 (2:1 -> 0:4)
            2: 0,  // To room 0 door 5 (2:2 -> 0:5)
            3: 1,  // To room 1 door 3 (2:3 -> 1:3)
            4: 1,  // To room 1 door 4 (2:4 -> 1:4)
            5: 1   // To room 1 door 5 (2:5 -> 1:5)
        ]
        
        correctMap = Self.generateThreeRoomsOneSelfLoop()
    }
    
    static func generateThreeRoomsOneSelfLoop() -> MapDescription {
        let roomLabels = [0, 1, 2]
        var connections: [Connection] = []
        
        // Each room has 1 self-loop, bidirectional connections
        // Room 0: door 0 self-loop
        connections.connect(room: 0, door: 0, toRoom: 0, toDoor: 0)
        connections.connect(room: 0, door: 1, toRoom: 1, toDoor: 0)
        connections.connect(room: 0, door: 2, toRoom: 1, toDoor: 1)
        connections.connect(room: 0, door: 3, toRoom: 2, toDoor: 0)
        connections.connect(room: 0, door: 4, toRoom: 2, toDoor: 1)
        connections.connect(room: 0, door: 5, toRoom: 2, toDoor: 2)
        
        // Room 1: door 2 self-loop
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 3, toRoom: 2, toDoor: 3)
        connections.connect(room: 1, door: 4, toRoom: 2, toDoor: 4)
        connections.connect(room: 1, door: 5, toRoom: 2, toDoor: 5)
        
        // No need to add more - connections are bidirectional via connect() helper
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    private func setupThreeRoomsTwoSelfLoops() {
        roomLabels = [0, 1, 2]
        
        // Each room has 2 self-loops, 4 connections to other rooms
        roomConnections[0] = [
            0: 0, 1: 0,  // Self-loops
            2: 1, 3: 1,  // To room 1
            4: 2, 5: 2   // To room 2
        ]
        roomConnections[1] = [
            0: 0, 1: 0,  // To room 0
            2: 1, 3: 1,  // Self-loops
            4: 2, 5: 2   // To room 2
        ]
        roomConnections[2] = [
            0: 0, 1: 0,  // To room 0
            2: 1, 3: 1,  // To room 1
            4: 2, 5: 2   // Self-loops
        ]
        
        correctMap = Self.generateThreeRoomsTwoSelfLoops()
    }
    
    static func generateThreeRoomsTwoSelfLoops() -> MapDescription {
        let roomLabels = [0, 1, 2]
        var connections: [Connection] = []
        
        // Room 0: doors 0,1 self-loops
        connections.connect(room: 0, door: 0, toRoom: 0, toDoor: 0)
        connections.connect(room: 0, door: 1, toRoom: 0, toDoor: 1)
        connections.connect(room: 0, door: 2, toRoom: 1, toDoor: 0)
        connections.connect(room: 0, door: 3, toRoom: 1, toDoor: 1)
        connections.connect(room: 0, door: 4, toRoom: 2, toDoor: 0)
        connections.connect(room: 0, door: 5, toRoom: 2, toDoor: 1)
        
        // Room 1: doors 2,3 self-loops
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 3, toRoom: 1, toDoor: 3)
        connections.connect(room: 1, door: 4, toRoom: 2, toDoor: 2)
        connections.connect(room: 1, door: 5, toRoom: 2, toDoor: 3)
        
        // Room 2: doors 4,5 self-loops
        connections.connect(room: 2, door: 4, toRoom: 2, toDoor: 4)
        connections.connect(room: 2, door: 5, toRoom: 2, toDoor: 5)
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    private func setupThreeRoomsThreeSelfLoops() {
        roomLabels = [0, 1, 2]
        
        // Each room has 3 self-loops, 3 connections to other rooms
        // Ensuring bidirectional consistency
        roomConnections[0] = [
            0: 0, 1: 0, 2: 0,  // Self-loops
            3: 1,              // To room 1 door 0 (0:3 -> 1:0)
            4: 2,              // To room 2 door 0 (0:4 -> 2:0)
            5: 2               // To room 2 door 1 (0:5 -> 2:1)
        ]
        roomConnections[1] = [
            0: 0,              // To room 0 door 3 (1:0 -> 0:3)
            1: 1, 2: 1, 3: 1,  // Self-loops
            4: 2,              // To room 2 door 2 (1:4 -> 2:2)
            5: 2               // To room 2 door 3 (1:5 -> 2:3)
        ]
        roomConnections[2] = [
            0: 0,              // To room 0 door 4 (2:0 -> 0:4)
            1: 0,              // To room 0 door 5 (2:1 -> 0:5)
            2: 1,              // To room 1 door 4 (2:2 -> 1:4)
            3: 1,              // To room 1 door 5 (2:3 -> 1:5)
            4: 2, 5: 2         // Self-loops
        ]
        
        correctMap = Self.generateThreeRoomsThreeSelfLoops()
    }
    
    static func generateThreeRoomsThreeSelfLoops() -> MapDescription {
        let roomLabels = [0, 1, 2]
        var connections: [Connection] = []
        
        // Room 0: doors 0,1,2 self-loops
        connections.connect(room: 0, door: 0, toRoom: 0, toDoor: 0)
        connections.connect(room: 0, door: 1, toRoom: 0, toDoor: 1)
        connections.connect(room: 0, door: 2, toRoom: 0, toDoor: 2)
        connections.connect(room: 0, door: 3, toRoom: 1, toDoor: 0)
        connections.connect(room: 0, door: 4, toRoom: 2, toDoor: 0)
        connections.connect(room: 0, door: 5, toRoom: 2, toDoor: 1)
        
        // Room 1: doors 1,2,3 self-loops
        connections.connect(room: 1, door: 1, toRoom: 1, toDoor: 1)
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 3, toRoom: 1, toDoor: 3)
        connections.connect(room: 1, door: 4, toRoom: 2, toDoor: 2)
        connections.connect(room: 1, door: 5, toRoom: 2, toDoor: 3)
        
        // Room 2: doors 4,5 self-loops
        connections.connect(room: 2, door: 4, toRoom: 2, toDoor: 4)
        connections.connect(room: 2, door: 5, toRoom: 2, toDoor: 5)
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    private func setupThreeRoomsFourSelfLoops() {
        roomLabels = [0, 1, 2]
        
        // Each room has 4 self-loops, 2 connections to other rooms
        roomConnections[0] = [
            0: 0, 1: 0, 2: 0, 3: 0,  // Self-loops
            4: 1,                    // To room 1
            5: 2                     // To room 2
        ]
        roomConnections[1] = [
            0: 0,                    // To room 0
            1: 1, 2: 1, 3: 1, 4: 1,  // Self-loops
            5: 2                     // To room 2
        ]
        roomConnections[2] = [
            0: 0,                    // To room 0
            1: 1,                    // To room 1
            2: 2, 3: 2, 4: 2, 5: 2   // Self-loops
        ]
        
        correctMap = Self.generateThreeRoomsFourSelfLoops()
    }
    
    static func generateThreeRoomsFourSelfLoops() -> MapDescription {
        let roomLabels = [0, 1, 2]
        var connections: [Connection] = []
        
        // Room 0: doors 0,1,2,3 self-loops
        connections.connect(room: 0, door: 0, toRoom: 0, toDoor: 0)
        connections.connect(room: 0, door: 1, toRoom: 0, toDoor: 1)
        connections.connect(room: 0, door: 2, toRoom: 0, toDoor: 2)
        connections.connect(room: 0, door: 3, toRoom: 0, toDoor: 3)
        connections.connect(room: 0, door: 4, toRoom: 1, toDoor: 0)
        connections.connect(room: 0, door: 5, toRoom: 2, toDoor: 0)
        
        // Room 1: doors 1,2,3,4 self-loops
        connections.connect(room: 1, door: 1, toRoom: 1, toDoor: 1)
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 3, toRoom: 1, toDoor: 3)
        connections.connect(room: 1, door: 4, toRoom: 1, toDoor: 4)
        connections.connect(room: 1, door: 5, toRoom: 2, toDoor: 1)
        
        // Room 2: doors 2,3,4,5 self-loops
        connections.connect(room: 2, door: 2, toRoom: 2, toDoor: 2)
        connections.connect(room: 2, door: 3, toRoom: 2, toDoor: 3)
        connections.connect(room: 2, door: 4, toRoom: 2, toDoor: 4)
        connections.connect(room: 2, door: 5, toRoom: 2, toDoor: 5)
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
    }
    
    private func setupThreeRoomsFiveSelfLoops() {
        roomLabels = [0, 1, 2]
        
        // Each room has 5 self-loops, 1 connection to another room
        // Creating connections: 0 <-> 1, 0 <-> 2
        roomConnections[0] = [
            0: 0, 1: 0, 2: 0, 3: 0,  // Self-loops on doors 0-3
            4: 1,                     // To room 1 door 4 (0:4 -> 1:4)
            5: 2                      // To room 2 door 5 (0:5 -> 2:5)
        ]
        roomConnections[1] = [
            0: 1, 1: 1, 2: 1, 3: 1,  // Self-loops on doors 0-3
            4: 0,                     // To room 0 door 4 (1:4 -> 0:4) - bidirectional
            5: 1                      // Self-loop on door 5
        ]
        roomConnections[2] = [
            0: 2, 1: 2, 2: 2, 3: 2, 4: 2,  // Self-loops on doors 0-4
            5: 0                            // To room 0 door 5 (2:5 -> 0:5) - bidirectional
        ]
        
        correctMap = Self.generateThreeRoomsFiveSelfLoops()
    }
    
    static func generateThreeRoomsFiveSelfLoops() -> MapDescription {
        let roomLabels = [0, 1, 2]
        var connections: [Connection] = []
        
        // Room 0: doors 0-3 self-loops, door 4 to room 1, door 5 to room 2
        connections.connect(room: 0, door: 0, toRoom: 0, toDoor: 0)
        connections.connect(room: 0, door: 1, toRoom: 0, toDoor: 1)
        connections.connect(room: 0, door: 2, toRoom: 0, toDoor: 2)
        connections.connect(room: 0, door: 3, toRoom: 0, toDoor: 3)
        connections.connect(room: 0, door: 4, toRoom: 1, toDoor: 4)
        connections.connect(room: 0, door: 5, toRoom: 2, toDoor: 5)
        
        // Room 1: doors 0-3 self-loops, door 4 connected to room 0, door 5 self-loop
        connections.connect(room: 1, door: 0, toRoom: 1, toDoor: 0)
        connections.connect(room: 1, door: 1, toRoom: 1, toDoor: 1)
        connections.connect(room: 1, door: 2, toRoom: 1, toDoor: 2)
        connections.connect(room: 1, door: 3, toRoom: 1, toDoor: 3)
        // Door 4 already connected to room 0 via bidirectional connection
        connections.connect(room: 1, door: 5, toRoom: 1, toDoor: 5)
        
        // Room 2: doors 0-4 self-loops, door 5 connected to room 0
        connections.connect(room: 2, door: 0, toRoom: 2, toDoor: 0)
        connections.connect(room: 2, door: 1, toRoom: 2, toDoor: 1)
        connections.connect(room: 2, door: 2, toRoom: 2, toDoor: 2)
        connections.connect(room: 2, door: 3, toRoom: 2, toDoor: 3)
        connections.connect(room: 2, door: 4, toRoom: 2, toDoor: 4)
        // Door 5 already connected to room 0 via bidirectional connection
        
        return MapDescription(rooms: roomLabels, startingRoom: 0, connections: connections)
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
