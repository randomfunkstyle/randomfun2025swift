import XCTest
@testable import ICFPWorkerLib

final class HexagonStructureTest: XCTestCase {
    
    func testHexagonMockClientStructure() {
        let mockClient = MockExplorationClient(layout: .hexagon)
        guard let mapDesc = mockClient.correctMap else {
            XCTFail("No map description available")
            return
        }
        
        print("=== HEXAGON STRUCTURE ANALYSIS ===")
        print("Room labels: \(mapDesc.rooms)")
        print("Starting room: \(mapDesc.startingRoom)")
        print("Total connections: \(mapDesc.connections.count)")
        
        // Group connections by room
        var roomConnections: [Int: [Int: Int]] = [:]
        for connection in mapDesc.connections {
            let fromRoom = connection.from.room
            let fromDoor = connection.from.door
            let toRoom = connection.to.room
            
            if roomConnections[fromRoom] == nil {
                roomConnections[fromRoom] = [:]
            }
            roomConnections[fromRoom]![fromDoor] = toRoom
        }
        
        // Print each room's connections
        for roomId in 0..<mapDesc.rooms.count {
            let label = mapDesc.rooms[roomId]
            let labelChar = String(Character(UnicodeScalar(65 + label)!))
            
            print("\nRoom \(roomId) (label \(labelChar)/\(label)):")
            if let connections = roomConnections[roomId] {
                var doorPattern = ""
                for door in 0..<6 {
                    if let targetRoom = connections[door] {
                        let targetLabel = mapDesc.rooms[targetRoom]
                        let targetChar = String(Character(UnicodeScalar(65 + targetLabel)!))
                        doorPattern += targetChar
                        print("  Door \(door) -> Room \(targetRoom) (label \(targetChar))")
                    } else {
                        doorPattern += "X"
                        print("  Door \(door) -> UNDEFINED")
                    }
                }
                print("  Pattern: \(labelChar):\(doorPattern)")
            } else {
                print("  No connections defined")
            }
        }
    }
}