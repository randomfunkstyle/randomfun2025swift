import Foundation

class KnownState {
    let totalRoomsCount: Int
    let depth: Int
    var definedRooms: [ExplorationRoom?]

    init(totalRoomsCount: Int, depth: Int) {
        self.totalRoomsCount = totalRoomsCount
        self.depth = depth
        definedRooms = Array(repeating: nil, count: totalRoomsCount)
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

    func moveByPathAndGetLabels(path: [Int]) -> [Int] {
        var labels: [Int] = []
        var currentRoom = rootRoom!
        labels.append(currentRoom.label)
        for step in path {
            currentRoom = currentRoom.doors[step].destinationRoom!
            labels.append(currentRoom.label)
        }
        return labels
    }

    func path(from: ExplorationRoom? = nil,with query: (ExplorationRoom) -> Bool) -> ([Int], ExplorationRoom)? {
        let from = from ?? rootRoom!
        var queue = [(room: from, path: [Int]())]
        var visited = [ExplorationRoom]()

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            if query(current) {
                return (path, current)
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
    func path(to room: ExplorationRoom) -> [Int]? {
        return path(with: { $0 === room })?.0
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

            if current.index == nil,
               current.doors.contains(where: { $0.destinationRoom == nil })
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

    func compactRooms() {
        // Task for compact is to simplify allVisitedRooms by changing those to defined once and cleanup
        var newUnboundedRooms: [ExplorationRoom] = []

        var processedRooms: [ExplorationRoom] = []

        func mergeTwoRooms(room1: ExplorationRoom, room2: ExplorationRoom) -> ExplorationRoom {
            let mergedRoom = ExplorationRoom(
                label: room1.label, path: room1.path, roomsCount: totalRoomsCount
            )
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
                        room1: boundDestinationRoom, room2: unboundDestinationRoom
                    )
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
                logKnownState("[2]Found LAST? unique room: \(room.label) \(room.path)")
                room.potential = Set([foundUniqueRooms])
                foundUniqueRooms += 1
                definedRooms[room.index!] = room
                logKnownState("Added unique room: with \(room.index!)")
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
                        for i in 0 ..< 5 {
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
                    // TODO: Potentially, we would need to merge information form the destRoom with a defined one <---
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
        
        if let roomIndex = room.index, let definedRoomIndex = definedRoom.index {
            if roomIndex == definedRoomIndex {
                return false
            }
        }

        for (roomDoor, definedRoomDoor) in zip(room.doors, definedRoom.doors) {
            guard let definedRoomDoorDestinationRoom = definedRoomDoor.destinationRoom else {
                continue
            }
            guard let roomDoorDestinationRoom = roomDoor.destinationRoom else { continue }

            if isDifferent(
                room: roomDoorDestinationRoom, definedRoom: definedRoomDoorDestinationRoom,
                depth: depth - 1
            ) {
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
            logKnownState("[3]Found new unique room: \(room.label) \(room.path)")
            room.potential = Set([foundUniqueRooms]) // 0
            foundUniqueRooms += 1
            definedRooms[room.index!] = room
            logKnownState("Added unique room: with \(room.index!)")
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
            logKnownState("[1]Found new unique room: \(room.label) \(room.path)")
            room.potential = Set([foundUniqueRooms]) // 0
            foundUniqueRooms += 1
            definedRooms[room.index!] = room
            logKnownState("Added unique room: with \(room.index!)")
            unboundedRooms.removeAll(where: { $0 === room })
        }
    }
}

private var debugCompact: Bool = false
private func log3(_ message: @autoclosure () -> String) {
    if debugCompact {
        print("[Compact] \(message())")
    }
}

private var debugKnownState: Bool = true
private func logKnownState(_ message: @autoclosure () -> String) {
    if debugKnownState {
        print("[KnownState] \(message())")
    }
}
