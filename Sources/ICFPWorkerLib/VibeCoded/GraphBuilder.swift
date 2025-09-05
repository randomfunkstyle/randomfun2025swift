import Foundation

/// Builds and maintains the graph structure of the hexagonal library
/// Processes exploration results to construct room connections
public class GraphBuilder {
    /// Represents a single hexagonal room in the library
    public struct Room {
        /// Unique identifier for the room
        public let id: Int
        /// 2-bit label value (0-3) observed when visiting the room
        public var label: Int?
        /// Maps door number (0-5) to connection info (target room and door)
        /// nil means unexplored, Some(x, -1) means explored but return door unknown
        public var doors: [Int: (toRoom: Int, toDoor: Int)?] = [:]
        
        /// Initialize a room with all 6 doors set to unexplored (nil)
        public init(id: Int, label: Int? = nil) {
            self.id = id
            self.label = label
            // Hexagonal rooms always have 6 doors
            for door in 0..<6 {
                doors[door] = nil
            }
        }
    }
    
    /// All discovered rooms indexed by their ID
    private var rooms: [Int: Room] = [:]
    /// The ID of the room where all explorations begin
    private var startingRoom: Int
    /// Counter for assigning unique IDs to newly discovered rooms
    private var nextRoomId: Int = 0
    
    /// Initialize with an optional label for the starting room
    public init(startingRoomLabel: Int? = nil) {
        self.startingRoom = nextRoomId
        rooms[startingRoom] = Room(id: startingRoom, label: startingRoomLabel)
        nextRoomId += 1
    }
    
    public func getStartingRoom() -> Int {
        return startingRoom
    }
    
    public func getRoom(_ id: Int) -> Room? {
        return rooms[id]
    }
    
    public func getAllRooms() -> [Room] {
        return Array(rooms.values)
    }
    
    /// Process an exploration path and its observed labels
    /// Updates room labels and creates new rooms as needed
    /// - Parameters:
    ///   - path: Sequence of door numbers (e.g., "012" means door 0, then 1, then 2)
    ///   - labels: Room labels observed at each step (including starting room)
    /// - Returns: Array of room IDs visited in order
    public func processExploration(path: String, labels: [Int]) -> [Int] {
        guard !path.isEmpty else { return [] }
        
        var currentRoom = startingRoom
        var visitedRooms: [Int] = [currentRoom]
        
        // Apply label to starting room if provided
        if let label = labels.first {
            rooms[currentRoom]?.label = label
        }
        
        // Check for simple self-loop pattern
        if path.count == 1 && labels.count == 2 && labels[0] == labels[1] {
            if let door = Int(path) {
                // This door is a self-loop
                setConnection(from: currentRoom, door: door, to: currentRoom, door: door)
                visitedRooms.append(currentRoom)
                return visitedRooms
            }
        }
        
        // Walk through the path, creating rooms as needed
        for (index, doorChar) in path.enumerated() {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            // Check if this might be returning to an existing room
            let nextLabel = (index + 1 < labels.count) ? labels[index + 1] : nil
            let nextRoom = traverseDoorWithLabel(from: currentRoom, through: door, expectedLabel: nextLabel)
            
            // Apply label to the room we just entered
            if index + 1 < labels.count {
                rooms[nextRoom]?.label = labels[index + 1]
            }
            
            currentRoom = nextRoom
            visitedRooms.append(currentRoom)
        }
        
        // Check if we returned to starting room
        if visitedRooms.count == labels.count && labels.last == labels.first {
            // We might have returned to the starting room
            let lastRoom = visitedRooms.last!
            if lastRoom != startingRoom && rooms[lastRoom]?.label == rooms[startingRoom]?.label {
                // Merge these rooms - they're the same
                mergeRooms(startingRoom, lastRoom)
                visitedRooms[visitedRooms.count - 1] = startingRoom
            }
        }
        
        return visitedRooms
    }
    
    /// Traverse a door from a room with an expected label hint
    /// - Parameters:
    ///   - roomId: Current room ID
    ///   - door: Door number to traverse (0-5)
    ///   - expectedLabel: The label we expect to find (if known)
    /// - Returns: ID of the room reached through the door
    private func traverseDoorWithLabel(from roomId: Int, through door: Int, expectedLabel: Int?) -> Int {
        guard let room = rooms[roomId] else { return roomId }
        
        // If we already know where this door leads, go there
        if let connection = room.doors[door], let (toRoom, _) = connection {
            return toRoom
        }
        
        // Check if we might be returning to an existing room
        if let expectedLabel = expectedLabel {
            // Look for existing rooms with this label
            for (existingRoomId, existingRoom) in rooms {
                if existingRoom.label == expectedLabel && existingRoomId != roomId {
                    // Check if this room has an unknown connection that could lead back
                    for (existingDoor, existingConnection) in existingRoom.doors {
                        if existingConnection == nil || 
                           (existingConnection?.toDoor == -1 && existingConnection?.toRoom == roomId) {
                            // This could be our return connection
                            rooms[roomId]?.doors[door] = (toRoom: existingRoomId, toDoor: existingDoor)
                            rooms[existingRoomId]?.doors[existingDoor] = (toRoom: roomId, toDoor: door)
                            return existingRoomId
                        }
                    }
                }
            }
        }
        
        // Create a new room for this unexplored door
        let newRoomId = nextRoomId
        nextRoomId += 1
        rooms[newRoomId] = Room(id: newRoomId, label: expectedLabel)
        
        // Mark the connection (we don't know the return door yet, so use -1)
        rooms[roomId]?.doors[door] = (toRoom: newRoomId, toDoor: -1)
        
        return newRoomId
    }
    
