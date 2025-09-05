import Foundation

/// Debug validation issues
public class DebugValidation {
    
    public static func debugThreeRooms() {
        print("\n🔍 Debugging three_rooms_one_loop.config")
        print(String(repeating: "=", count: 50))
        
        do {
            // Load the config WITHOUT generating markdown
            let basePath = #file.replacingOccurrences(of: "Sources/ICFPWorkerLib/VibeCoded/DebugValidation.swift", with: "")
            let configPath = basePath + "Resources/MapConfigs/three_rooms_one_loop.config"
            let content = try String(contentsOfFile: configPath, encoding: .utf8)
            
            print("Config content:")
            print(content)
            print("\n" + String(repeating: "-", count: 50))
            
            let config = try MapFileLoader.parseMap(content)
            print("\nParsed \(config.connections.count) connections:")
            
            // Track what doors each room has
            var roomDoors: [String: Set<Int>] = [:]
            for room in config.roomIds {
                roomDoors[room] = []
            }
            
            // Process each connection
            for (i, conn) in config.connections.enumerated() {
                print("\(i+1). \(conn.from)\(conn.fromDoor) -> \(conn.to)\(conn.toDoor)")
                
                // This connection covers from:fromDoor
                roomDoors[conn.from]?.insert(conn.fromDoor)
                
                // If bidirectional (not a self-loop on same door), it also covers to:toDoor
                if conn.from != conn.to || conn.fromDoor != conn.toDoor {
                    roomDoors[conn.to]?.insert(conn.toDoor)
                    print("   (bidirectional: also covers \(conn.to)\(conn.toDoor) -> \(conn.from)\(conn.fromDoor))")
                }
            }
            
            print("\n" + String(repeating: "-", count: 50))
            print("Door coverage after processing bidirectional connections:")
            
            var totalDoors = 0
            for (room, doors) in roomDoors.sorted(by: { $0.key < $1.key }) {
                let missing = Set(0...5).subtracting(doors)
                totalDoors += doors.count
                
                print("Room \(room): \(doors.sorted()) - count: \(doors.count)/6")
                if !missing.isEmpty {
                    print("         ❌ Missing doors: \(missing.sorted())")
                }
            }
            
            print("\nTotal doors covered: \(totalDoors) (should be 18 for 3 rooms)")
            
            if totalDoors != 18 {
                print("❌ VALIDATION SHOULD FAIL - Not all doors are connected!")
            } else {
                print("✅ All doors properly connected")
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}