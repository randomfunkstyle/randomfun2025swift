
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
        
        let room7 = createRoom(label: 1)
        room6.connect(0, room7)
        knownState.addRoomAndCompactRooms(room6)
        
        XCTAssertEqual(knownState.foundUniqueRooms, 2)
        XCTAssertEqual(knownState.unboundedRooms.count, 0)
        XCTAssertTrue(knownState.definedRooms[1]?.doors[0].destinationRoom === one)

        
    }
    
    var roomsCount = 3
    
    private func createRoom(label: Int) -> R {
        let room = R(label: label, path: [], roomsCount: roomsCount)
        return room
    }
    
}



private extension R {
    
    func connect(_ doorIndex: Int, _ room: R) {
        self.doors[doorIndex].destinationRoom = room
    }
}
