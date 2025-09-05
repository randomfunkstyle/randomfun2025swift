import Foundation

/// Builds complete graph connections from room analysis
public class GraphConnectionBuilder {
    
    /// Build a complete MapDescription from analyzed rooms
    public func buildCompleteGraph(rooms: [StateTransitionAnalyzer.Room]) -> MapDescription {
        // Sort rooms by ID for consistent ordering
        let sortedRooms = rooms.sorted { $0.id < $1.id }
        
        // Build room labels array
        let roomLabels = sortedRooms.map { $0.label }
        
        // Build complete connection list
        var connections: [Connection] = []
        var connectionSet = Set<String>()  // To avoid duplicates
        
        for room in sortedRooms {
            for door in 0..<6 {
                if let connection = room.doors[door] {
                    let toRoomId = connection!.toRoomId
                    let toDoor = connection!.toDoor ?? door  // Default to same door if unknown
                    
                    // Create unique key to avoid duplicate connections
                    let key = "\(room.id):\(door)->\(toRoomId):\(toDoor)"
                    if !connectionSet.contains(key) {
                        connectionSet.insert(key)
                        
                        connections.append(Connection(
                            from: RoomDoor(room: room.id, door: door),
                            to: RoomDoor(room: toRoomId, door: toDoor)
                        ))
                    }
                }
            }
        }
        
        // Find the starting room (should be room with ID 0)
        let startingRoomId = sortedRooms.first(where: { room in
            room.states.contains("")  // Room containing the empty state
        })?.id ?? 0
        
        return MapDescription(
            rooms: roomLabels,
            startingRoom: startingRoomId,
            connections: connections
        )
    }
    
    /// Validate that the graph is complete
    public func validateGraph(rooms: [StateTransitionAnalyzer.Room]) -> (isComplete: Bool, issues: [String]) {
        var issues: [String] = []
        
        for room in rooms {
            var unmappedDoors: [Int] = []
            
            for door in 0..<6 {
                if room.doors[door] == nil {
                    unmappedDoors.append(door)
                }
            }
            
            if !unmappedDoors.isEmpty {
                issues.append("Room \(room.id) (label \(room.label)) has unmapped doors: \(unmappedDoors)")
            }
        }
        
        // Check for bidirectional consistency
        for room in rooms {
            for (door, connectionOpt) in room.doors {
                if let connection = connectionOpt {
                    let toRoomId = connection.toRoomId
                    let toDoor = connection.toDoor
                    
                    // Find the target room
                    if let targetRoom = rooms.first(where: { $0.id == toRoomId }) {
                        // Check if return connection exists
                        if let returnDoor = toDoor,
                           let returnConnection = targetRoom.doors[returnDoor] {
                            if returnConnection!.toRoomId != room.id {
                                issues.append("Bidirectional mismatch: Room \(room.id) door \(door) -> Room \(toRoomId) door \(returnDoor), but return goes to Room \(returnConnection!.toRoomId)")
                            }
                        }
                    }
                }
            }
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// Get statistics about the graph
    public func getGraphStatistics(rooms: [StateTransitionAnalyzer.Room]) -> String {
        var totalConnections = 0
        var selfLoops = 0
        var transitions = 0
        var unmappedDoors = 0
        
        for room in rooms {
            for (_, connection) in room.doors {
                if let connection = connection {
                    totalConnections += 1
                    if connection.toRoomId == room.id {
                        selfLoops += 1
                    } else {
                        transitions += 1
                    }
                } else {
                    unmappedDoors += 1
                }
            }
        }
        
        let avgConnectionsPerRoom = rooms.isEmpty ? 0.0 : Double(totalConnections) / Double(rooms.count)
        
        return """
        Graph Statistics:
          Rooms: \(rooms.count)
          Total connections: \(totalConnections)
          Self-loops: \(selfLoops)
          Transitions: \(transitions)
          Unmapped doors: \(unmappedDoors)
          Average connections per room: \(String(format: "%.1f", avgConnectionsPerRoom))
        """
    }
}