@available(macOS 13.0, *)
public final class FindEverythingWorker: Worker {
    final class ExploratoinDoor {
        let id: String
        var destinationRoom: ExplorationRoom?
        var destinationDoor: ExploratoinDoor?
        
        init(id: String) {
            self.id = id
        }
    }
    
    final class ExplorationRoom: CustomStringConvertible {
        // List of indexeses that this room potentially could be
        var potential: Set<Int>
        
        // 100% unique room index
        var index: Int? {
            guard potential.count == 1 else { return nil }
            return potential.first!
        }
        
        // External label
        let label: Int
        let path: [Int]
        let doors: [ExploratoinDoor] = (0 ..< 6).map { ExploratoinDoor(id: String($0)) }
        
        init(label: Int, path: [Int], roomsCount: Int) {
            self.label = label
            self.path = path
            
            var potential = Set<Int>()
            for i in 0 ..< roomsCount {
                potential.insert(i)
            }
            self.potential = potential
        }
        
        var description: String {
            let doorsDesc = doors.map { door in
                if let destRoom = door.destinationRoom {
                    if let destRoomIndex = destRoom.index {
                        return "\(door.id)->\(destRoomIndex)[\(destRoom.label)]"
                    } else {
                        return "\(door.id)->?[\(destRoom.label)]"
                    }
                } else {
                    return "\(door.id)->nil"
                }
            }.joined(separator: ", ")
            return "Room(label: \(label), path: \(path), index: \(String(describing: index)), potential: \(potential), doors: [\(doorsDesc)])"
        }
    }
    
    class KnownState {
        let totalRoomsCount: Int
        
        init(totalRoomsCount: Int) {
            self.totalRoomsCount = totalRoomsCount
        }
        
        private var debug: Bool = true
        func log(_ message: @autoclosure () -> String) {
            if debug {
                print("[KnownState] \(message())")
            }
        }
        
        private var debugCompact: Bool = false
        func log3(_ message: @autoclosure () -> String) {
            if debugCompact {
                print("[Compact] \(message())")
            }
        }
        
        private var debugCleanup: Bool = false
        func log4(_ message: @autoclosure () -> String) {
            if debugCleanup {
                print("[Cleanup] \(message())")
            }
        }

        
        var definedRooms: [ExplorationRoom?] = Array(repeating: nil, count: 64)
        
        var foundUniqueRooms: Int = 0
        
        var rootRoom: ExplorationRoom?
        
        var unboundedRooms: [ExplorationRoom] = []
        
        func addRoomAndCompactRooms(_ room: ExplorationRoom) {
            addRoom(room)
//            log("Total unique rooms found: \(foundUniqueRooms)/\(unboundedRooms.count)")
            compactRooms()
            
//            log("[Compact]iue rooms found: \(foundUniqueRooms)/\(unboundedRooms.count)")
        }
        
        private func compactRooms() {
            // Task for compact is to simplify allVisitedRooms by changing those to defined once and cleanup
            var newAllVisitedRooms: [ExplorationRoom] = []
            
            for room in unboundedRooms {
                removeAllPotentialIndexes(room)
            }
            
            var processedRooms: [ExplorationRoom] = []
            
            func processChildren(room: ExplorationRoom, definedOne: ExplorationRoom) {
                guard room !== definedOne else { return }
                guard !processedRooms.contains(where: { $0 === room }) else { return }
                processedRooms.append(room)
                
                //                newAllVisitedRooms.removeAll(where: { $0 === room })
                
                for (roomDoor, definedRoomDoor) in zip(room.doors, definedOne.doors) {
                    if let roomDestinationRoom = roomDoor.destinationRoom,
                       let definedRoomDestinationRoom = definedRoomDoor.destinationRoom,
                       roomDestinationRoom === definedRoomDestinationRoom && roomDestinationRoom !== definedRoomDestinationRoom {
                        // We need to update roomDestion with information from definedRoomDestinationRoom
                        roomDoor.destinationRoom = definedRoomDoor.destinationRoom
                        processChildren(room: roomDestinationRoom, definedOne: definedRoomDestinationRoom)
                    }
                }
            }
            
            
            for room in unboundedRooms {
                
                guard let index = room.index  else {
                    newAllVisitedRooms.append(room)
                    continue
                }
                
                guard !processedRooms.contains(where: { $0 === room }) else { continue }
                
                // Merge information with the defined room, if we know everything about it
                if let definedRoom = definedRooms[index] {
                    
                    for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
                        if let roomDoorDestinationRoom = roomDoor.destinationRoom, definedRoomDoor.destinationRoom == nil
                        {
                            // Add connection to the defined room from the current room
                            definedRoomDoor.destinationRoom = roomDoorDestinationRoom
                        }
                    }
                    
                    // Process all children of this room, and try to make those as defined as possible
                    processChildren(room: room, definedOne: definedRoom)
                    
                } else {
                    
                    // This is a new unique room found
                    log("[2]Found new unique room: \(room.label) \(room.path)")
                    room.potential = Set([foundUniqueRooms])
                    foundUniqueRooms += 1
                    definedRooms[room.index!] = room
                    log("Added unique room: with \(room.index!)")
                }
                
            }
            
