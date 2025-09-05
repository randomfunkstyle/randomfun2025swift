import Foundation

/// Evaluates the completeness and confidence of the discovered graph
/// Identifies missing information needed to complete the map
public class GraphEvaluator {
    /// Result of graph evaluation
    public struct EvaluationResult {
        /// True if the graph appears complete
        public let isComplete: Bool
        /// Confidence score (0.0-1.0) in the graph's completeness
        public let confidence: Double
        /// Details about what information is still missing
        public let missingInfo: MissingInformation
    }
    
    /// Information missing from the current graph
    public struct MissingInformation {
        /// Rooms without known labels
        public let unlabeledRooms: [Int]
        /// Doors that haven't been explored
        public let unknownDoors: [(room: Int, door: Int)]
        /// Connections where we don't know the return door
        public let ambiguousConnections: [(from: (room: Int, door: Int), to: [(room: Int, door: Int)])]
    }
    
    public init() {}
    
    /// Evaluate the current state of the graph
    /// - Parameter graph: The graph to evaluate
    /// - Returns: Evaluation result with completeness and missing info
    public func evaluate(graph: GraphBuilder) -> EvaluationResult {
        let allRooms = graph.getAllRooms()
        
        // Identify different types of missing information
        let unlabeledRooms = findUnlabeledRooms(in: allRooms)
        let unknownDoors = findUnknownDoors(in: allRooms)
        let ambiguousConnections = findAmbiguousConnections(in: allRooms)
        
        // Graph is complete if we have no missing information
        let isComplete = unlabeledRooms.isEmpty && 
                        unknownDoors.isEmpty && 
                        ambiguousConnections.isEmpty &&
                        allRooms.count > 0
        
        // Calculate confidence based on how much we know
        let confidence = calculateConfidence(
            unlabeledRooms: unlabeledRooms,
            unknownDoors: unknownDoors,
            ambiguousConnections: ambiguousConnections,
            totalRooms: allRooms.count
        )
        
        let missingInfo = MissingInformation(
            unlabeledRooms: unlabeledRooms,
            unknownDoors: unknownDoors,
            ambiguousConnections: ambiguousConnections
        )
        
        return EvaluationResult(
            isComplete: isComplete,
            confidence: confidence,
            missingInfo: missingInfo
        )
    }
    
    private func findUnlabeledRooms(in rooms: [GraphBuilder.Room]) -> [Int] {
        return rooms
            .filter { $0.label == nil }
            .map { $0.id }
    }
    
    private func findUnknownDoors(in rooms: [GraphBuilder.Room]) -> [(room: Int, door: Int)] {
        var unknownDoors: [(room: Int, door: Int)] = []
        
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] == nil {
                    unknownDoors.append((room: room.id, door: door))
                }
            }
        }
        
        return unknownDoors
    }
    
    private func findAmbiguousConnections(in rooms: [GraphBuilder.Room]) -> [(from: (room: Int, door: Int), to: [(room: Int, door: Int)])] {
        var ambiguous: [(from: (room: Int, door: Int), to: [(room: Int, door: Int)])] = []
        
        for room in rooms {
            for (door, connection) in room.doors {
                if let (toRoom, toDoor) = connection, toDoor < 0 {
                    ambiguous.append((
                        from: (room: room.id, door: door),
                        to: [(room: toRoom, door: -1)]
                    ))
                }
            }
        }
        
        return ambiguous
    }
    
    /// Calculate confidence score based on known vs unknown information
    /// Weights: 30% labels, 50% doors, 20% ambiguity resolution
    private func calculateConfidence(
        unlabeledRooms: [Int],
        unknownDoors: [(room: Int, door: Int)],
        ambiguousConnections: [(from: (room: Int, door: Int), to: [(room: Int, door: Int)])],
        totalRooms: Int
    ) -> Double {
        guard totalRooms > 0 else { return 0.0 }
        
        // Special handling for simple layouts (2-3 rooms)
        if totalRooms <= 3 {
            // For small layouts, be more optimistic about completeness
            let labeledRatio = Double(totalRooms - unlabeledRooms.count) / Double(totalRooms)
            
            // Count fully resolved doors (both direction known)
            let totalDoors = totalRooms * 6
            let fullyResolvedDoors = totalDoors - unknownDoors.count - ambiguousConnections.count
            let doorRatio = Double(fullyResolvedDoors) / Double(totalDoors)
            
            // For small layouts, if we have all labels and most doors, we're very confident
            if labeledRatio == 1.0 && doorRatio > 0.7 {
                return 0.95
            }
            
            // Adjusted weights for small layouts: labels are more important
            return (labeledRatio * 0.5 + doorRatio * 0.4 + (1.0 - Double(ambiguousConnections.count) / Double(max(6, 1))) * 0.1)
        }
        
        // Original calculation for larger layouts
        let labeledRatio = Double(totalRooms - unlabeledRooms.count) / Double(totalRooms)
        
        // How many doors have we explored?
        let totalDoors = totalRooms * 6
        let knownDoors = totalDoors - unknownDoors.count
        let doorRatio = Double(knownDoors) / Double(totalDoors)
        
        // How many connections are fully resolved?
        let ambiguityPenalty = 1.0 - (Double(ambiguousConnections.count) / Double(max(totalDoors, 1)))
        
        // Weighted average
        return (labeledRatio * 0.3 + doorRatio * 0.5 + ambiguityPenalty * 0.2)
    }
    
    /// Find the most important paths to explore next
    /// Prioritizes unexplored doors that are easy to reach
    public func findCriticalUnexploredPaths(graph: GraphBuilder) -> [String] {
        var criticalPaths: [String] = []
        let evaluation = evaluate(graph: graph)
        
        // Focus on the first 5 unknown doors
        for (room, door) in evaluation.missingInfo.unknownDoors.prefix(5) {
            if room == graph.getStartingRoom() {
                // Direct exploration from start
                criticalPaths.append(String(door))
            } else {
                // Need to navigate to the room first
                if let pathToRoom = findPathToRoom(from: graph.getStartingRoom(), to: room, in: graph) {
                    criticalPaths.append(pathToRoom + String(door))
                }
            }
        }
        
        return criticalPaths
    }
    
    /// Find shortest path between two rooms using BFS
    /// - Parameters:
    ///   - startRoom: Starting room ID
    ///   - targetRoom: Target room ID
    ///   - graph: Graph to search in
    /// - Returns: Path string if found, nil otherwise
    private func findPathToRoom(from startRoom: Int, to targetRoom: Int, in graph: GraphBuilder) -> String? {
        if startRoom == targetRoom {
            return ""
        }
        
        var visited = Set<Int>()
        var queue: [(room: Int, path: String)] = [(startRoom, "")]
        
        // BFS to find shortest path
        while !queue.isEmpty {
            let (currentRoom, currentPath) = queue.removeFirst()
            
            // Skip if already visited
            if visited.contains(currentRoom) {
                continue
            }
            visited.insert(currentRoom)
            
            guard let room = graph.getRoom(currentRoom) else { continue }
            
            // Check all doors
            for (door, connection) in room.doors {
                if let (nextRoom, _) = connection {
                    let newPath = currentPath + String(door)
                    
                    // Found target?
                    if nextRoom == targetRoom {
                        return newPath
                    }
                    
                    // Add to queue if not visited
                    if !visited.contains(nextRoom) {
                        queue.append((nextRoom, newPath))
                    }
                }
            }
        }
        
        return nil
    }
}