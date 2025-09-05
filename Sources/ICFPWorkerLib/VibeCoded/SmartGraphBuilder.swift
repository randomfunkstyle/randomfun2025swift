import Foundation

/// Builds graphs using pattern analysis instead of incremental room creation
public class SmartGraphBuilder {
    private let analyzer = PatternAnalyzer()
    private var analyzedRooms: [Int: PatternAnalyzer.IdentifiedRoom] = [:]
    private var startingLabel: Int = 0
    
    /// All exploration results collected so far
    private var allPaths: [String] = []
    private var allResults: [[Int]] = []
    
    /// Process a batch of exploration results
    public func processBatch(paths: [String], results: [[Int]]) {
        // Collect all data
        allPaths.append(contentsOf: paths)
        allResults.append(contentsOf: results)
        
        // Re-analyze with all data
        let (rooms, startLabel) = analyzer.analyzePatterns(paths: allPaths, results: allResults)
        analyzedRooms = rooms
        startingLabel = startLabel
    }
    
    /// Get the current graph structure
    public func getCurrentGraph() -> (rooms: [PatternAnalyzer.IdentifiedRoom], startingLabel: Int) {
        return (Array(analyzedRooms.values), startingLabel)
    }
    
    /// Check if the graph is completely mapped
    public func isComplete() -> Bool {
        return analyzer.isComplete(rooms: analyzedRooms)
    }
    
    /// Get completeness percentage
    public func getCompleteness() -> Double {
        return analyzer.completeness(rooms: analyzedRooms)
    }
    
    /// Get the number of unique rooms discovered
    public func getRoomCount() -> Int {
        return analyzedRooms.count
    }
    
    /// Convert to MapDescription for submission
    public func toMapDescription() -> MapDescription {
        // Create a mapping from labels to room IDs
        let sortedLabels = analyzedRooms.keys.sorted()
        var labelToId: [Int: Int] = [:]
        for (index, label) in sortedLabels.enumerated() {
            labelToId[label] = index
        }
        
        var connections: [Connection] = []
        
        // Build connections from analyzed rooms
        for room in analyzedRooms.values {
            let fromId = labelToId[room.label] ?? 0
            
            for door in 0..<6 {
                if let connection = room.doors[door] {
                    if let conn = connection {
                        let toId = labelToId[conn.toLabel] ?? 0
                        let toDoor = conn.toDoor ?? door  // Default to same door if unknown
                        
                        // Add the connection
                        let connection = Connection(
                            from: RoomDoor(room: fromId, door: door),
                            to: RoomDoor(room: toId, door: toDoor)
                        )
                        connections.append(connection)
                    }
                } else {
                    // No connection info - this shouldn't happen if we're complete
                    print("No connection found for door \(door) in room \(room.label)")
                }
            }
        }
        
        // Create room labels array
        let roomLabels = sortedLabels
        let startingRoomId = labelToId[startingLabel] ?? 0
        
        return MapDescription(
            rooms: roomLabels,
            startingRoom: startingRoomId,
            connections: connections
        )
    }
    
    /// Get suggested paths to explore next
    public func getSuggestedPaths() -> [String] {
        var suggestions: [String] = []
        
        // Priority 1: Single-door explorations we haven't tried
        let exploredSingleDoors = Set(allPaths.filter { $0.count == 1 })
        for door in 0..<6 {
            let doorStr = String(door)
            if !exploredSingleDoors.contains(doorStr) {
                suggestions.append(doorStr)
            }
        }
        
        // Priority 2: Two-door paths to find return connections
        for room in analyzedRooms.values {
            for (door, connection) in room.doors {
                if let conn = connection, conn.toDoor == nil {
                    // We know this door goes somewhere but don't know the return
                    // Try paths that might reveal the return connection
                    
                    // If from starting room, try going there and coming back
                    if room.label == startingLabel {
                        for returnDoor in 0..<6 {
                            let path = "\(door)\(returnDoor)"
                            if !allPaths.contains(path) && suggestions.count < 10 {
                                suggestions.append(path)
                            }
                        }
                    }
                }
            }
        }
        
        // Priority 3: Confirm suspected connections
        if suggestions.isEmpty {
            // Try some three-door paths that return home
            for door1 in 0..<6 {
                for door2 in 0..<6 {
                    for door3 in 0..<6 {
                        let path = "\(door1)\(door2)\(door3)"
                        if !allPaths.contains(path) && suggestions.count < 5 {
                            suggestions.append(path)
                        }
                    }
                }
            }
        }
        
        return suggestions
    }
    
    /// Confidence score based on completeness
    public func getConfidence() -> Double {
        let completeness = getCompleteness()
        let roomCount = getRoomCount()
        
        // For small graphs (2-3 rooms), high completeness means high confidence
        if roomCount <= 3 && completeness > 0.8 {
            return 0.95
        }
        
        // For simple patterns, we can be very confident
        if roomCount == 2 && hasSimplePattern() {
            return 0.97
        }
        
        return min(0.94, completeness)
    }
    
    /// Check if we have a simple pattern (one connection, rest self-loops)
    private func hasSimplePattern() -> Bool {
        guard analyzedRooms.count == 2 else { return false }
        
        var connectingDoors = 0
        var selfLoops = 0
        
        for room in analyzedRooms.values {
            for (_, connection) in room.doors {
                if let conn = connection {
                    if conn.toLabel == room.label {
                        selfLoops += 1
                    } else {
                        connectingDoors += 1
                    }
                }
            }
        }
        
        // Simple pattern: mostly self-loops with just a few connections
        return selfLoops >= 8 && connectingDoors <= 4
    }
}