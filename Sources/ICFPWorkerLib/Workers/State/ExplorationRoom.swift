extension Array where Element == Int {
    func intersection(_ other: [Int]) -> [Int] {
        return self.filter { other.contains($0) }
    }
}

final class ExplorationRoom: CustomStringConvertible {

    static var nextID = 0

    // List of indexeses that this room potentially could be
    var potential: [Int]

    let serializationId: Int

    // 100% unique room index
    var index: Int? {
        guard potential.count == 1 else { return nil }
        return potential.first!
    }

    // External label
    let label: Int
    var path: [Int]
    let doors: [ExploratoinDoor]
    
    /// The list of external door connections that lead to our room. We would gather them, and then try to compact and resolve them
    var externalDoorsConnections: [ExploratoinDoor] = []

    init(label: Int, path: [Int], roomsCount: Int) {
        self.label = label
        self.path = path

        var potential = [Int]()
        for i in 0..<roomsCount {
            potential.append(i)
        }
        self.potential = potential
        self.serializationId = ExplorationRoom.nextID
        ExplorationRoom.nextID += 1
        
        let doors = (0..<6).map { ExploratoinDoor(id: $0, owner:nil) }
        self.doors = doors
        for door in doors {
            door.owner = self
        }
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
            "Room(label: \(label), path: \(path), index: \(index.map { "✅\($0)"} ?? "?"), potential: \(potential.sorted()), doors: [\(doorsDesc)])"
    }
}

extension [Int] {
    func asString() -> String { self.map { String($0) }.joined() }
}
