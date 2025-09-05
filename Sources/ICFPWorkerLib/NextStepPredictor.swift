import Foundation

/// Predicts the next best exploration paths based on current graph state
/// Uses heuristics to maximize information gain
public class NextStepPredictor {
    /// Maximum length of generated paths
    private let maxPathLength: Int
    /// Maximum number of path suggestions to generate
    private let maxSuggestions: Int
    
    /// Initialize with path generation constraints
    public init(maxPathLength: Int = 10, maxSuggestions: Int = 20) {
        self.maxPathLength = maxPathLength
        self.maxSuggestions = maxSuggestions
    }
    
    /// Predict the most valuable paths to explore next
    /// Prioritizes: unknown doors > ambiguous connections > unlabeled rooms
    public func predictNextPaths(graph: GraphBuilder, evaluator: GraphEvaluator) -> [String] {
        let evaluation = evaluator.evaluate(graph: graph)
        
        // No suggestions needed if graph is complete
        if evaluation.isComplete {
            return []
        }
        
        var suggestedPaths: [String] = []
        
        // Priority 1: Explore unknown doors
        suggestedPaths.append(contentsOf: exploreUnknownDoors(
            graph: graph,
            unknownDoors: evaluation.missingInfo.unknownDoors
        ))
        
        // Priority 2: Resolve ambiguous connections
        suggestedPaths.append(contentsOf: resolveAmbiguousConnections(
            graph: graph,
            ambiguous: evaluation.missingInfo.ambiguousConnections
        ))
        
        // Priority 3: Visit unlabeled rooms
        suggestedPaths.append(contentsOf: exploreUnlabeledRooms(
            graph: graph,
            unlabeledRooms: evaluation.missingInfo.unlabeledRooms
        ))
        
        // Fill remaining with exploratory paths if needed
        if suggestedPaths.count < maxSuggestions / 2 {
            suggestedPaths.append(contentsOf: generateExploratoryPaths(graph: graph))
        }
        
        // Remove duplicates and limit count
        return Array(Set(suggestedPaths).prefix(maxSuggestions))
    }
    
    /// Generate paths to explore unknown doors
    /// Prioritizes doors directly accessible from the starting room
    private func exploreUnknownDoors(graph: GraphBuilder, unknownDoors: [(room: Int, door: Int)]) -> [String] {
        var paths: [String] = []
        
        // First handle doors from starting room (easy to reach)
        let doorsFromStart = unknownDoors.filter { $0.room == graph.getStartingRoom() }
        for (_, door) in doorsFromStart.prefix(5) {
            // Direct exploration
            paths.append(String(door))
            
            // Explore what's beyond
            for nextDoor in 0..<6 {
                paths.append("\(door)\(nextDoor)")
            }
        }
        
        // Then handle doors from other rooms (need navigation)
        let otherDoors = unknownDoors.filter { $0.room != graph.getStartingRoom() }
        for (room, door) in otherDoors.prefix(5) {
            if let pathToRoom = findShortestPath(from: graph.getStartingRoom(), to: room, in: graph) {
                if pathToRoom.count < maxPathLength - 1 {
                    // Navigate to room then explore door
                    paths.append(pathToRoom + String(door))
                    
                    // Also explore a bit beyond
                    for nextDoor in [0, 1, 2].shuffled().prefix(2) {
                        if pathToRoom.count < maxPathLength - 2 {
                            paths.append(pathToRoom + "\(door)\(nextDoor)")
                        }
                    }
                }
            }
        }
        
        return paths
    }
    
    /// Generate paths to resolve ambiguous connections
    /// Tries to discover which door leads back from connected rooms
    private func resolveAmbiguousConnections(
        graph: GraphBuilder,
        ambiguous: [(from: (room: Int, door: Int), to: [(room: Int, door: Int)])]
    ) -> [String] {
        var paths: [String] = []
        
        // Focus on first 3 ambiguous connections
        for connection in ambiguous.prefix(3) {
            let fromRoom = connection.from.room
            let fromDoor = connection.from.door
            
            if fromRoom == graph.getStartingRoom() {
                // Direct exploration from start
                paths.append(String(fromDoor))
                
                // Try all return doors to find the connection
                for returnDoor in 0..<6 {
                    paths.append("\(fromDoor)\(returnDoor)")
                }
            } else if let pathToRoom = findShortestPath(from: graph.getStartingRoom(), to: fromRoom, in: graph) {
                if pathToRoom.count < maxPathLength - 2 {
                    // Navigate to room, go through door
                    paths.append(pathToRoom + String(fromDoor))
                    
                    // Try return doors
                    for returnDoor in 0..<6 {
                        if pathToRoom.count < maxPathLength - 3 {
                            paths.append(pathToRoom + "\(fromDoor)\(returnDoor)")
                        }
                    }
                }
            }
        }
        
        return paths
    }
    
