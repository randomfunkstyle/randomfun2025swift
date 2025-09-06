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
            for i in 0 ..< roomsCount {
                potential.insert(i)
            }
        }
    }

    private class KnownState {
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

        func addRoom(_ room: ExplorationRoom) {
            if allVisitedRooms.isEmpty {
                allVisitedRooms.append(room)
                rootRoom = room
                room.potential = Set([foundUniqueRooms])
                foundUniqueRooms += 1
                definedRooms[room.index!] = room

                log("Added unique room: \(room.index!)")
                return
            }

            // if this room 1000% unique, we need to set index to it and update all other rooms
            definedRooms[room.label] = room
        }
    }

    private var knownState: KnownState = .init()

    private var debug: Bool = true
    func log(_ message: @autoclosure () -> String) {
        if debug {
            print("[GenerateEverythingWorker] \(message())")
        }
    }

    public init(problem: Problem, client: ExplorationClient, debug: Bool = false) {
        super.init(problem: problem, client: client)
        self.debug = debug
    }

    override public func shouldContinue(iterations it: Int) -> Bool {
        knownState.uniqueRoomsCount < problem.roomsCount && it < 2
    }

    private var query: [String] = []

    override public func generatePlans() -> [String] {
        query = [String(doorPath(N: problem.roomsCount).dropFirst(iterations))]
        return query
    }

    override public func generateGuess() -> MapDescription {
        return MapDescription(rooms: [], startingRoom: 0, connections: [])
    }

    override public func processExplored(explored: ExploreResponse) {
        for (query, result) in zip(query, explored.results) {
            let querySteps = query.split(separator: "").map { Int(String($0))! }

            var currentPath: [Int] = []
            var currentRoom: ExplorationRoom = knownState.rootRoom ?? ExplorationRoom(label: result[0], path: [])
            if knownState.rootRoom == nil {
                knownState.rootRoom = currentRoom
                knownState.addRoom(currentRoom)
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
                    let newRoom = ExplorationRoom(label: toRoom, path: currentPath)
                    knownState.roomsByPath[currentPath] = newRoom
                    door.destinationRoom = newRoom
                    print("Added new room: \(newRoom.path) -> \(newRoom.label)")
                    print("Added connection: \(fromRoom)[\(fromDoor)]->\(toRoom)")
                    knownState.addRoom(currentRoom)

                    currentRoom = newRoom
                }

                knownState.addRoom(currentRoom)
            }
        }

        log("Known state: \(knownState)")
    }
}