            // Replace all destinationRooms to defined rooms, if possible
            for definedRoom in definedRooms {
                guard let definedRoom = definedRoom else { continue }
                for door in definedRoom.doors {
                    guard let destRoom = door.destinationRoom else { continue }
                    guard !definedRooms.contains(where: { $0 === destRoom }) else { continue }
                    
                    removeAllPotentialIndexes(destRoom)
                    
                    if let idx = destRoom.index {
                        
                        // --> Door -> DestionRoom
  
                        // Replace door with defined rooms
                        log3("Replacing door destination room \(String(describing: door.destinationRoom)) with defined room \(idx)")
                        door.destinationRoom =  definedRooms[idx]!
                        
                        // TODO:Potentially, we would need to merge information form the destRoom with a defined one
                    }
                }
            }
            
            unboundedRooms = newAllVisitedRooms
        }
        
        private func removeAllPotentialIndexes(_ room: ExplorationRoom) {
            for definedRoom in definedRooms {
                guard let definedRoom = definedRoom else { continue }
                guard let definedRoomIndex = definedRoom.index else { continue }
                guard room.potential.contains(definedRoomIndex) else { continue }
                
                if isDifferen(room: room, definedRoom: definedRoom, depth: 5) {
                    room.potential.remove(definedRoomIndex)
                    continue
                }
            }
        }
        
        
        private func isDifferen(room: ExplorationRoom, definedRoom:ExplorationRoom, depth: Int) -> Bool {
            guard depth > 0 else { return false }
            guard room.label == definedRoom.label else { return true}
            
            for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
                guard let definedRoomDoorDestinationRoom = definedRoomDoor.destinationRoom else { continue }
                guard let roomDoorDestinationRoom = roomDoor.destinationRoom else { continue }

                if isDifferen(room: definedRoomDoorDestinationRoom, definedRoom: roomDoorDestinationRoom, depth: depth - 1) {
                    return true
                }
            }
            
            
            return false
            
        }
            
        
        private func addRoom(_ room: ExplorationRoom) {
            if let _ = room.index {
                return
            }
            
            unboundedRooms.append(room)
            
            removeAllPotentialIndexes(room)
            
            
            // Is it still potential?
            if room.potential.count <= totalRoomsCount - foundUniqueRooms {
                // This is a new unique room found
                log("[1]Found new unique room: \(room.label) \(room.path)")
                room.potential = Set([foundUniqueRooms])
                foundUniqueRooms += 1
                definedRooms[room.index!] = room
                log("Added unique room: with \(room.index!)")
                return
            }
        }
    }
    
    private var knownState: KnownState
    
    private var debug: Bool = true
    func log(_ message: @autoclosure () -> String) {
        if debug {
            print("[GenerateEverythingWorker] \(message())")
        }
    }
    
    public init(problem: Problem, client: ExplorationClient, debug: Bool = false) {
        self.knownState = KnownState(totalRoomsCount: problem.roomsCount)
        super.init(problem: problem, client: client)
        self.debug = debug
    }
    
    override public func shouldContinue(iterations it: Int) -> Bool {
        // Let's count found unique rooms
        let uniqueRooms = knownState.foundUniqueRooms
        print("!!!Unique rooms found: \(uniqueRooms)/\(problem.roomsCount)")
        
        var undefinedDoors  = 0
        for room in knownState.definedRooms {
            guard let room  else { continue }
            
            for door in room.doors {
                // We need to caclulate all doors that are not moving to defined rooms
                if let destRoom = door.destinationRoom, destRoom.index == nil {
                    print("❓Room \(String(describing: room.index)) has door \(door.id) to non-defined room \(destRoom.label) \(destRoom.path) with potential \(destRoom.potential)")
                    undefinedDoors += 1
                }
            }
        }
        
        if undefinedDoors != 0 {
            print("😢 !!!Undefined doors found: \(undefinedDoors)")
        }
        
        if uniqueRooms == problem.roomsCount && undefinedDoors == 0 {
            print("Everything is FINE 🔥")
            return false
        }
                
        
        return it < 500
    }
    
    //
    //    [1][2][3][4][5][0][1][14][15][16][17][12][11][10][9][8][7][6]
    //    0 ->2'->13          ---> Update
    
    private var query: [String] = []
    
    override public func generatePlans() -> [String] {
        let query = String(doorPath(N: problem.roomsCount * iterations))
        let sentQuery = String(query.suffix(problem.roomsCount * 18))
        
        self.query = [sentQuery]

        if let room = knownState.definedRooms.compactMap({ $0}).first(where:{ room in
            room.doors.contains(where: { $0.destinationRoom == nil })
        }) {
            print("🍈 Found oor \(room) with unknown doors")
            let door = room.doors.first(where: { $0.destinationRoom == nil })!
            
            print("🍈 Will explore door \(door.id) in room \(room)")
            
            for i in 0..<6 {
                let additionalQuer = room.path + [Int(door.id)! , i]
                let additionalQueryString = additionalQuer.map { String($0) }.joined() + sentQuery
//                + sentQuery
                let final = String(additionalQueryString.prefix(problem.roomsCount * 18))
                self.query.append(final)
            }
        }
        
        if self.query.isEmpty {
            self.query.append(sentQuery)
        }
        
        
        return self.query
    }
    
    override public func generateGuess() -> MapDescription {
        let allRooms = knownState.definedRooms.compactMap { $0}
        
        for room in allRooms {
            for door in room.doors {
                if let destinationRoom = door.destinationRoom {
                    
                    if door.destinationDoor == nil {
                        /// Connect somehow door
                        ///
                        
                        // Find firs door that goes back
                        let backDoor = destinationRoom.doors.first(where: { $0.destinationRoom === room && $0.destinationDoor == nil })!
                        
                        door.destinationDoor = backDoor
                        backDoor.destinationDoor = door
                    }
                }
            }
        }
        
        var connections: [Connection] = []
        
        for (roomIndex, room) in allRooms.enumerated() {
            for (doorIndex, door) in room.doors.enumerated() {
                let desinaroomIndex = allRooms.firstIndex(where: { $0 === door.destinationRoom })!
                let toDoor = door.destinationDoor!.id
                connections.connect(room: roomIndex, door: doorIndex, toRoom: desinaroomIndex, toDoor: Int(toDoor)!)
            }
        }
        
        return MapDescription(rooms: knownState.definedRooms.compactMap { $0}.map { $0.label }, startingRoom: 0, connections: connections)
    }
    
    private func createExplorationRoom(label: Int, path: [Int]) -> ExplorationRoom {
        return ExplorationRoom(label: label, path: path, roomsCount: problem.roomsCount)
    }
    
    private final class RoomState {
        var room: ExplorationRoom
        init(room: ExplorationRoom) {
            self.room = room
        }
        
    }
    
    private var debugExploration: Bool = false
    func log2(_ message: @autoclosure () -> String) {
        if debugExploration {
            print("[ProcessExplored] \(message())")
        }
    }
    
    
    override public func processExplored(explored: ExploreResponse) {
        for (query, result) in zip(query, explored.results) {
            let querySteps = query.split(separator: "").map { Int(String($0))! }
            
            var currentPath: [Int] = []
            let currentRoom: ExplorationRoom = knownState.rootRoom ?? createExplorationRoom(label: result[0], path: [])
            if knownState.rootRoom == nil {
                knownState.rootRoom = currentRoom
                knownState.addRoomAndCompactRooms(currentRoom)
            }
            
            let roomState = RoomState(room: currentRoom)
            
            for i in 0 ..< querySteps.count {
                let fromDoor = querySteps[i]
                let fromRoom = result[i]
                let toRoom = result[i + 1]
                
                currentPath.append(fromDoor)
                
                log2("Will Process \(fromDoor) ")
                log2("Current Path \(currentPath) ")
                log2("Current Room \(roomState.room) ")
                
                let door = roomState.room.doors[fromDoor]
                if let destinationRoom = door.destinationRoom {
                    roomState.room = destinationRoom
                } else {
                    let newRoom = createExplorationRoom(label: toRoom, path: currentPath)
                    door.destinationRoom = newRoom
                    
                    log2("Added new room: \(roomState.room.potential): \(newRoom.path) -\(fromDoor)> \(newRoom.label)")
                    log2("Added connection: \(roomState.room.potential) \(fromRoom) -\(fromDoor)> \(toRoom)")
                    
                    knownState.addRoomAndCompactRooms(roomState.room)
                    
                    var curr = knownState.rootRoom!
                    for step in newRoom.path {
                        if let knownDestinationRoom = roomState.room.doors[step].destinationRoom {
                            curr = knownDestinationRoom
                            log2("[1]Current room changed to \(curr)")
                        } else {
                            curr = newRoom
                            log2("[2]Current room changed to \(curr)")
                            break
                        }
                    }
                    roomState.room = curr
                    
                    log2("[3]Current room changed to \(roomState.room)")
                }
            }
        }
        
        log2("Known state: \(knownState)")
    }
}
