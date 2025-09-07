@available(macOS 13.0, *)
public final class FindEverythingWorker: Worker {
    let depth: Int
    let take: Int

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
        var path: [Int]
        var doors: [ExploratoinDoor] = (0..<6).map { ExploratoinDoor(id: String($0)) }

        init(label: Int, path: [Int], roomsCount: Int) {
            self.label = label
            self.path = path

            var potential = Set<Int>()
            for i in 0..<roomsCount {
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
            return
                "Room(label: \(label), path: \(path), index: \(String(describing: index)), potential: \(potential), doors: [\(doorsDesc)])"
        }
    }

    class KnownState {
        let totalRoomsCount: Int
        let depth: Int
        var definedRooms: [ExplorationRoom?]

        init(totalRoomsCount: Int, depth: Int) {
            self.totalRoomsCount = totalRoomsCount
            self.depth = depth
            self.definedRooms = Array(repeating: nil, count: totalRoomsCount)
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

        func boundAndUnboundDoors() -> (definedDoors: Int, undefined: Int) {
            var undefinedDoors = 0
            var definedDoors = 0
            for room in definedRooms {
                guard let room else { continue }

                for door in room.doors {
                    // We need to caclulate all doors that are not moving to defined rooms
                    if let destRoom = door.destinationRoom {
                        if destRoom.index == nil {
                            undefinedDoors += 1
                        } else {
                            definedDoors += 1
                        }
                    }
                }
            }
            return (definedDoors, undefinedDoors)
        }

        func path(to room: ExplorationRoom) -> [Int]? {
            var queue = [(room: self.rootRoom!, path: [Int]())]
            var visited = [ExplorationRoom]()

            while !queue.isEmpty {
                let (current, path) = queue.removeFirst()
                if current === room {
                    return path
                }
                if visited.contains(where: { $0 === current }) {
                    continue
                }
                visited.append(current)

                for door in current.doors {
                    if let nextRoom = door.destinationRoom {
                        queue.append((nextRoom, path + [Int(door.id)!]))
                    }
                }
            }
            return nil
        }

        func updatePaths() {
            guard let startingPoint = rootRoom else { return }

            var queue = [(room: startingPoint, path: [Int]())]
            var visited = [ExplorationRoom]()
            while !queue.isEmpty {
                let (current, path) = queue.removeFirst()
                current.path = path
                visited.append(current)
                for door in current.doors {
                    if let nextRoom = door.destinationRoom {
                        if visited.contains(where: { $0 === nextRoom }) {
                            continue
                        }
                        queue.append((nextRoom, path + [Int(door.id)!]))
                    }
                }
            }
        }

        func findTopRooms(n: Int) -> [ExplorationRoom] {
            guard let startingPoint = rootRoom else { return [] }
            var queue = [(room: startingPoint, path: [Int]())]
            var visited = [ExplorationRoom]()
            var topRooms = [ExplorationRoom]()
            while !queue.isEmpty {
                let (current, path) = queue.removeFirst()
                visited.append(current)

                if current.index == nil
                    && current.doors.contains(where: { $0.destinationRoom == nil })
                {
                    topRooms.append(current)

                    if topRooms.count >= n * 2 {
                        topRooms.sort(by: {
                            $0.potential.count < $1.potential.count
                                || ($0.potential.count == $1.potential.count
                                    && $0.path.count < $1.path.count)
                        })
                        topRooms = Array(topRooms.prefix(n))
                    }
                }
                for door in current.doors {
                    if let nextRoom = door.destinationRoom {
                        if visited.contains(where: { $0 === nextRoom }) {
                            continue
                        }
                        queue.append((nextRoom, path + [Int(door.id)!]))
                    }
                }
            }
            topRooms = Array(topRooms.prefix(n))
            return topRooms
        }

        var foundUniqueRooms: Int = 0

        var rootRoom: ExplorationRoom?

        var unboundedRooms: [ExplorationRoom] = []

        func addRoomAndCompactRooms(_ room: ExplorationRoom) {
            addRoom(room)
            //            log("Total unique rooms found: \(foundUniqueRooms)/\(unboundedRooms.count)")

            compactRooms()
        }

        private func compactRooms() {
            // Task for compact is to simplify allVisitedRooms by changing those to defined once and cleanup
            var newUnboundedRooms: [ExplorationRoom] = []

            var processedRooms: [ExplorationRoom] = []

            func mergeTwoRooms(room1: ExplorationRoom, room2: ExplorationRoom) -> ExplorationRoom {
                let mergedRoom = ExplorationRoom(
                    label: room1.label, path: room1.path, roomsCount: totalRoomsCount)
                mergedRoom.potential = room1.potential.intersection(room2.potential)
                processedRooms.append(mergedRoom)
                processChildren(unboundRoom: room1, boundRoom: room2)
                return mergedRoom
            }

            func processChildren(unboundRoom: ExplorationRoom, boundRoom: ExplorationRoom) {
                guard unboundRoom !== boundRoom else { return }
                guard !processedRooms.contains(where: { $0 === unboundRoom }) else { return }
                processedRooms.append(unboundRoom)
                for (unboundRoomDoor, boundRoomDoor) in zip(unboundRoom.doors, boundRoom.doors) {
                    // Simplest case, we don't have info about door but roomDoor has it
                    if boundRoomDoor.destinationRoom == nil,
                        let roomDestination = unboundRoomDoor.destinationRoom
                    {
                        boundRoomDoor.destinationRoom = roomDestination
                    } else if unboundRoomDoor.destinationRoom == nil,
                        let definedRoomDestination = boundRoomDoor.destinationRoom
                    {
                        unboundRoomDoor.destinationRoom = definedRoomDestination
                    } else if let boundDestinationRoom = boundRoomDoor.destinationRoom,
                        let unboundDestinationRoom = unboundRoomDoor.destinationRoom,
                        boundDestinationRoom !== unboundDestinationRoom
                    {

                        // Merge Information from the doorZ

                        let mergedRoom = mergeTwoRooms(
                            room1: boundDestinationRoom, room2: unboundDestinationRoom)
                        boundRoomDoor.destinationRoom = mergedRoom
                        unboundRoomDoor.destinationRoom = mergedRoom

                    }
                }
            }

            for room in unboundedRooms {

                guard !processedRooms.contains(where: { $0 === room }) else { continue }
                removeAllInvalidPotentialIndexes(room)

                // As if nothing happened, leave as it is, we still not sure what this is room about
                guard let index = room.index else {
                    newUnboundedRooms.append(room)
                    continue
                }

                // Room is unbound, but have and index so ti basically the same as one fo  bounded/defined rooms

                // Merge information with the defined room, if we know everything about it
                if let definedRoom = definedRooms[index] {

                    processChildren(unboundRoom: room, boundRoom: definedRoom)

                } else {
                    // This is a new unique room found (The last room)
                    log("[2]Found LAST? unique room: \(room.label) \(room.path)")
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

                    removeAllInvalidPotentialIndexes(destRoom)

                    if let idx = destRoom.index {

                        // Replace door with defined rooms
                        log3(
                            "Replacing door destination room \(String(describing: door.destinationRoom)) with defined room \(idx)"
                        )

                        let definedRoom = definedRooms[idx]!

                        // 0 (nil)(nil)(1)(2)(3)(4)
                        // 0' (0)(5)()()()()
                        //  basically here we need to merge all possible information from the destRoom to the definedRoom
                        //  so if destRoom has door to some other room, we need to copy that
                        if isMagicNeeded {
                            for i in 0..<5 {
                                if definedRoom.doors[i].destinationRoom == nil,
                                    door.destinationRoom?.doors[i].destinationRoom != nil,
                                    let someDoor = door.destinationRoom?.doors[i]
                                {
                                    definedRoom.doors[i] = someDoor
                                }
                            }

                            door.destinationRoom = definedRoom
                        }

                        door.destinationRoom = definedRoom
                        // TODO:Potentially, we would need to merge information form the destRoom with a defined one <---

                    }
                }
            }

            unboundedRooms = newUnboundedRooms
        }

        var isMagicNeeded: Bool = false

        func printBoundRoomInfo() {
            for room in definedRooms {
                guard let room = room else { continue }

                var connectionsCount = 0
                for r in (definedRooms.compactMap { $0 }) {
                    for door in r.doors {
                        if door.destinationRoom?.index == room.index {
                            connectionsCount += 1
                        }
                    }
                }

                print("🍏 Bound [\(room.index!)] count: \(connectionsCount) / 6")
            }
        }

        private func removeAllInvalidPotentialIndexes(_ room: ExplorationRoom) {
            for definedRoom in definedRooms {
                guard let definedRoom = definedRoom else { continue }
                guard let definedRoomIndex = definedRoom.index else { continue }
                guard room.potential.contains(definedRoomIndex) else { continue }

                if isDifferent(room: room, definedRoom: definedRoom, depth: depth) {
                    room.potential.remove(definedRoomIndex)
                    continue
                }
            }
        }

        func isDifferent(room: ExplorationRoom, definedRoom: ExplorationRoom, depth: Int) -> Bool {
            guard depth > 0 else { return false }
            guard room.label == definedRoom.label else { return true }

            for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
                guard let definedRoomDoorDestinationRoom = definedRoomDoor.destinationRoom else {
                    continue
                }
                guard let roomDoorDestinationRoom = roomDoor.destinationRoom else { continue }

                if isDifferent(
                    room: roomDoorDestinationRoom, definedRoom: definedRoomDoorDestinationRoom,
                    depth: depth - 1)
                {
                    return true
                }
            }

            return false

        }

