public final class SixWorker: Worker {
    let builder: IncrementalRoomBuilder
    var allPaths: [String] = []
    let allLabels: [[Int]] = []
    let maxDepths = 10
    var depth = 0
    var stats: (rooms: Int, states: Int, connections: Int) = (0, 0, 0)
    var generatedPaths: [String] = []

    public override init(problem: Problem, client: ExplorationClient) {
        // Create incremental room builder
        self.builder = IncrementalRoomBuilder(maxPathLength: 18 * problem.roomsCount)
        super.init(problem: problem, client: client)
    }

    /// Generate all paths of a specific length
    private static func generatePathsOfLength(_ length: Int, current: String, paths: inout [String])
    {
        if current.count == length {
            paths.append(current)
            return
        }

        for door in 0..<6 {
            generatePathsOfLength(length, current: current + String(door), paths: &paths)
        }
    }

    public override func shouldContinue(iterations: Int) -> Bool {
        if stats.rooms == problem.roomsCount {
            return false
        }
        if depth < 6 {
            depth += 1
            return true
        }

        return false
    }

    public override func generatePlans() -> [String] {
        print("  Exploring depth \(depth):")

        // Generate all paths of this depth
        var pathsAtDepth: [String] = []
        if depth == 0 {
            pathsAtDepth = [""]
        } else {
            Self.generatePathsOfLength(depth, current: "", paths: &pathsAtDepth)
        }

        // Test a reasonable subset
        let limit = depth <= 2 ? pathsAtDepth.count : min(100, pathsAtDepth.count)
        let selectedPaths = Array(pathsAtDepth.prefix(limit))

        generatedPaths = []
        for path in selectedPaths {
            if !allPaths.contains(path) {
                generatedPaths.append(path)
                allPaths.append(path)
            }
        }
        return generatedPaths

    }
    public override func processExplored(explored: ExploreResponse) {
        builder.processExplorations(paths: generatedPaths, results: explored.results)
        stats = builder.getStatistics()
        print(
            "    Explored \(generatedPaths.count) new paths. Current: \(stats.rooms) rooms, \(stats.states) states, \(stats.connections) connections"
        )
    }

    public override func generateGuess() -> MapDescription {
        // Show final mapping
        let rooms = builder.getFinalRooms()
        var connections: [Connection] = []
        print("\n📊 FINAL MAPPING:")
        for room in rooms.sorted(by: { $0.id < $1.id }) {
            print("\n  Room \(room.id) (label \(room.label)):")
            for door in 0..<6 {
                if let conn = room.doors[door], let c = conn {
                    if c.toRoomId == room.id {
                        print("    Door \(door) → self-loop")
                    } else {
                        let toDoorStr =
                            c.toDoor ?? -1 >= 0 ? "door \(c.toDoor ?? -1)" : "unknown door"
                        print("    Door \(door) → Room \(c.toRoomId) \(toDoorStr)")
                    }
                    connections.append(
                        Connection(
                            from: RoomDoor(room: room.id, door: door),
                            to: RoomDoor(room: c.toRoomId, door: c.toDoor!)
                        )
                    )
                } else {
                    print("    Door \(door) → unmapped")
                }
            }
        }

        if rooms.count != problem.roomsCount {
            print("\n⚠️ INCOMPLETE - found \(rooms.count) rooms, expected \(problem.roomsCount)")
        }

        return MapDescription(rooms: rooms.map { $0.id }, startingRoom: 0, connections: connections)

    }
}
