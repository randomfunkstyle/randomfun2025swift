
@available(macOS 13.0, *)
public final class FindEverythingWorker: Worker {
    let depth: Int
    let take: Int

    private var knownState: KnownState

    public init(
        problem: Problem, client: ExplorationClient, depth: Int, take: Int, debug: Bool = true
    ) {
        knownState = KnownState(totalRoomsCount: problem.roomsCount, depth: depth)
        debugFindEverythingWorker = debug
        self.depth = depth
        self.take = take
        super.init(problem: problem, client: client)
    }

    override public func shouldContinue(iterations it: Int) -> Bool {
        // Let's count found unique rooms
        let uniqueRooms = knownState.foundUniqueRooms
        print("!!!Unique rooms found: \(uniqueRooms)/\(problem.roomsCount)")

        let (definedDoors, undefinedDoors) = knownState.boundAndUnboundDoors()

        if undefinedDoors != 0 {
            print("😢 !!!Undefined doors found: \(undefinedDoors) vs \(definedDoors) defined doors")
        }

        if uniqueRooms == problem.roomsCount && undefinedDoors == 0 {
            print("Everything is FINE 🔥")
            knownState.printBoundRoomInfo()
            return false
        }

        return it < 500
    }

    private var submittedQueries: [String] = []
    // mapping from label we used on the previous step to our room IDs
    private var assignedLabels: [Int: Int] = [:]

    /// Generate random query of maxQuerySize length
    private func generateRandomQuery() -> String {
        var randomQuery = ""
        for _ in 0 ..< maxQuerySize {
            randomQuery += String(Int.random(in: 0 ..< 6))
        }
        return randomQuery
    }

    func regularPlans() -> [String] {
        var plans: [String] = []

        for room in knownState.definedRooms.compactMap({ $0 }).sorted(by: {
            $0.path.count < $1.path.count
        }).filter({ room in
            room.doors.contains(where: { $0.destinationRoom == nil })
        }).shuffled().prefix(take) {
            //            print("🍈 Found oor \(room) with unknown doors")
            for door in room.doors.filter({ $0.destinationRoom == nil }) {
                print("🍈 Will explore door \(door.id) in room \(room)")

                for i in 0 ..< 1 {
                    if let path = knownState.path(to: room) {
                        let additionalQuer = path + [Int(door.id)!, i]
                        let additionalQueryString =
                            additionalQuer.map { String($0) }.joined()
                                + generateRandomQuery()
                        let final = String(additionalQueryString.prefix(maxQuerySize))
                        plans.append(final)
                    }
                }
            }
        }
        return plans
    }

    public func fancyPlans() -> [String] {
        var plans: [String] = []
        let allInterestingRooms = knownState.findTopRooms(n: 5)

        for room in allInterestingRooms {
            if let door = room.doors.filter({ $0.destinationRoom == nil }).randomElement() {
                print("🍈 Will explore door \(door.id) in room \(room)")

                if let path = knownState.path(to: room) {
                    let additionalQuer = path + [Int(door.id)!]
                    let additionalQueryString =
                        additionalQuer.map { String($0) }.joined()
                            + generateRandomQuery()
                    let final = String(additionalQueryString.prefix(maxQuerySize))
                    plans.append(final)
                }
            }
        }

        return plans
    }

    func randomPlans() -> [String] {
        return [generateRandomQuery()]
    }

    func complexPlans() -> [String] {
        if !problem.complicated {
            return []
        }

        var plans: [String] = []

        return plans
    }

    override public func generatePlans() -> [String] {
        knownState.updatePaths()

        let lastSubmitted = submittedQueries
        submittedQueries = []

        let generators: [() -> [String]] = [
            regularPlans,
            fancyPlans,
            randomPlans,
        ]

        for generator in generators {
            let plans = generator()

            if !plans.isEmpty {
                submittedQueries = plans
                break
            }
        }

        if lastSubmitted == submittedQueries {
            print("This is the end of the world, no new queries to submit")
        }

        return submittedQueries
    }

