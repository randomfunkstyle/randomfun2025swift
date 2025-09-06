
import XCTest
@testable import ICFPWorkerLib


typealias R = FindEverythingWorker.ExplorationRoom
typealias D = FindEverythingWorker.ExploratoinDoor

final class FindEverythingWorkerTests: XCTestCase {
    
    
    func testInitialization() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        XCTAssertEqual(knownState.totalRoomsCount, 3)
        XCTAssertEqual(knownState.foundUniqueRooms, 0)
    }
    
    
    func testOneRoomShouldWork() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [], roomsCount: 3))
        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
    }

    func testOneRoomShouldWork011() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [], roomsCount: 3))
        knownState.addRoomAndCompactRooms(.init(label: 1, path: [1], roomsCount: 3))
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertNotNil(knownState.definedRooms[1])
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
    }

    
    func testOneRoomShouldWork010() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [], roomsCount: 3))
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [0], roomsCount: 3))
        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertEqual(knownState.unboundedRooms.count, 1)
    }
    
    func testOneRoomShouldWork000() {
        roomsCount = 2
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 2)
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [], roomsCount: 2))
        knownState.addRoomAndCompactRooms(.init(label: 0, path: [0], roomsCount: 2))
        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertEqual(knownState.unboundedRooms.count, 1)
    }
    
    func testOneRoomShouldWork00asd() {
        roomsCount = 2
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: roomsCount)
        
        let room = createRoom(label: 0)
        let next = createRoom(label: 0)
        room.connect(0, next)
        knownState.addRoomAndCompactRooms(room)
        
        let nextNext = createRoom(label: 1)
        next.connect(0, nextNext)
        knownState.addRoomAndCompactRooms(next)
        
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertNotNil(knownState.definedRooms[1])
        
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
    }
    
    func testOneRoomShouldWor() {
        roomsCount = 2
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: roomsCount)

        let room0 = createRoom(label: 0)
        let room1 = createRoom(label: 0)
        room0.connect(0, room1)
        
