@available(macOS 13.0, *)
public final class PingWorker: Worker {
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

    var maxIterations: Int = 5000
    override public func shouldContinue(iterations it: Int) -> Bool {
        // Let's count found unique rooms
        let uniqueRooms = knownState.foundUniqueRooms
        print("!!!Unique rooms found: \(uniqueRooms)/\(problem.roomsCount)")

        let (definedDoors, undefinedDoors, zeroDoors) = knownState.boundAndUnboundDoors()

        let totalDoors = problem.roomsCount * 6
        let percentageOfDefinedDoors: Int = definedDoors * 100 / totalDoors
        if undefinedDoors != 0 {
            print(
                "😢 !!!Undefined doors found: \(undefinedDoors) vs \(definedDoors) defined doors of \(totalDoors) (\(percentageOfDefinedDoors)%)"
            )
        }

        if uniqueRooms == problem.roomsCount && zeroDoors == 0 && undefinedDoors == 0 {
            print("Everything is FINE 🔥")
            knownState.printBoundRoomInfo()
            return false
        }

        let istooLong = it > maxIterations
        if istooLong {
            print("Too many iterations \(it) 🔥 :(")
            print("Continue? (y/n)")

            // Ask for input and to continue if possible
            let response = readLine(strippingNewline: true)
            if response?.lowercased() == "y" {
                print("Continuing...")
                maxIterations += 5000
                return true
            }
            print("Stopping...")
            return false
        }

        return true
    }

    private var submittedQueries: [String] = []
    // mapping from label we used on the previous step to our room IDs
    private var assignedLabels: [Int: Int] = [:]

    /// Generate random query of maxQuerySize length
    private func generateRandomQuery() -> String {
        var randomQuery = ""
        for _ in 0..<maxQuerySize {
            randomQuery += String(Int.random(in: 0..<6))
        }
        return randomQuery
    }

    // MARK: - Ping ================================

    private var isPingQuery: Bool = false

    struct PingQuery {
        let boundRoomIndex: Int
        let previousLabel: Int
        let expectedLabel: Int
        let previousLabels: [Int]
        let query: String
        let queryForProcessing: String
    }

    private var pingQuery: PingQuery?

    func pingPlans() -> [String] {
        /// Find first room with the potential is like [BoundedRoom + (Not Found Rooms)]
        let boundRooms = knownState.definedRooms.compactMap { $0 }

        let pathsWithBoundRooms = boundRooms.compactMap { boundRoom in
            knownState.path(
                from: boundRoom,
                with: { room in
                    room.index == nil && room.potential.contains(boundRoom.index!)
                }
            )
            .map { (bound: boundRoom, potential: (room: $0.1, path: $0.0)) }
        }

        let sortPotentials = pathsWithBoundRooms.sorted(by: {
            $0.1.room.potential.count < $1.1.room.potential.count
        })

        // Select one of pathsWithBoundRooms
        let sortedPotentialsWithoutKnown = sortPotentials.first(where: {
            knownState.path(to: $0.bound) != nil
        })
        guard let (bound, potential) = sortedPotentialsWithoutKnown else {
            return []
        }

        let previousLabel = bound.label
        let nextLabel = (previousLabel + 1) % 4

        guard let pathToBoundRoom = knownState.path(to: bound) else {
            // TODO: Add check here... What the hell is going on?
            return []
        }

        isPingQuery = true

        pingQuery = PingQuery(
            boundRoomIndex: bound.index!,
            previousLabel: previousLabel,
            expectedLabel: nextLabel,
            previousLabels: knownState.moveByPathAndGetLabels(path: bound.path + potential.path),
            query: pathToBoundRoom.asString() + "[\(nextLabel)]" + potential.path.asString(),
            queryForProcessing: pathToBoundRoom.asString() + "c" + potential.path.asString()
        )

        print("🔥 Ping query: \(pingQuery!)")
        print("🔥 Checking behaviour of potential \(potential.room) by \(bound)")

        // This is the mighty query 💪
        return [pingQuery!.query]
    }

