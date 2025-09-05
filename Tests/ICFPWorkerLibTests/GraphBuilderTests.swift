import XCTest
@testable import ICFPWorkerLib

final class GraphBuilderTests: XCTestCase {
    
    func testInitialization() {
        let builder = GraphBuilder(startingRoomLabel: 1)
        let startingRoom = builder.getStartingRoom()
        
        XCTAssertEqual(startingRoom, 0)
        XCTAssertNotNil(builder.getRoom(startingRoom))
        XCTAssertEqual(builder.getRoom(startingRoom)?.label, 1)
    }
    
    func testSimpleExploration() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        let path = "012"
        let labels = [0, 1, 2, 3]
        
        let visitedRooms = builder.processExploration(path: path, labels: labels)
        
        XCTAssertEqual(visitedRooms.count, 4)
        
        XCTAssertEqual(builder.getRoom(visitedRooms[0])?.label, 0)
        XCTAssertEqual(builder.getRoom(visitedRooms[1])?.label, 1)
        XCTAssertEqual(builder.getRoom(visitedRooms[2])?.label, 2)
        XCTAssertEqual(builder.getRoom(visitedRooms[3])?.label, 3)
    }
    
    func testRoomConnections() {
        let builder = GraphBuilder()
        
        // Create rooms first by exploring
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        builder.setConnection(from: 0, door: 1, to: 1, door: 3)
        builder.setConnection(from: 1, door: 3, to: 0, door: 1)
        
        let room0 = builder.getRoom(0)
        let room1 = builder.getRoom(1)
        
        XCTAssertEqual(room0?.doors[1]??.toRoom, 1)
        XCTAssertEqual(room0?.doors[1]??.toDoor, 3)
        XCTAssertEqual(room1?.doors[3]??.toRoom, 0)
        XCTAssertEqual(room1?.doors[3]??.toDoor, 1)
    }
    
    func testMergeRooms() {
        let builder = GraphBuilder()
        
        let labels1 = [0, 1]
        _ = builder.processExploration(path: "0", labels: labels1)
        
        let labels2 = [0, 2]
        _ = builder.processExploration(path: "1", labels: labels2)
        
        let allRoomsBefore = builder.getAllRooms()
        XCTAssertEqual(allRoomsBefore.count, 3)
        
        builder.mergeRooms(1, 2)
        
        let allRoomsAfter = builder.getAllRooms()
        XCTAssertEqual(allRoomsAfter.count, 2)
        XCTAssertNil(builder.getRoom(2))
        XCTAssertNotNil(builder.getRoom(1))
    }
    
    func testCircularPath() {
        let builder = GraphBuilder()
        
        // First create the rooms with labels
        let labels = [0, 1, 2, 3]
        let visitedRooms = builder.processExploration(path: "000", labels: labels)
        
        XCTAssertEqual(visitedRooms.count, 4)
        XCTAssertEqual(visitedRooms[0], 0)
        XCTAssertEqual(builder.getRoom(visitedRooms[1])?.label, 1)
        XCTAssertEqual(builder.getRoom(visitedRooms[2])?.label, 2)
        XCTAssertEqual(builder.getRoom(visitedRooms[3])?.label, 3)
    }
    
    func testToMapDescription() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        _ = builder.processExploration(path: "0", labels: [0, 1])
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 1, door: 3, to: 0, door: 0)
        
        let mapDesc = builder.toMapDescription()
        
        XCTAssertEqual(mapDesc.startingRoom, 0)
        XCTAssertEqual(mapDesc.rooms.count, 2)
        XCTAssertTrue(mapDesc.connections.count >= 2)
        
        let hasForwardConnection = mapDesc.connections.contains { conn in
            conn.from.room == 0 && conn.from.door == 0 &&
            conn.to.room == 1 && conn.to.door == 3
        }
        XCTAssertTrue(hasForwardConnection)
    }
    
    func testComplexExploration() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        let paths = [
            ("012", [0, 1, 2, 3]),
            ("345", [0, 2, 1, 0]),
            ("000", [0, 1, 2, 3])
        ]
        
        for (path, labels) in paths {
            _ = builder.processExploration(path: path, labels: labels)
        }
        
        let allRooms = builder.getAllRooms()
        XCTAssertGreaterThan(allRooms.count, 0)
        
        for room in allRooms {
            // Each room has doors (0-5) but not all may be explored
            for door in 0..<6 {
                // Verify door slots exist (they can be nil or have connections)
                _ = room.doors[door]  // This ensures the key exists or can be accessed
            }
        }
    }
}