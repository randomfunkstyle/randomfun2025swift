import Foundation

/// Generates markdown files from simple config files and validates map structure
public class MapConfigGenerator {
    
    public struct ConfigMap {
        public let numRooms: Int
        public let roomIds: [String]
        public let roomLabels: [Int]
        public let connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)]
        
        public init(numRooms: Int, roomIds: [String], roomLabels: [Int], connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)]) {
            self.numRooms = numRooms
            self.roomIds = roomIds
            self.roomLabels = roomLabels
            self.connections = connections
        }
    }
    
    /// Load and validate a config file
    public static func loadConfig(from filename: String) throws -> ConfigMap {
        let basePath = #file.replacingOccurrences(of: "Sources/ICFPWorkerLib/VibeCoded/MapConfigGenerator.swift", with: "")
        let configPath = basePath + "Resources/MapConfigs/" + filename
        
        let content = try String(contentsOfFile: configPath, encoding: .utf8)
        return try parseConfig(content)
    }
    
    /// Parse and validate config content
    public static func parseConfig(_ content: String) throws -> ConfigMap {
        let lines = content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard !lines.isEmpty else {
            throw ConfigError.invalidFormat("Empty config file")
        }
        
        // First line should be number of rooms
        guard let numRooms = Int(lines[0]) else {
            throw ConfigError.invalidFormat("First line must be number of rooms")
        }
        
        var roomIds: [String] = []
        var roomLabels: [Int] = []
        var connections: [(from: String, fromDoor: Int, to: String, toDoor: Int)] = []
        
        var currentSection = ""
        var roomCount = 0
        var connectionCount = 0
        
        for line in lines.dropFirst() {
            if line.isEmpty { continue }
            
            if line == "ROOMS:" {
                currentSection = "ROOMS"
                continue
            } else if line == "CONNECTIONS:" {
                currentSection = "CONNECTIONS"
                continue
            }
            
            if currentSection == "ROOMS" {
                let parts = line.split(separator: " ")
                guard parts.count == 2,
                      let label = Int(parts[1]) else {
                    throw ConfigError.invalidFormat("Invalid room format: \(line)")
                }
                
                roomIds.append(String(parts[0]))
                roomLabels.append(label)
                roomCount += 1
            } else if currentSection == "CONNECTIONS" {
                // Parse format: A0 B0
                guard line.count >= 4 else {
                    throw ConfigError.invalidFormat("Invalid connection format: \(line)")
                }
                
                let parts = line.split(separator: " ")
                guard parts.count == 2 else {
                    throw ConfigError.invalidFormat("Invalid connection format: \(line)")
                }
                
                let fromStr = String(parts[0])
                let toStr = String(parts[1])
                
                guard let fromRoom = String(fromStr.prefix(1)).first,
                      let fromDoor = Int(fromStr.dropFirst()),
                      let toRoom = String(toStr.prefix(1)).first,
                      let toDoor = Int(toStr.dropFirst()) else {
                    throw ConfigError.invalidFormat("Invalid connection format: \(line)")
                }
                
                connections.append((
                    from: String(fromRoom),
                    fromDoor: fromDoor,
                    to: String(toRoom),
                    toDoor: toDoor
                ))
                connectionCount += 1
            }
        }
        
        // Validation
        guard roomCount == numRooms else {
            throw ConfigError.validation("Expected \(numRooms) rooms, found \(roomCount)")
        }
        
        // Each room should have exactly 6 connections (doors 0-5)
        let expectedConnections = numRooms * 6
        guard connectionCount == expectedConnections else {
            throw ConfigError.validation("Expected \(expectedConnections) connections, found \(connectionCount)")
        }
        
        return ConfigMap(
            numRooms: numRooms,
            roomIds: roomIds,
            roomLabels: roomLabels,
            connections: connections
        )
    }
    
    /// Generate markdown file from config
    public static func generateMarkdown(config: ConfigMap, title: String) -> String {
        var markdown = "# \(title)\n\n```mermaid\ngraph TD\n"
        
        // Add room declarations
        for (id, label) in zip(config.roomIds, config.roomLabels) {
            markdown += "    \(id)((\(id):\(label)))\n"
        }
        markdown += "\n"
        
        // Group connections by type
        var bidirectional: [(String, Int, String)] = []
        var selfLoops: [(String, Int)] = []
        
        for conn in config.connections {
            if conn.from == conn.to {
                selfLoops.append((conn.from, conn.fromDoor))
            } else {
                // Check if this is the first direction of a bidirectional connection
                let reverse = config.connections.first {
                    $0.from == conn.to && $0.to == conn.from && $0.fromDoor == conn.toDoor && $0.toDoor == conn.fromDoor
                }
                if reverse != nil && conn.from < conn.to {
                    bidirectional.append((conn.from, conn.fromDoor, conn.to))
                }
            }
        }
        
        // Add bidirectional connections
        for (from, door, to) in bidirectional {
            markdown += "    \(from) -.\(door).- \(to)\n"
        }
        
        if !bidirectional.isEmpty && !selfLoops.isEmpty {
            markdown += "\n"
        }
        
        // Add self loops
        for (room, door) in selfLoops.sorted(by: { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }) {
            markdown += "    \(room) --\(door)--> \(room)\n"
        }
        
        markdown += "```\n"
        return markdown
    }
    
    public enum ConfigError: Error {
        case invalidFormat(String)
        case validation(String)
    }
}