    func processPingExplored(explored: ExploreResponse) {
        //        for (query, result) in zip(submittedQueries, explored.results) {
        let result = explored.results[0]
        let querySteps = self.pingQuery!.queryForProcessing

        let pingQuery = self.pingQuery!

        let pointer = RoomState(room: knownState.rootRoom!)

        print("Explored Results: \(result)")

        for i in 0..<querySteps.count {
            let fromDoorC = querySteps[querySteps.index(querySteps.startIndex, offsetBy: i)]
            guard let fromDoor = Int(String(fromDoorC)) else {
                continue
            }

            let destinationRoomLabel = result[i + 1]

            let door = pointer.room.doors[fromDoor]
            let destinationRoom = door.destinationRoom!

            // Verify if destination room label is correct
            if destinationRoomLabel != destinationRoom.label, destinationRoom.index == nil {
                print("🔥 Change Detected for room \(destinationRoom)")
                // Change Detected therefore we know that it the bounded room we just pinged
                destinationRoom.potential = [pingQuery.boundRoomIndex]

            } else if destinationRoomLabel == destinationRoom.label, i == querySteps.count - 1 {
                // We changed that bounded one, but we didn't see the expect change in the potential
                destinationRoom.potential.remove(pingQuery.boundRoomIndex)

                print(
                    "🔥 Change Was not detected for room \(destinationRoom) Therefore this should be unique one or at lease we removed one potential \(pingQuery.boundRoomIndex)"
                )
            }

            pointer.room = destinationRoom
        }
        //        }
        // TODO: We only need to optimize and mark
        knownState.addRoomAndCompactRooms(pointer.room)
        isPingQuery = false
    }

    // MARK: - Regular ================================

    func pingExplorationPlans() -> [String] {
        var plans: [String] = []

        let roomsWeInterstedIn =
            knownState.definedRooms
            .compactMap { $0 }
            .filter { pingQuery?.boundRoomIndex == $0.index }
            .filter { room in
                room.doors.contains(where: { $0.destinationRoom == nil })
            }.shuffled().prefix(take)

        for room in roomsWeInterstedIn {
            for door in room.doors.filter({ $0.destinationRoom == nil }) {
                print("🌺 explore door \(door.id) in room \(room)")

                for i in 0..<1 {
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

        if !plans.isEmpty {
            print("🎃 Using ping priority plans")
        }
        return plans
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

                for i in 0..<1 {
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
            pingPlans,
            pingExplorationPlans,
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

    private func printMermaidOnError() {
        let mermaiMap = knownState.returnMermaidMap()
        print("========================")
        print(mermaiMap)
        print("========================")
    }

    override public func generateGuess() -> MapDescription {
        let allRooms = knownState.definedRooms.compactMap { $0 }

        for room in allRooms {

            // We definetly know that all doors are connected somewher
            for door in room.doors {

                guard let destinationRoom = door.destinationRoom else {
                    printMermaidOnError()
                    fatalError(
                        "Door \(door.id) in room \(room) has no back door. How did we get there?")
                }

                guard door.destinationDoor != nil else {
                    // We alread connected this door (not sure how, but still)
                    continue
                }

                /// Connect somehow door

                // Find firs door that goes back
                guard
                    let backDoor = destinationRoom.doors.first(where: {
                        $0.destinationRoom!.index! == room.index! && $0.destinationDoor == nil
                    })
                else {
                    printMermaidOnError()
                    fatalError(
                        "Door \(door.id) in room \(room) has no back door. How did we get there?")
                }

                door.destinationDoor = backDoor
                backDoor.destinationDoor = door
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
        if isPingQuery {
            processPingExplored(explored: explored)
            return
        }

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

            for i in 0..<querySteps.count {
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