    /// Traverse a door from a room, creating a new room if needed
    /// - Parameters:
    ///   - roomId: Current room ID
    ///   - door: Door number to traverse (0-5)
    /// - Returns: ID of the room reached through the door
    private func traverseDoor(from roomId: Int, through door: Int) -> Int {
        return traverseDoorWithLabel(from: roomId, through: door, expectedLabel: nil)
    }
    
    /// Manually set a bidirectional door connection
    /// Used when we discover how rooms connect to each other
    public func setConnection(from fromRoom: Int, door fromDoor: Int, to toRoom: Int, door toDoor: Int) {
        rooms[fromRoom]?.doors[fromDoor] = (toRoom: toRoom, toDoor: toDoor)
    }
    
    /// Merge two rooms that are actually the same room
    /// This happens when we discover a cycle in the graph
    /// - Parameters:
    ///   - room1: Room to keep (merge target)
    ///   - room2: Room to remove (will be merged into room1)
    public func mergeRooms(_ room1: Int, _ room2: Int) {
        guard room1 != room2,
              let r2 = rooms[room2] else { return }
        
        // Update all references to room2 to point to room1
        for (fromRoom, room) in rooms {
            for (door, connection) in room.doors {
                if let (toRoom, toDoor) = connection, toRoom == room2 {
                    rooms[fromRoom]?.doors[door] = (toRoom: room1, toDoor: toDoor)
                }
            }
        }
        
        // Merge door information from room2 into room1
        if let r1 = rooms[room1] {
            for (door, connection) in r2.doors {
                // Only add connections we don't already know about
                if rooms[room1]?.doors[door] == nil {
                    rooms[room1]?.doors[door] = connection
                }
            }
            
            // Prefer known labels over unknown
            if r1.label == nil && r2.label != nil {
                rooms[room1]?.label = r2.label
            }
        }
        
        // Remove the merged room
        rooms.removeValue(forKey: room2)
    }
    
    /// Detect connection patterns from multiple single-door explorations
    /// Identifies self-loops and connections to other rooms
    public func detectConnectionPatterns(paths: [String], results: [[Int]]) {
        for (path, labels) in zip(paths, results) where path.count == 1 && labels.count == 2 {
            guard let door = Int(path) else { continue }
            
            let fromRoomLabel = labels[0]
            let toRoomLabel = labels[1]
            
            // Find the room with the starting label
            let fromRoom = rooms.first { $0.value.label == fromRoomLabel }?.key ?? startingRoom
            
            if fromRoomLabel == toRoomLabel {
                // Self-loop detected
                setConnection(from: fromRoom, door: door, to: fromRoom, door: door)
            } else {
                // Connection to a different room
                // This helps identify which doors actually lead to other rooms
                if let existingToRoom = rooms.first(where: { $0.value.label == toRoomLabel && $0.key != fromRoom })?.key {
                    // Connect to existing room with that label
                    rooms[fromRoom]?.doors[door] = (toRoom: existingToRoom, toDoor: -1)
                }
            }
        }
        
        // Also consolidate rooms with the same label after pattern detection
        consolidateDuplicateRooms()
    }
    
    /// Consolidate rooms that have the same label (likely duplicates)
    private func consolidateDuplicateRooms() {
        let labelGroups = Dictionary(grouping: rooms.values) { $0.label }
        
        for (label, group) in labelGroups where label != nil && group.count > 1 {
            // Keep the room with the most connections
            let sortedByConnections = group.sorted { room1, room2 in
                let conn1 = room1.doors.values.compactMap { $0 }.count
                let conn2 = room2.doors.values.compactMap { $0 }.count
                return conn1 > conn2
            }
            
            guard let primary = sortedByConnections.first else { continue }
            
            // Merge all others into the primary
            for secondary in sortedByConnections.dropFirst() {
                if primary.id != secondary.id {
                    mergeRooms(primary.id, secondary.id)
                }
            }
        }
    }
    
    /// Convert the internal graph to the API's MapDescription format
    /// - Returns: MapDescription ready for submission
    public func toMapDescription() -> MapDescription {
        let roomIds = Array(rooms.keys).sorted()
        var connections: [Connection] = []
        
        // Build connection list from all known door connections
        for (roomId, room) in rooms {
            for (door, connection) in room.doors {
                // Only include fully known connections (toDoor >= 0)
                if let (toRoom, toDoor) = connection, toDoor >= 0 {
                    let conn = Connection(
                        from: RoomDoor(room: roomId, door: door),
                        to: RoomDoor(room: toRoom, door: toDoor)
                    )
                    connections.append(conn)
                }
            }
        }
        
        // Extract room labels (using 0 as default for unknown labels)
        let labels = roomIds.compactMap { rooms[$0]?.label ?? 0 }
        
        return MapDescription(
            rooms: labels,
            startingRoom: roomIds.firstIndex(of: startingRoom) ?? 0,
            connections: connections
        )
    }
}