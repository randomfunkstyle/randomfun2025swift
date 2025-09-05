public struct Room: Codable {
    public let id: Int
    public var doors: [Int?]

    public init(id: Int) {
        self.id = id
        self.doors = Array(repeating: nil, count: 6)
    }
}

struct Door: Hashable {
    let room: Int
    let door: Int
}

public final class NaiveWorker: Worker {
    var rooms: [Room]
    var plan: [Int]
    var mapDescription: MapDescription?

    public override init(problem: Problem, client: ExplorationClient) {
        rooms = (0...2).map { Room(id: $0) }
        plan = (0..<54).map { _ in Int.random(in: 0..<6) }
        super.init(problem: problem, client: client)
    }

    public override func generatePlans() -> [String] {
        return [plan.map { String($0) }.joined()]
    }

    private func generateMapDescription() -> MapDescription? {
        var takenDoors = Set<Door>()

        var connections: [Connection] = []
        for room in rooms {
            for (doorIndex, targetRoom) in room.doors.enumerated() {
                if let targetRoom = targetRoom {
                    let destRoom = rooms[targetRoom]
                    let destDoor = findDoor(
                        room: destRoom, targetRoomId: room.id, takenDoors: takenDoors)

                    guard let destDoor = destDoor else {
                        return nil
                    }

                    let from = RoomDoor(room: room.id, door: doorIndex)
                    let to = RoomDoor(room: destRoom.id, door: destDoor)
                    takenDoors.insert(Door(room: room.id, door: doorIndex))
                    takenDoors.insert(Door(room: destRoom.id, door: destDoor))

                    connections.append(Connection(from: from, to: to))
                }
            }
        }

        return MapDescription(rooms: rooms.map { $0.id }, startingRoom: 0, connections: connections)
    }

    public override func shouldContinue(iterations: Int) -> Bool {
        return self.mapDescription == nil
    }

    public override func processExplored(explored: ExploreResponse) {
        print("Processing explored: \(explored.results)")

        let steps = zip(plan, explored.results[0]).map { (door: $0.0, result: $0.1) }

        var currentRoom = 0
        for (door, result) in steps {
            rooms[currentRoom].doors[door] = result
            currentRoom = result
        }

        self.mapDescription = self.generateMapDescription()
    }

    private func findDoor(room: Room, targetRoomId: Int, takenDoors: Set<Door>) -> Int? {
        return room.doors.firstIndex { door in
            if let door = door {
                return door == targetRoomId && !takenDoors.contains(Door(room: room.id, door: door))
            }
            return false
        }
    }

    public override func generateGuess() -> MapDescription {
        return self.mapDescription!
    }
}
