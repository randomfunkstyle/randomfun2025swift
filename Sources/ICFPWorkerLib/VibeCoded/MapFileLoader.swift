import Foundation

/// Loads map configurations from config files
public class MapFileLoader {
    
    public struct MapConfig {
        let roomIds: [String]      // ["A", "B", "C"]
        let roomLabels: [Int]      // [0, 1, 2]
        let startRoom: String       // "A"
        let connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)]
    }
    
    /// Load a map from a config file and ALWAYS auto-generate markdown
    public static func loadMap(from filename: String) throws -> MapConfig {
        // Try to find the file in Resources/MapConfigs
        let basePath = #file.replacingOccurrences(of: "Sources/ICFPWorkerLib/VibeCoded/MapFileLoader.swift", with: "")
        let mapPath = basePath + "Resources/MapConfigs/" + filename
        
        let content = try String(contentsOfFile: mapPath, encoding: .utf8)
        let config = try parseMap(content)
        
        // ALWAYS auto-generate markdown file to ensure consistency
        try generateMarkdownFile(from: config, configFilename: filename, basePath: basePath)
        
        return config
    }
    
    /// Generate and save markdown file from config
    private static func generateMarkdownFile(from config: MapConfig, configFilename: String, basePath: String) throws {
        // Convert MapConfig to MapConfigGenerator.ConfigMap format
        let configMap = MapConfigGenerator.ConfigMap(
            numRooms: config.roomIds.count,
            roomIds: config.roomIds,
            roomLabels: config.roomLabels,
            connections: config.connections
        )
        
        // Generate title from filename (remove .config extension)
        let title = configFilename
            .replacingOccurrences(of: ".config", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
        
        // Generate markdown content
        let markdown = MapConfigGenerator.generateMarkdown(config: configMap, title: title)
        
        // Save to TestMaps directory with .md extension
        let mdFilename = configFilename.replacingOccurrences(of: ".config", with: ".md")
        let mdPath = basePath + "Resources/TestMaps/" + mdFilename
        
        // Write the markdown file
        try markdown.write(toFile: mdPath, atomically: true, encoding: .utf8)
        
        print("📝 Generated markdown: \(mdFilename)")
    }
    
    /// Parse map content from config string with comprehensive validation
    public static func parseMap(_ content: String) throws -> MapConfig {
        let lines = content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard !lines.isEmpty else {
            throw ParseError.invalidFormat("Empty config file")
        }
        
        // First line should be number of rooms
        guard let numRooms = Int(lines[0]) else {
            throw ParseError.invalidFormat("First line must be number of rooms")
        }
        
        // Validate room count range (A-Z + a-z = 52 possible room IDs)
        guard numRooms >= 1 && numRooms <= 52 else {
            throw ParseError.validation("Number of rooms must be between 1 and 52, got \(numRooms)")
        }
        
        var roomIds: [String] = []
        var roomLabels: [Int] = []
        var connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)] = []
        
        var currentSection = ""
        var foundRoomsSection = false
        var foundConnectionsSection = false
        
        for line in lines.dropFirst() {
            if line.isEmpty { continue }
            
            if line == "ROOMS:" {
                currentSection = "ROOMS"
                foundRoomsSection = true
                continue
            } else if line == "CONNECTIONS:" {
                currentSection = "CONNECTIONS"
                foundConnectionsSection = true
                continue
            }
            
            if currentSection == "ROOMS" {
                let parts = line.split(separator: " ")
                guard parts.count == 2 else {
                    throw ParseError.invalidFormat("Invalid room format: '\(line)' - expected 'ROOM_ID LABEL'")
                }
                
                let roomId = String(parts[0])
                guard let label = Int(parts[1]) else {
                    throw ParseError.invalidFormat("Invalid room label in '\(line)' - label must be an integer")
                }
                
                // Validate room ID format (single letter)
                guard roomId.count == 1 && roomId.first?.isLetter == true else {
                    throw ParseError.validation("Room ID '\(roomId)' must be a single letter")
                }
                
                // Validate label range (0-3 for 2-bit labels)
                guard label >= 0 && label <= 3 else {
                    throw ParseError.validation("Room label \(label) must be between 0 and 3 (2-bit label)")
                }
                
                // Check for duplicate room IDs
                if roomIds.contains(roomId) {
                    throw ParseError.validation("Duplicate room ID: \(roomId)")
                }
                
                roomIds.append(roomId)
                roomLabels.append(label)
                
            } else if currentSection == "CONNECTIONS" {
                // Parse format: A0 B0
                let parts = line.split(separator: " ")
                guard parts.count == 2 else {
                    throw ParseError.invalidFormat("Invalid connection format: '\(line)' - expected 'FROM_ROOM_DOOR TO_ROOM_DOOR'")
                }
                
                let fromStr = String(parts[0])
                let toStr = String(parts[1])
                
                // Validate format: single letter followed by digit
                guard fromStr.count >= 2 && toStr.count >= 2 else {
                    throw ParseError.invalidFormat("Invalid connection format: '\(line)' - connections must be like 'A0 B1'")
                }
                
                guard let fromRoom = String(fromStr.prefix(1)).first,
                      let fromDoor = Int(fromStr.dropFirst()),
                      let toRoom = String(toStr.prefix(1)).first,
                      let toDoor = Int(toStr.dropFirst()) else {
                    throw ParseError.invalidFormat("Invalid connection format: '\(line)' - expected format like 'A0 B1'")
                }
                
                // Validate door numbers (0-5 for hexagonal rooms)
                guard fromDoor >= 0 && fromDoor <= 5 else {
                    throw ParseError.validation("Door number \(fromDoor) in '\(line)' must be between 0 and 5")
                }
                guard toDoor >= 0 && toDoor <= 5 else {
                    throw ParseError.validation("Door number \(toDoor) in '\(line)' must be between 0 and 5")
                }
                
                // Validate room IDs exist
                let fromRoomStr = String(fromRoom)
                let toRoomStr = String(toRoom)
                
                if !roomIds.contains(fromRoomStr) {
                    throw ParseError.validation("Unknown room '\(fromRoomStr)' in connection '\(line)'")
                }
                if !roomIds.contains(toRoomStr) {
                    throw ParseError.validation("Unknown room '\(toRoomStr)' in connection '\(line)'")
                }
                
                connections.append((
                    from: fromRoomStr,
                    fromDoor: fromDoor,
                    to: toRoomStr,
                    toDoor: toDoor
                ))
            } else if !line.isEmpty && currentSection.isEmpty {
                throw ParseError.invalidFormat("Unexpected content before sections: '\(line)'")
            }
        }
        
        // Validate required sections exist
        guard foundRoomsSection else {
            throw ParseError.validation("Missing required 'ROOMS:' section")
        }
        guard foundConnectionsSection else {
            throw ParseError.validation("Missing required 'CONNECTIONS:' section")
        }
        
        // Validate room count matches declaration
        guard roomIds.count == numRooms else {
            throw ParseError.validation("Expected \(numRooms) rooms, found \(roomIds.count) room definitions")
        }
        
        // Build a dictionary to track all connections for each room/door
        var doorConnections: [String: [Int: String]] = [:]
        for roomId in roomIds {
            doorConnections[roomId] = [:]
        }
        
        // Process connections as bidirectional
        for connection in connections {
            // Add forward direction
            if doorConnections[connection.from]?[connection.fromDoor] != nil {
                throw ParseError.validation("Duplicate connection for \(connection.from) door \(connection.fromDoor)")
            }
            doorConnections[connection.from]?[connection.fromDoor] = connection.to
            
            // Add reverse direction (bidirectional)
            if connection.from != connection.to || connection.fromDoor != connection.toDoor {
                if doorConnections[connection.to]?[connection.toDoor] != nil {
                    throw ParseError.validation("Duplicate connection for \(connection.to) door \(connection.toDoor)")
                }
                doorConnections[connection.to]?[connection.toDoor] = connection.from
            }
        }
        
        // Validate each room has exactly 6 doors connected
        for roomId in roomIds {
            let roomDoors = doorConnections[roomId] ?? [:]
            let doors = Set(roomDoors.keys)
            
            guard roomDoors.count == 6 else {
                throw ParseError.validation("Room \(roomId) has \(roomDoors.count) doors connected, must have exactly 6")
            }
            
            guard doors == Set(0...5) else {
                let missingDoors = Set(0...5).subtracting(doors)
                let extraDoors = doors.subtracting(Set(0...5))
                var message = "Room \(roomId) door validation failed"
                if !missingDoors.isEmpty {
                    message += " - missing doors: \(missingDoors.sorted())"
                }
                if !extraDoors.isEmpty {
                    message += " - invalid doors: \(extraDoors.sorted())"
                }
                throw ParseError.validation(message)
            }
        }
        
        // Validate room IDs are unique (already checked during parsing with duplicate check)
        // No need to enforce any specific ordering - rooms can be A, B, Z, a, d, etc.
        let uniqueRoomIds = Set(roomIds)
        guard uniqueRoomIds.count == roomIds.count else {
            throw ParseError.validation("Room IDs must be unique")
        }
        
        // Validate graph connectivity - all rooms must be reachable from the starting room
        if !roomIds.isEmpty {
            let startRoom = roomIds[0]
            var visited = Set<String>()
            var toVisit = [startRoom]
            
            // Build adjacency list from doorConnections
            var adjacency: [String: Set<String>] = [:]
            for room in roomIds {
                adjacency[room] = Set()
            }
            
            for (room, doors) in doorConnections {
                for (_, connectedRoom) in doors {
                    if connectedRoom != room { // Skip self-loops for connectivity check
                        adjacency[room]?.insert(connectedRoom)
                    }
                }
            }
            
            // BFS to find all reachable rooms
            while !toVisit.isEmpty {
                let current = toVisit.removeFirst()
                if visited.contains(current) {
                    continue
                }
                visited.insert(current)
                
                if let neighbors = adjacency[current] {
                    for neighbor in neighbors {
                        if !visited.contains(neighbor) {
                            toVisit.append(neighbor)
                        }
                    }
                }
            }
            
            // Check if all rooms were visited
            if visited.count != roomIds.count {
                let unreachable = Set(roomIds).subtracting(visited).sorted()
                throw ParseError.validation("Graph is not connected. Unreachable rooms: \(unreachable.joined(separator: ", "))")
            }
        }
        
        // Default start room to first room
        let startRoom = roomIds.isEmpty ? "A" : roomIds[0]
        
        return MapConfig(
            roomIds: roomIds,
            roomLabels: roomLabels,
            startRoom: startRoom,
            connections: connections
        )
    }
    
    public enum ParseError: Error {
        case invalidFormat(String)
        case validation(String)
    }
    
    /// Convert parsed map to MapDescription
    public static func createMapDescription(roomLabels: [Int], connections: [Int: [Int: Int]], startingRoom: Int = 0) -> MapDescription {
        var connectionList: [Connection] = []
        
        // Build connection list from the connections dictionary
        for (fromRoom, doors) in connections {
            for (fromDoor, toRoom) in doors {
                // Find the return door by checking the target room's connections
                var toDoor = fromDoor // Default to same door
                if let targetDoors = connections[toRoom] {
                    for (targetDoor, targetRoom) in targetDoors {
                        if targetRoom == fromRoom && targetDoor != fromDoor {
                            // Found a return connection on a different door
                            toDoor = targetDoor
                            break
                        }
                    }
                }
                
                // Only add connections once (from lower room number to higher, or self-loops)
                if fromRoom <= toRoom {
                    connectionList.append(Connection(
                        from: RoomDoor(room: fromRoom, door: fromDoor),
                        to: RoomDoor(room: toRoom, door: toDoor)
                    ))
                }
            }
        }
        
        return MapDescription(rooms: roomLabels, startingRoom: startingRoom, connections: connectionList)
    }
}