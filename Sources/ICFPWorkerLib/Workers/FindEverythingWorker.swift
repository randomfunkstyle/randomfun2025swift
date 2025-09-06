@available(macOS 13.0, *)
public final class FindEverythingWorker: Worker {
    private final class ExploratoinDoor {
        let id: String
        var destinationRoom: ExplorationRoom?
        var destinationDoor: ExploratoinDoor?

        init(id: String) {
            self.id = id
        }
    }

    private final class ExplorationRoom {
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
    }

    private class KnownState {
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

        var definedRooms: [ExplorationRoom?] = Array(repeating: nil, count: 64)

        var foundUniqueRooms: Int = 0

        var rootRoom: ExplorationRoom?

        var allVisitedRooms: [ExplorationRoom] = []

        func addRoomAndCompactRooms(_ room: ExplorationRoom) {
            addRoom(room)
            log("Total unique rooms found: \(foundUniqueRooms)/\(allVisitedRooms.count)")
            compactRooms()
        
            log("[Compact]iue rooms found: \(foundUniqueRooms)/\(allVisitedRooms.count)")
        }

        private func compactRooms() {
            // Task for compact is to simplify allVisitedRooms by changinf those to defined once and cleanup
            var newAllVisitedRooms: [ExplorationRoom] = []

            for room in allVisitedRooms {
                removeAllPotentialIndexes(room)
            }

            for room in allVisitedRooms {

                guard let index = room.index  else {
                    newAllVisitedRooms.append(room)
                    continue
                }
                

                // Merge information with the defined room, if we know everything about it
                if let definedRoom = definedRooms[index] {
                    for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
                        if let roomDoorDestinationRoom = roomDoor.destinationRoom, definedRoomDoor.destinationRoom == nil
                        {
                            // Add connection to the defined room from the current room
                            definedRoomDoor.destinationRoom = roomDoorDestinationRoom
                        }
                    }
                } else {
                    
                    // This is a new unique room found
                    log("Found new unique room: \(room.label) \(room.path)")
                    room.potential = Set([foundUniqueRooms])
                    foundUniqueRooms += 1
                    definedRooms[room.index!] = room
                    log("Added unique room: with \(room.index!)")
                }
                
            }

            // Replace all destinationRooms to defined rooms, if possible
            for definedRoom in definedRooms {
                if let definedRoom = definedRoom {
                    for door in definedRoom.doors {
                        guard let destRoom = door.destinationRoom else { continue }
                        guard !definedRooms.contains(where: { $0 === destRoom }) else { continue }

                        removeAllPotentialIndexes(destRoom)

                        if let idx = destRoom.index {
                            // Replace door with defined rooms
                            door.destinationRoom =  definedRooms[idx]!

                            // TODO:Potentially, we would need to merge information form the destRoom with a defined one
                        }
                    }
                }
            }
            
            allVisitedRooms = newAllVisitedRooms
        }

        private func removeAllPotentialIndexes(_ room: ExplorationRoom) {
            for definedRoom in definedRooms {
                guard let definedRoom = definedRoom else { continue }
                guard let definedRoomIndex = definedRoom.index else { continue }
                guard room.potential.contains(definedRoomIndex) else { continue }

                if room.label != definedRoom.label {
                    room.potential.remove(definedRoomIndex)
                    continue
                }

                for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
                    guard let definedRoomDoorDestinationRoom = definedRoomDoor.destinationRoom else { continue }
                    guard let roomDoorDestinationRoom = roomDoor.destinationRoom else { continue }
                    if definedRoomDoorDestinationRoom.label != roomDoorDestinationRoom.label {
                        room.potential.remove(definedRoomIndex)
                        continue
                    }
                }
            }
        }

        private func addRoom(_ room: ExplorationRoom) {
//            if allVisitedRooms.isEmpty {
//                allVisitedRooms.append(room)
//                room.potential = Set([foundUniqueRooms])
//                foundUniqueRooms += 1
//                definedRooms[room.index!] = room
//
//                log("Added unique room: \(room.index!)")
//                rootRoom = room
//                return
//            }

            // We aleread know averything about this
            // Post process other visited rooms
            if let _ = room.index {
                return
            }

            allVisitedRooms.append(room)

            removeAllPotentialIndexes(room)


            // Is it still potential?
            if room.potential.count <= totalRoomsCount - foundUniqueRooms {
                // This is a new unique room found
                log("Found new unique room: \(room.label) \(room.path)")
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
        knownState.foundUniqueRooms < problem.roomsCount && it < 2
    }

    private var query: [String] = []

    override public func generatePlans() -> [String] {
        query = [String(doorPath(N: problem.roomsCount).dropFirst(iterations))]
        return query
    }

    override public func generateGuess() -> MapDescription {
        return MapDescription(rooms: [], startingRoom: 0, connections: [])
    }
    
    private func createExplorationRoom(label: Int, path: [Int]) -> ExplorationRoom {
        return ExplorationRoom(label: label, path: path, roomsCount: problem.roomsCount)
    }

    override public func processExplored(explored: ExploreResponse) {
        for (query, result) in zip(query, explored.results) {
            let querySteps = query.split(separator: "").map { Int(String($0))! }

            var currentPath: [Int] = []
            var currentRoom: ExplorationRoom = knownState.rootRoom ?? createExplorationRoom(label: result[0], path: [])
            if knownState.rootRoom == nil {
                knownState.rootRoom = currentRoom
                knownState.addRoomAndCompactRooms(currentRoom)
            }

            for i in 0 ..< querySteps.count {
                let fromDoor = querySteps[i]
                let fromRoom = result[i]
                let toRoom = result[i + 1]

                currentPath.append(fromDoor)

                let door = currentRoom.doors[fromDoor]
                if let destinationRoom = door.destinationRoom {
                    currentRoom = destinationRoom
                } else {
                    let newRoom = createExplorationRoom(label: toRoom, path: currentPath)
                    door.destinationRoom = newRoom
                    
                    print("Added new room: \(newRoom.path) -> \(newRoom.label)")
                    print("Added connection: \(fromRoom)[\(fromDoor)]->\(toRoom)")
                    
                    knownState.addRoomAndCompactRooms(currentRoom)

                    currentRoom = newRoom
                }
            }
        }

        log("Known state: \(knownState)")
    }
}
