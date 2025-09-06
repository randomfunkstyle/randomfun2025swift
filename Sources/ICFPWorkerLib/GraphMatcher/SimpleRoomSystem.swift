import Foundation

/// Ultra-simple room representation - just a label and 6-character door string
public struct SimpleRoom {
    public let label: RoomLabel
    public var doors: String  // 6 characters, each representing what that door leads to
    public let path: String  // The path from start to reach this room
    
    public init(label: RoomLabel, path: String = "") {
        self.label = label
        self.doors = "XXXXXX"  // Unknown doors initially
        self.path = path
    }
    
    /// Check if this room is fully explored (no X's in doors)
    public var isComplete: Bool {
        return !doors.contains("X")
    }
    
    /// Get the signature for this room (will be computed dynamically based on exploration depth needed)
    public func getSignature(depth: Int, roomCollection: SimpleRoomCollection) -> String {
        var signature = ""
        
        // Add doors at each depth level (no label prefix, just the pattern)
        for currentDepth in 1...depth {
            if currentDepth > 1 {
                signature += ":"
            }
            if currentDepth == 1 {
                signature += doors
            } else {
                // For deeper levels, trace paths and get the labels
                signature += getDoorsAtDepth(depth: currentDepth, roomCollection: roomCollection)
            }
        }
        
        return signature
    }
    
    /// Get the signature with label for display purposes
    public func getDisplaySignature(depth: Int, roomCollection: SimpleRoomCollection) -> String {
        return "\(label.rawValue):\(getSignature(depth: depth, roomCollection: roomCollection))"
    }
    
    /// Get what each door leads to at a specific depth
    private func getDoorsAtDepth(depth: Int, roomCollection: SimpleRoomCollection) -> String {
        var doorsAtDepth = ""
        
        for door in 0..<6 {
            if getDoorDestination(door) != nil {
                // Trace this path to the specified depth
                let pathToTrace = String(repeating: String(door), count: depth)
                let finalLabel = roomCollection.tracePath(fromPath: self.path, additionalPath: pathToTrace)
                doorsAtDepth += finalLabel?.rawValue ?? "X"
            } else {
                doorsAtDepth += "X"
            }
        }
        
        return doorsAtDepth
    }
    
    /// Set what a specific door leads to
    public mutating func setDoor(_ doorNumber: Int, leadsTo destination: RoomLabel) {
        guard doorNumber >= 0 && doorNumber < 6 else { return }
        
        var doorArray = Array(doors)
        doorArray[doorNumber] = Character(destination.rawValue)
        doors = String(doorArray)
    }
    
    /// Get what a specific door leads to (nil if unknown)
    public func getDoorDestination(_ doorNumber: Int) -> RoomLabel? {
        guard doorNumber >= 0 && doorNumber < 6 else { return nil }
        let char = doors[doors.index(doors.startIndex, offsetBy: doorNumber)]
        return char == "X" ? nil : RoomLabel(rawValue: String(char))
    }
}

/// Simple room collection that builds rooms from exploration results
public class SimpleRoomCollection {
    // Store rooms by the shortest path to reach them from start
    // This allows multiple rooms with the same label
    private var roomsByPath: [String: SimpleRoom] = [:]
    
    public init() {}
    
    /// Get or create a room at a specific path
    public func getOrCreateRoomAtPath(_ path: String, label: RoomLabel) -> SimpleRoom {
        if roomsByPath[path] == nil {
            roomsByPath[path] = SimpleRoom(label: label, path: path)
        }
        return roomsByPath[path]!
    }
    
    /// Update a room's door connection
    public func setRoomDoorAtPath(path: String, roomLabel: RoomLabel, door: Int, destination: RoomLabel) {
        var room = getOrCreateRoomAtPath(path, label: roomLabel)
        room.setDoor(door, leadsTo: destination)
        roomsByPath[path] = room
    }
    
    /// Get all rooms
    public func getAllRooms() -> [SimpleRoom] {
        return Array(roomsByPath.values)
    }
    
    /// Get rooms with complete door information
    public func getCompleteRooms() -> [SimpleRoom] {
        return roomsByPath.values.filter { $0.isComplete }
    }
    
    /// Count unique signatures among complete rooms
    /// Returns the count of unique connection patterns (signatures)
    public func countUniqueSignatures() -> Int {
        let completeRooms = getCompleteRooms()
        
        // Just return the count of unique depth-1 signatures
        // This represents the number of unique room types based on their connection patterns
        let signatures = Set(completeRooms.map { $0.getSignature(depth: 1, roomCollection: self) })
        
        print("Complete rooms: \(completeRooms.count), Unique signatures: \(signatures.count)")
        
        // Show the unique signatures found
        for sig in signatures.sorted() {
            // Find an example room with this signature for display
            if let exampleRoom = completeRooms.first(where: { $0.getSignature(depth: 1, roomCollection: self) == sig }) {
                print("  Unique signature: \(exampleRoom.getDisplaySignature(depth: 1, roomCollection: self))")
            }
        }
        
        return signatures.count
    }
    