//       (0:)0 [0] -> (1:)0
        
        knownState.addRoomAndCompactRooms(room0)
        
        let room2 = createRoom(label: 1)
        room1.connect(1, room2)
        // (0:)0 [0] -> (1:)0 -> (2:)1 <-- unique 1  [0]
        // (1:)0 -> (2:)               <-- unbounded [0, 1]
        knownState.addRoomAndCompactRooms(room1)

        // (0:)0 [0] -> (1:)0 -> (2:)1 <-- unique 1 [0]
        // (1:)0 -> (2:)               <-- uniueq 1 (by contradiction and compaction) [0]
        // (2:)1                      <-- unique 2 [1]
        knownState.addRoomAndCompactRooms(room2)

        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
    }
    
    func testOneRoomShouldWor2123() {
        roomsCount = 2
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: roomsCount)

        let room0 = createRoom(label: 0)
        let room1 = createRoom(label: 0)
        room0.connect(0, room1)
        
        // (0:)0 -0> (1:)0   <-- unique 1  [0]
        
        knownState.addRoomAndCompactRooms(room0)
        // (0:)0 -0> (1:)0   <-- unique 1  [0]
        
        let room2 = createRoom(label: 0)
        room1.connect(1, room2)
        
        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        knownState.addRoomAndCompactRooms(room1)

        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        // (2:)0                     <-- unbounded [0, 1]
        
        knownState.addRoomAndCompactRooms(room2)
        
        let room3 = createRoom(label: 0)
        room2.connect(2, room3)
        
        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        // (2:)0 -2> (3:)0           <-- unbounded [0, 1]
        // (3:)0                     <-- unbounded [0, 1]
        knownState.addRoomAndCompactRooms(room3)

        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertEqual(knownState.unboundedRooms.count, 3)
        
        let room4 = createRoom(label: 1)
        room3.connect(3, room4)

        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, x] // this should be compacted
        // (2:)0 -2> (3:)0           <-- unbounded [0, x]  // this should be compacted
        // (3:)0 -3> (4:)1          <-- unique2 [1]
        knownState.addRoomAndCompactRooms(room4)
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertNotNil(knownState.definedRooms[1])
        
        let zero = knownState.definedRooms[0]!
        let one = knownState.definedRooms[1]!
        XCTAssertTrue(knownState.definedRooms[0]?.doors[0].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[1].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[2].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[3].destinationRoom === one)
        
    }
    
    func testOneRoomShouldWor21232() {
        roomsCount = 2
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: roomsCount)

        let room0 = createRoom(label: 0)
        let room1 = createRoom(label: 0)
        room0.connect(0, room1)
        
        // (0:)0 -0> (1:)0   <-- unique 1  [0]
        
        knownState.addRoomAndCompactRooms(room0)
        // (0:)0 -0> (1:)0   <-- unique 1  [0]
        
        let room2 = createRoom(label: 0)
        room1.connect(1, room2)
        
        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        knownState.addRoomAndCompactRooms(room1)

        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        // (2:)0                     <-- unbounded [0, 1]
        
        knownState.addRoomAndCompactRooms(room2)
        
        let room3 = createRoom(label: 0)
        room2.connect(2, room3)
        
        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, 1]
        // (2:)0 -2> (3:)0           <-- unbounded [0, 1]
        // (3:)0                     <-- unbounded [0, 1]
        knownState.addRoomAndCompactRooms(room3)

        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertEqual(knownState.unboundedRooms.count, 3)
        
        let room4 = createRoom(label: 1)
        room3.connect(3, room4)

        // (0:)0 -0> (1:)0 -1> (2:)0 <-- unique 1  [0]
        // (1:)0 -1> (2:)0           <-- unbounded [0, x] // this should be compacted
        // (2:)0 -2> (3:)0           <-- unbounded [0, x]  // this should be compacted
        // (3:)0 -3> (4:)1          <-- unique2 [1]
        knownState.addRoomAndCompactRooms(room4)
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        XCTAssertNotNil(knownState.definedRooms[0])
        XCTAssertNotNil(knownState.definedRooms[1])
        
        let zero = knownState.definedRooms[0]!
        let one = knownState.definedRooms[1]!
        XCTAssertTrue(knownState.definedRooms[0]?.doors[0].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[1].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[2].destinationRoom === zero)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[3].destinationRoom === one)
        
        
        let room5 = createRoom(label: 0)
        room0.connect(4, room5)

        knownState.addRoomAndCompactRooms(room0)
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[4].destinationRoom === zero)
        
        let room6 = createRoom(label: 1)
        room0.connect(5, room6)
        knownState.addRoomAndCompactRooms(room0)
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        XCTAssertTrue(knownState.definedRooms[0]?.doors[5].destinationRoom === one)
    }
    
    
    func testSelfRefece() {
        roomsCount = 1
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: roomsCount)

        let room0 = createRoom(label: 0)
        let room1 = createRoom(label: 0)
        room0.connect(0, room1)
        
        // (0:)0 -0> (1:)0   <-- unique 1  [0]
        
        knownState.addRoomAndCompactRooms(room0)
        knownState.addRoomAndCompactRooms(room1)

        XCTAssertEqual(knownState.foundUniqueRooms, 1)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        
        let zero = knownState.definedRooms[0]!
        XCTAssertTrue(zero.doors[0].destinationRoom === zero)        
    }
    
    var roomsCount = 3
    
    private func createRoom(label: Int) -> R {
        let room = R(label: label, path: [], roomsCount: roomsCount)
        return room
    }
    
    // MARK: - isDifferent Tests
    
    func testIsDifferenSameRooms() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 5)
        
        // Same rooms with same labels should not be different
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 1))
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 5))
    }
    
    func testIsDifferenDifferentLabels() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 7)
        
        // Different labels should be different
        XCTAssertTrue(knownState.isDifferent(room: room1, definedRoom: room2, depth: 1))
        XCTAssertTrue(knownState.isDifferent(room: room1, definedRoom: room2, depth: 5))
    }
    
    func testIsDifferenDepthZero() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 7)
        
        // With depth 0, should always return false (no difference)
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 0))
    }
    
    func testIsDifferenWithConnectedRooms() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        
        // Create two rooms with same label
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 5)
        
        // Create connected rooms
        let connectedRoom1 = createRoom(label: 3)
        let connectedRoom2 = createRoom(label: 3)
        
        // Connect both rooms to their respective connected rooms via door 0
        room1.connect(0, connectedRoom1)
        room2.connect(0, connectedRoom2)
        
        // Should not be different since connected rooms have same labels
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 2))
    }
    
    func testIsDifferenWithDifferentConnectedRooms() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        
        // Create two rooms with same label
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 5)
        
        // Create connected rooms with different labels
        let connectedRoom1 = createRoom(label: 3)
        let connectedRoom2 = createRoom(label: 7)
        
        // Connect both rooms to their respective connected rooms via door 0
        room1.connect(0, connectedRoom1)
        room2.connect(0, connectedRoom2)
        
        // Should be different since connected rooms have different labels
        XCTAssertTrue(knownState.isDifferent(room: room1, definedRoom: room2, depth: 2))
    }
    
    func testIsDifferenWithNilDestinations() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        
        // Create two rooms with same label
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 5)
        
        // Create connected rooms
        let connectedRoom1 = createRoom(label: 3)
        
        // Connect only room1 to connected room, leave room2's door nil
        room1.connect(0, connectedRoom1)
        // room2.doors[0].destinationRoom remains nil
        
        // Should not be different since we skip nil destinations
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 2))
    }
        
    func testIsDifferenMultipleDoors() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 3)
        
        // Create two rooms with same label
        let room1 = createRoom(label: 5)
        let room2 = createRoom(label: 5)
        
        // Create connected rooms for different doors
        let door0Room1 = createRoom(label: 3)
        let door0Room2 = createRoom(label: 3)
        let door1Room1 = createRoom(label: 7)
        let door1Room2 = createRoom(label: 9) // Different label
        
        // Connect via different doors
        room1.connect(0, door0Room1)
        room2.connect(0, door0Room2)
        room1.connect(1, door1Room1)
        room2.connect(1, door1Room2)
        
        // Should be different due to door 1 connection
        XCTAssertTrue(knownState.isDifferent(room: room1, definedRoom: room2, depth: 2))
    }
    
    func testIsDifferenComplexScenario() {
        let knownState = FindEverythingWorker.KnownState(totalRoomsCount: 5)
        
        // Create two complex room structures
        let room1 = createRoom(label: 1)
        let room2 = createRoom(label: 1)
        
        // Create a network of connected rooms
        let room1A = createRoom(label: 2)
        let room1B = createRoom(label: 3)
        let room2A = createRoom(label: 2)
        let room2B = createRoom(label: 3)
        
        let room1AA = createRoom(label: 4)
        let room1BB = createRoom(label: 5)
        let room2AA = createRoom(label: 4)
        let room2BB = createRoom(label: 6) // Different label
        
        // Build identical structure for room1
        room1.connect(0, room1A)
        room1.connect(1, room1B)
        room1A.connect(0, room1AA)
        room1B.connect(0, room1BB)
        
        // Build similar structure for room2, but with one difference
        room2.connect(0, room2A)
        room2.connect(1, room2B)
        room2A.connect(0, room2AA)
        room2B.connect(0, room2BB)
        
        // Should detect difference at depth 3
        XCTAssertTrue(knownState.isDifferent(room: room1, definedRoom: room2, depth: 3))
        
        // Should not detect difference at depth 2
        XCTAssertFalse(knownState.isDifferent(room: room1, definedRoom: room2, depth: 2))
    }
    
}



private extension R {
    
    func connect(_ doorIndex: Int, _ room: R) {
        self.doors[doorIndex].destinationRoom = room
    }
}
