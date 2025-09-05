import Foundation

/// Loads map configurations from markdown files
public class MapFileLoader {
    
    public struct MapConfig {
        let roomIds: [String]      // ["A", "B", "C"]
        let roomLabels: [Int]      // [0, 1, 2]
        let startRoom: String       // "A"
        let connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)]
    }
    
    /// Load a map from a markdown file
    public static func loadMap(from filename: String) throws -> MapConfig {
        // Try to find the file in Resources/TestMaps
        let basePath = #file.replacingOccurrences(of: "Sources/ICFPWorkerLib/VibeCoded/MapFileLoader.swift", with: "")
        let mapPath = basePath + "Resources/TestMaps/" + filename
        
        let content = try String(contentsOfFile: mapPath, encoding: .utf8)
        return parseMap(content)
    }
    
    /// Parse map content from markdown string
    public static func parseMap(_ content: String) -> MapConfig {
        var roomIds: [String] = []
        var roomLabels: [Int] = []
        var startRoom = "A"
        var connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)] = []
        
        let lines = content.split(separator: "\n")
        
        // Find the Config section
        var inConfigSection = false
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed == "```" {
                if inConfigSection {
                    break // End of config section
                } else if index > 0 && lines[index - 1].contains("Config") {
                    inConfigSection = true
                    continue
                }
            }
            
            if !inConfigSection {
                continue
            }
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            if trimmed.hasPrefix("ROOMS") {
                // Parse: ROOMS A:0 B:1 C:2
                let parts = trimmed.replacingOccurrences(of: "ROOMS", with: "").split(separator: " ")
                for part in parts {
                    let roomParts = part.split(separator: ":")
                    if roomParts.count == 2 {
                        roomIds.append(String(roomParts[0]))
                        roomLabels.append(Int(roomParts[1]) ?? 0)
                    }
                }
            } else if trimmed.hasPrefix("START") {
                // Parse: START A
                startRoom = trimmed.replacingOccurrences(of: "START", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.count >= 4 {
                // Parse connections: A0 B0
                let parts = trimmed.split(separator: " ")
                if parts.count == 2 {
                    let from = String(parts[0])
                    let to = String(parts[1])
                    
                    // Extract room and door from "A0" format
                    if from.count >= 2, to.count >= 2 {
                        let fromRoom = String(from.dropLast())
                        let fromDoor = Int(String(from.last!)) ?? 0
                        let toRoom = String(to.dropLast())
                        let toDoor = Int(String(to.last!)) ?? 0
                        
                        connections.append((from: fromRoom, fromDoor: fromDoor, to: toRoom, toDoor: toDoor))
                    }
                }
            }
        }
        
        return MapConfig(
            roomIds: roomIds,
            roomLabels: roomLabels,
            startRoom: startRoom,
            connections: connections
        )
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