    /// Get groups of rooms with identical signatures (complete rooms only)
    public func getSignatureGroups() -> [[RoomLabel]] {
        let completeRooms = getCompleteRooms()
        var signatureGroups: [String: [RoomLabel]] = [:]
        
        // Try increasing depth until we get unique signatures for all complete rooms
        for depth in 1...10 {
            signatureGroups.removeAll()
            
            for room in completeRooms {
                let signature = room.getSignature(depth: depth, roomCollection: self)
                signatureGroups[signature, default: []].append(room.label)
            }
            
            // If all rooms are uniquely distinguished, return the groups
            if signatureGroups.values.allSatisfy({ $0.count == 1 }) {
                return signatureGroups.values.map { $0.sorted { $0.rawValue < $1.rawValue } }
            }
        }
        
        // Fallback - return groups even if not all unique
        return signatureGroups.values.map { $0.sorted { $0.rawValue < $1.rawValue } }
    }
    
    /// Trace a path from the starting room and return the final room label
    /// - Parameters:
    ///   - fromPath: The path to the starting room
    ///   - additionalPath: Additional doors to follow
    /// - Returns: The label of the final room reached, or nil if path cannot be followed
    public func tracePath(fromPath: String, additionalPath: String) -> RoomLabel? {
        guard let startRoom = roomsByPath[fromPath] else {
            return nil
        }
        
        var currentPath = fromPath
        var currentRoom = startRoom
        
        for doorChar in additionalPath {
            guard let doorNumber = Int(String(doorChar)), doorNumber >= 0 && doorNumber < 6 else {
                return nil
            }
            
            // See where this door leads
            guard currentRoom.getDoorDestination(doorNumber) != nil else {
                return nil // Door not explored yet
            }
            
            // Find the room with this label that's reachable from currentPath + door
            let nextPath = currentPath.isEmpty ? String(doorNumber) : currentPath + String(doorNumber)
            
            // First check if we have a room at this exact path
            if let nextRoom = roomsByPath[nextPath] {
                currentRoom = nextRoom
                currentPath = nextPath
            } else {
                // Can't continue - we don't know this room yet
                return nil
            }
        }
        
        return currentRoom.label
    }
    
    /// Debug: print all room signatures
    public func printAllSignatures() {
        print("=== ROOM SIGNATURES ===")
        for (path, room) in roomsByPath.sorted(by: { $0.key < $1.key }) {
            let status = room.isComplete ? "COMPLETE" : "INCOMPLETE"
            let signature = room.getDisplaySignature(depth: 2, roomCollection: self)
            let pathDisplay = path.isEmpty ? "START" : path
            print("Room at path '\(pathDisplay)' (\(room.label.rawValue)): \(signature) (\(status))")
        }
    }
}

extension GraphMatcher {
    
    /// Build simple rooms from exploration results
    public func buildSimpleRooms(from results: [PathResult]) -> SimpleRoomCollection {
        let roomCollection = SimpleRoomCollection()
        
        print("Building simple rooms from \(results.count) exploration results...")
        
        // First, ensure the starting room exists
        _ = roomCollection.getOrCreateRoomAtPath("", label: .A)
        
        for result in results {
            // Skip if labels don't match path length + 1
            guard result.observedLabels.count == result.path.count + 1 else { continue }
            
            // Build up the path step by step
            var currentPath = ""
            
            for i in 0..<result.path.count {
                guard let door = Int(String(result.path[result.path.index(result.path.startIndex, offsetBy: i)])) else { continue }
                guard door >= 0 && door < 6 else { continue }
                
                let currentRoomLabel = result.observedLabels[i]
                let nextRoomLabel = result.observedLabels[i + 1]
                
                // Get or create the current room at this path
                let currentRoom = roomCollection.getOrCreateRoomAtPath(currentPath, label: currentRoomLabel)
                
                // Calculate the path to the next room
                let nextPath = currentPath.isEmpty ? String(door) : currentPath + String(door)
                
                // Get or create the next room at its path
                _ = roomCollection.getOrCreateRoomAtPath(nextPath, label: nextRoomLabel)
                
                // Update the door connection (only if not already set)
                if currentRoom.getDoorDestination(door) == nil {
                    roomCollection.setRoomDoorAtPath(path: currentPath, roomLabel: currentRoomLabel, door: door, destination: nextRoomLabel)
                    let pathDisplay = currentPath.isEmpty ? "START" : currentPath
                    print("  Room[\(pathDisplay)](\(currentRoomLabel.rawValue)) door \(door) -> Room[\(nextPath)](\(nextRoomLabel.rawValue))")
                }
                
                // Move to the next room for the next iteration
                currentPath = nextPath
            }
        }
        
        roomCollection.printAllSignatures()
        return roomCollection
    }
}