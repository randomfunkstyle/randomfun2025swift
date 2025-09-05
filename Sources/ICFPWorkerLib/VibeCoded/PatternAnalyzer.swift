import Foundation

/// Analyzes exploration patterns to determine graph structure without creating phantom rooms
public class PatternAnalyzer {
    
    /// Represents a room identified by its label
    public struct IdentifiedRoom {
        public let label: Int
        public var doors: [Int: (toLabel: Int, toDoor: Int?)?] = [:]
        
        public init(label: Int) {
            self.label = label
            // Initialize all 6 doors as unknown
            for door in 0..<6 {
                doors[door] = nil
            }
        }
    }
    
    /// Analyze exploration results to build the complete graph structure
    public func analyzePatterns(paths: [String], results: [[Int]]) -> (rooms: [Int: IdentifiedRoom], startingLabel: Int) {
        guard !paths.isEmpty, !results.isEmpty else {
            return ([:], 0)
        }
        
        // Step 1: Identify unique room labels
        let uniqueLabels = Set(results.flatMap { $0 })
        var roomsByLabel: [Int: IdentifiedRoom] = [:]
        
        for label in uniqueLabels {
            roomsByLabel[label] = IdentifiedRoom(label: label)
        }
        
        let startingLabel = results.first?.first ?? 0
        
        // Step 2: Analyze single-door explorations first (most informative)
        analyzeSingleDoorPatterns(paths: paths, results: results, rooms: &roomsByLabel)
        
        // Step 3: Analyze multi-door paths to find return connections
        analyzeMultiDoorPatterns(paths: paths, results: results, rooms: &roomsByLabel)
        
        // Step 4: Infer bidirectional connections
        inferBidirectionalConnections(rooms: &roomsByLabel)
        
        return (roomsByLabel, startingLabel)
    }
    
    /// Analyze single-door explorations to identify self-loops and direct connections
    private func analyzeSingleDoorPatterns(paths: [String], results: [[Int]], rooms: inout [Int: IdentifiedRoom]) {
        for (path, labels) in zip(paths, results) where path.count == 1 && labels.count == 2 {
            guard let door = Int(path) else { continue }
            
            let fromLabel = labels[0]
            let toLabel = labels[1]
            
            if fromLabel == toLabel {
                // Self-loop detected
                rooms[fromLabel]?.doors[door] = (toLabel: fromLabel, toDoor: door)
            } else {
                // Connection to different room
                rooms[fromLabel]?.doors[door] = (toLabel: toLabel, toDoor: nil)
            }
        }
    }
    
    /// Analyze multi-door paths to discover return connections
    private func analyzeMultiDoorPatterns(paths: [String], results: [[Int]], rooms: inout [Int: IdentifiedRoom]) {
        for (path, labels) in zip(paths, results) where path.count > 1 {
            var currentLabel = labels[0]
            
            for (index, doorChar) in path.enumerated() {
                guard let door = Int(String(doorChar)),
                      index + 1 < labels.count else { continue }
                
                let nextLabel = labels[index + 1]
                
                // Update connection if not already known
                if rooms[currentLabel]?.doors[door] == nil {
                    if currentLabel == nextLabel {
                        rooms[currentLabel]?.doors[door] = (toLabel: currentLabel, toDoor: door)
                    } else {
                        rooms[currentLabel]?.doors[door] = (toLabel: nextLabel, toDoor: nil)
                    }
                }
                
                currentLabel = nextLabel
            }
            
            // Special case: paths that return to start help identify return doors
            if labels.count == path.count + 1 && labels.first == labels.last {
                analyzeReturnPath(path: path, labels: labels, rooms: &rooms)
            }
        }
    }
    
    /// Analyze paths that return to the starting room
    private func analyzeReturnPath(path: String, labels: [Int], rooms: inout [Int: IdentifiedRoom]) {
        // For path "03" with labels [0, 1, 0]:
        // Room 0 door 0 → Room 1
        // Room 1 door 3 → Room 0
        
        guard path.count == 2, labels.count == 3,
              labels[0] == labels[2], labels[0] != labels[1] else { return }
        
        if let firstDoor = Int(String(path.prefix(1))),
           let secondDoor = Int(String(path.suffix(1))) {
            let startLabel = labels[0]
            let middleLabel = labels[1]
            
            // Set the return connection
            rooms[middleLabel]?.doors[secondDoor] = (toLabel: startLabel, toDoor: firstDoor)
            rooms[startLabel]?.doors[firstDoor] = (toLabel: middleLabel, toDoor: secondDoor)
        }
    }
    
    /// Infer bidirectional connections where possible
    private func inferBidirectionalConnections(rooms: inout [Int: IdentifiedRoom]) {
        for (fromLabel, fromRoom) in rooms {
            for (fromDoor, connection) in fromRoom.doors {
                guard let connection = connection,
                      connection.toDoor == nil else { continue }
                
                let toLabel = connection.toLabel
                
                // Look for an unassigned door in the target room that could connect back
                if let toRoom = rooms[toLabel] {
                    for (toDoor, toConnection) in toRoom.doors {
                        if let toConn = toConnection,
                           toConn.toLabel == fromLabel && toConn.toDoor == nil {
                            // Found a matching return connection
                            rooms[fromLabel]?.doors[fromDoor] = (toLabel: toLabel, toDoor: toDoor)
                            rooms[toLabel]?.doors[toDoor] = (toLabel: fromLabel, toDoor: fromDoor)
                            break
                        }
                    }
                }
            }
        }
    }
    
    /// Determine if we have enough information to map the graph
    public func isComplete(rooms: [Int: IdentifiedRoom]) -> Bool {
        for room in rooms.values {
            for (_, connection) in room.doors {
                if connection == nil {
                    return false // Unknown door
                }
                if let conn = connection, conn.toDoor == nil {
                    return false // Unknown return door
                }
            }
        }
        return true
    }
    
    /// Calculate exploration completeness as a percentage
    public func completeness(rooms: [Int: IdentifiedRoom]) -> Double {
        let totalDoors = rooms.count * 6
        var knownConnections = 0
        var fullyKnownConnections = 0
        
        for room in rooms.values {
            for (_, connection) in room.doors {
                if let conn = connection {
                    knownConnections += 1
                    if conn.toDoor != nil {
                        fullyKnownConnections += 1
                    }
                }
            }
        }
        
        // Weight: 60% for knowing connections, 40% for knowing return doors
        let connectionRatio = Double(knownConnections) / Double(totalDoors)
        let fullRatio = Double(fullyKnownConnections) / Double(totalDoors)
        
        return connectionRatio * 0.6 + fullRatio * 0.4
    }
}