        private func addRoom(_ room: ExplorationRoom) {

            if room.index != nil {

                // Room kind'a bounded, but check if there's defined room with the same index
                guard definedRooms[room.index!] == nil else { return }

                // This is a new unique room found
                log("[3]Found new unique room: \(room.label) \(room.path)")
                room.potential = Set([foundUniqueRooms])  // 0
                foundUniqueRooms += 1
                definedRooms[room.index!] = room
                log("Added unique room: with \(room.index!)")
                unboundedRooms.removeAll(where: { $0 === room })

                return
            }

            unboundedRooms.append(room)

            removeAllInvalidPotentialIndexes(room)

            // Is it still potential?
            // For first room potential count == totalRoomsCount
            // [0,1,2,3,4,5]            6                      0
            // 6  <=          6
            if room.potential.count <= totalRoomsCount - foundUniqueRooms {
                // This is a new unique room found
                log("[1]Found new unique room: \(room.label) \(room.path)")
                room.potential = Set([foundUniqueRooms])  // 0
                foundUniqueRooms += 1
                definedRooms[room.index!] = room
                log("Added unique room: with \(room.index!)")
                unboundedRooms.removeAll(where: { $0 === room })
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

    public init(
        problem: Problem, client: ExplorationClient, depth: Int, take: Int, debug: Bool = true
    ) {
        self.knownState = KnownState(totalRoomsCount: problem.roomsCount, depth: depth)
        self.debug = debug
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

    func generateRandomQuery() -> String {
        var randomQuery = ""
        for _ in 0..<(problem.roomsCount * 6) {
            randomQuery += String(Int.random(in: 0..<6))
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

                for i in 0..<1 {
                    if let path = knownState.path(to: room) {
                        let additionalQuer = path + [Int(door.id)!, i]
                        let additionalQueryString =
                            additionalQuer.map { String($0) }.joined()
                            + generateRandomQuery()
                        let final = String(additionalQueryString.prefix(problem.roomsCount * 6))
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
                    let final = String(additionalQueryString.prefix(problem.roomsCount * 6))
                    plans.append(final)
                }
            }
        }

        return plans
    }

    func randomPlans() -> [String] {
        return [generateRandomQuery()]
    }

    override public func generatePlans() -> [String] {
        knownState.updatePaths()

        let lastSubmitted = self.submittedQueries
        self.submittedQueries = []

        let generators: [() -> [String]] = [
            regularPlans,
            fancyPlans,
            randomPlans,
        ]

        for generator in generators {

            let plans = generator()

            if !plans.isEmpty {
                self.submittedQueries = plans
                break
            }
        }

        if lastSubmitted == self.submittedQueries {
            print("This is the end of the world, no new queries to submit")
        }

        return self.submittedQueries
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
                    room: roomIndex, door: doorIndex, toRoom: desinaroomIndex, toDoor: Int(toDoor)!)
            }
        }

        return MapDescription(
            rooms: knownState.definedRooms.compactMap { $0 }.map { $0.label }, startingRoom: 0,
            connections: connections)
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
        for (query, result) in zip(submittedQueries, explored.results) {

            // q:0
            // R:0 -> 1

            // 0 -0> 1
            let querySteps = query.split(separator: "").map { Int(String($0))! }

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
                let fromDoor = querySteps[i]
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