    override public func generateGuess() -> MapDescription {
        let allRooms = knownState.definedRooms.compactMap { $0 }

        for room in allRooms {
            for door in room.doors {
                if let destinationRoom = door.destinationRoom {
                    if door.destinationDoor == nil {
                        /// Connect somehow door
                        ///

                        // Find firs door that goes back
                        let backDoor = destinationRoom.doors.first(where: {
                            $0.destinationRoom === room && $0.destinationDoor == nil
                        })!

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
                connections.connect(
                    room: roomIndex, door: doorIndex, toRoom: desinaroomIndex, toDoor: Int(toDoor)!
                )
            }
        }

        return MapDescription(
            rooms: knownState.definedRooms.compactMap { $0 }.map { $0.label }, startingRoom: 0,
            connections: connections
        )
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

    // return pairs of (door, Label?)
    func parseQuery(_ query: String) -> [(Int, Int?)] {
        var result: [(Int, Int?)] = []

        var lastDoor: Int? = nil
        var i: String.Index = query.startIndex
        while i < query.endIndex {
            let char = query[i]
            if let door = Int(String(char)) {
                if lastDoor != nil {
                    // previous door didn't have a label
                    result.append((lastDoor!, nil))
                }
                lastDoor = door
            } else {
                // parse the [label] bit
                // skip [
                i = query.index(after: i)
                // get label
                let label = Int(String(query[i]))
                result.append((lastDoor!, label))
                lastDoor = nil
                // skip ]
                i = query.index(after: i)
            }
            i = query.index(after: i)
        }

        if let lastDoor = lastDoor {
            // previous door didn't have a label
            result.append((lastDoor, nil))
        }

        return result
    }

    override public func processExplored(explored: ExploreResponse) {
        for (query, result) in zip(submittedQueries, explored.results) {
            let querySteps = parseQuery(query)

            var currentPath: [Int] = []

            // result[0]
            // Always starting from the initial room
            let currentRoom: ExplorationRoom =
                knownState.rootRoom ?? createExplorationRoom(label: result[0], path: [])
            if knownState.rootRoom == nil {
                knownState.rootRoom = currentRoom
                knownState.addRoomAndCompactRooms(currentRoom)
            }

            let pointer = RoomState(room: currentRoom)

            for i in 0 ..< querySteps.count {
                let (fromDoor, label) = querySteps[i]
                let fromRoom = result[i]
                let toRoom = result[i + 1]

                // [0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0, 4, 3]
                // Room. () <-- Path
                currentPath.append(fromDoor)

                log2("Will Process \(fromDoor) ")
                log2("Current Path \(currentPath) ")
                log2("Current Room \(pointer.room) ")

                let door = pointer.room.doors[fromDoor]
                if let destinationRoom = door.destinationRoom {
                    if let idx = destinationRoom.index,
                       knownState.definedRooms[idx] !== destinationRoom
                    {
                        door.destinationRoom = knownState.definedRooms[idx]
                        pointer.room = knownState.definedRooms[idx]!
                    } else {
                        pointer.room = destinationRoom
                    }
                } else {
                    let newRoom = createExplorationRoom(label: toRoom, path: currentPath)
                    door.destinationRoom = newRoom

                    log2(
                        "Added new room: \(pointer.room.potential): \(newRoom.path) -\(fromDoor)> \(newRoom.label)"
                    )
                    log2(
                        "Added connection: \(pointer.room.potential) \(fromRoom) -\(fromDoor)> \(toRoom)"
                    )

                    // MAG : <--
                    knownState.addRoomAndCompactRooms(pointer.room)

                    //     0    5     0
                    //  0 -0> 1 -5> [*0 -0> 1] ->  unbounded([*])
                    //  0 -1> 2
                    var curr = knownState.rootRoom!
                    for step in currentPath {
                        if let knownDestinationRoom = curr.doors[step].destinationRoom {
                            curr = knownDestinationRoom
                            log2("[1]Current room changed to \(curr)")
                        } else {
                            curr = newRoom
                            log2("[2]Current room changed to \(curr)")
                            break
                        }
                    }
                    pointer.room = curr

                    log2("[3]Current room changed to \(pointer.room)")
                }
            }
        }

        log(
            "[Compact]  rooms found: \(knownState.foundUniqueRooms)/\(knownState.unboundedRooms.count)"
        )

        log2("Known state: \(knownState)")
    }
}

// MARK: - Fileprivate Log Functions

private var debugFindEverythingWorker: Bool = true
private var debugProcessExplored: Bool = false

private var debugCleanup: Bool = false

private func log(_ message: @autoclosure () -> String) {
    if debugFindEverythingWorker {
        print("[FindEverythingWorker] \(message())")
    }
}

private func log2(_ message: @autoclosure () -> String) {
    if debugProcessExplored {
        print("[ProcessExplored] \(message())")
    }
}


private func log4(_ message: @autoclosure () -> String) {
    if debugCleanup {
        print("[Cleanup] \(message())")
    }
}