    private func exploreUnlabeledRooms(graph: GraphBuilder, unlabeledRooms: [Int]) -> [String] {
        var paths: [String] = []
        
        for roomId in unlabeledRooms.prefix(5) {
            if roomId == graph.getStartingRoom() {
                paths.append("")
            } else if let pathToRoom = findShortestPath(from: graph.getStartingRoom(), to: roomId, in: graph) {
                if !pathToRoom.isEmpty && pathToRoom.count <= maxPathLength {
                    paths.append(pathToRoom)
                }
            }
        }
        
        return paths.filter { !$0.isEmpty || unlabeledRooms.contains(graph.getStartingRoom()) }
    }
    
    private func generateExploratoryPaths(graph: GraphBuilder) -> [String] {
        var paths: [String] = []
        let allRooms = graph.getAllRooms()
        
        let roomsWithMostUnknowns = allRooms.sorted { room1, room2 in
            let unknowns1 = room1.doors.values.filter { $0 == nil }.count
            let unknowns2 = room2.doors.values.filter { $0 == nil }.count
            return unknowns1 > unknowns2
        }.prefix(3)
        
        for room in roomsWithMostUnknowns {
            if room.id == graph.getStartingRoom() {
                for door in 0..<6 where room.doors[door] == nil {
                    paths.append(String(door))
                }
            } else if let pathToRoom = findShortestPath(from: graph.getStartingRoom(), to: room.id, in: graph) {
                for door in 0..<6 where room.doors[door] == nil {
                    if pathToRoom.count < maxPathLength - 1 {
                        paths.append(pathToRoom + String(door))
                    }
                }
            }
        }
        
        for _ in 0..<5 {
            let randomLength = min(Int.random(in: 2...maxPathLength), maxPathLength)
            let randomPath = (0..<randomLength).map { _ in String(Int.random(in: 0..<6)) }.joined()
            paths.append(randomPath)
        }
        
        return paths
    }
    
    private func findShortestPath(from startRoom: Int, to targetRoom: Int, in graph: GraphBuilder) -> String? {
        if startRoom == targetRoom {
            return ""
        }
        
        var visited = Set<Int>()
        var queue: [(room: Int, path: String)] = [(startRoom, "")]
        
        while !queue.isEmpty {
            let (currentRoom, currentPath) = queue.removeFirst()
            
            if visited.contains(currentRoom) {
                continue
            }
            visited.insert(currentRoom)
            
            guard let room = graph.getRoom(currentRoom) else { continue }
            
            for (door, connection) in room.doors {
                if let (nextRoom, _) = connection {
                    let newPath = currentPath + String(door)
                    
                    if nextRoom == targetRoom {
                        return newPath
                    }
                    
                    if !visited.contains(nextRoom) && newPath.count < maxPathLength {
                        queue.append((nextRoom, newPath))
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Score a path by how much new information it would provide
    /// Higher scores mean more valuable exploration
    public func scorePathByInformationGain(path: String, graph: GraphBuilder) -> Double {
        var score = 0.0
        var simulatedRoom = graph.getStartingRoom()
        
        // Simulate walking the path and score each step
        for (index, doorChar) in path.enumerated() {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            if let room = graph.getRoom(simulatedRoom) {
                // Score based on what we'd learn
                if room.doors[door] == nil {
                    // Unknown door = high value
                    score += 2.0
                } else if let connection = room.doors[door], let (nextRoom, toDoor) = connection, toDoor < 0 {
                    // Ambiguous connection = medium value
                    score += 1.0
                    simulatedRoom = nextRoom
                } else if let connection = room.doors[door], let (nextRoom, _) = connection {
                    // Known connection = no direct value
                    simulatedRoom = nextRoom
                }
                
                // Bonus for visiting unlabeled rooms
                if let nextRoomObj = graph.getRoom(simulatedRoom), nextRoomObj.label == nil {
                    score += 1.5
                }
            }
            
            // Decay score with depth (prefer shorter paths)
            score *= (1.0 - Double(index) * 0.05)
        }
        
        return score
    }
}