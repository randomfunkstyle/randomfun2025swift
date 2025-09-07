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
    var doors: [ExploratoinDoor] = (0 ..< 6).map { ExploratoinDoor(id: String($0)) }

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
        return "Room(label: \(label), path: \(path), index: \(index.map { "✅\($0)"} ?? "?"), potential: \(potential.sorted()), doors: [\(doorsDesc)])"
    }
}


extension [Int] {
    func asString() -> String { self.map { String($0) }.joined()}
}