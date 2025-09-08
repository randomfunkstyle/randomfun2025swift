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

    func returnMermaidMap() -> String {
        var mermaidMap = ""
        mermaidMap += "graph G {\n"
        for (index, room) in definedRooms.compactMap({ $0 }).enumerated() {
            mermaidMap += "subgraph N\(index)[\"\(index)\"]\n"
            for (doorIndex, door) in room.doors.enumerated() {
                mermaidMap += "N\(index)\(doorIndex)[\"\(doorIndex)\"]\n"
            }
            mermaidMap += "end\n"
        }

        // Connections
        for (index, room) in definedRooms.compactMap({ $0 }).enumerated() {
            for (doorIndex, door) in room.doors.enumerated() {
                guard let destinationRoom = door.destinationRoom else { continue }
                mermaidMap +=
                    "N\(index)\(doorIndex) -- N\(destinationRoom.index!)\(door.destinationDoor!.id)\n"
            }
        }

        mermaidMap += "}"
        return mermaidMap
    }

    func boundAndUnboundDoors() -> (definedDoors: Int, undefined: Int, zeroDoors: Int) {
        var undefinedDoors = 0
        var definedDoors = 0
        var zeroDoors = 0
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
                } else {
                    zeroDoors += 1
                }
            }
        }
        return (definedDoors, undefinedDoors, zeroDoors)
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

    func path(from: ExplorationRoom? = nil, with query: (ExplorationRoom) -> Bool) -> (
        [Int], ExplorationRoom
    )? {
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
                    queue.append((nextRoom, path + [door.id]))
                }
            }
        }
        return nil
    }

    func findRoomUsingCursor(with query: (ExplorationRoom) -> Bool) -> (ExplorationRoom, ExploratoinDoor)? {
        let from = rootRoom!
        var queue = [(room: from, path: [ExploratoinDoor]())]
        var visited = [ExplorationRoom]()

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            if query(current) {
                return (current, path.last!)
            }
            if visited.contains(where: { $0 === current }) {
                continue
            }
            visited.append(current)

            for door in current.doors {
                if let nextRoom = door.destinationRoom {
                    if !nextRoom.externalDoorsConnections.contains(where: { $0 == door }) {
                        nextRoom.externalDoorsConnections.append(door)
                    }
                    queue.append((nextRoom, path + [door]))
                }
            }
        }
        return nil
    }

    func findAllRoomsUsingCursor(with query: (ExplorationRoom) -> Bool) -> [(ExplorationRoom, ExploratoinDoor)] {
                let from = rootRoom!
        var queue = [(room: from, path: [ExploratoinDoor]())]
        var visited = [ExplorationRoom]()
        var res = [(ExplorationRoom, ExploratoinDoor)]()

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            if query(current) {
                res.append((current, path.last!))
            }
            if visited.contains(where: { $0 === current }) {
                continue
            }
            visited.append(current)

            for door in current.doors {
                if let nextRoom = door.destinationRoom {
                    if !nextRoom.externalDoorsConnections.contains(where: { $0 == door }) {
                        nextRoom.externalDoorsConnections.append(door)
                    }
                    queue.append((nextRoom, path + [door]))
                }
            }
        }
        return res
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
                    queue.append((nextRoom, path + [door.id]))
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
                    queue.append((nextRoom, path + [door.id]))
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
        compactRooms()
    }

    func mergeTwoRooms(room1: ExplorationRoom, room2: ExplorationRoom) -> ExplorationRoom {
        var processedPairs: [(Int, Int)] = []
        var processedRooms: [ExplorationRoom] = []
        mergeToRoom(mergeTo: room1, additionalRoom: room2, processedPairs: &processedPairs, processedRooms: &processedRooms)
        return room1
    }

    private struct LabelAndDoor: Hashable {
        let label: Int // 0, 1, 2, 3
        let door: Int
    }

    func collapseConnections() {
        var proccesedRooms: [Int] = []

        while true {
            let roomAndDoors: [(ExplorationRoom, ExploratoinDoor)] = findAllRoomsUsingCursor(with: {
                guard let index = $0.index else { return false }
                guard definedRooms[index]?.serializationId != $0.serializationId else { return false }
                return true
            })
            guard !roomAndDoors.isEmpty else { break }
            print("Found \(roomAndDoors.count) rooms to collapse ⏲")

             for roomAndDoor in roomAndDoors {
                let (room, _) = roomAndDoor
//                print("Reached room \(room.index!) \(room.serializationId) through \(door.serializationId)  ")
                let definedRoom = definedRooms[room.index!]!

                for externalDoor in room.externalDoorsConnections {
                    guard externalDoor.destinationRoom!.serializationId != definedRoom.serializationId  else { continue }
                    externalDoor.destinationRoom = definedRoom
                }      

                 _ = mergeTwoRooms(room1: definedRoom, room2: room)

            } 
        }

        while true {
            if let path = path(with: {
                guard !proccesedRooms.contains($0.serializationId) else { return false }
                guard $0.externalDoorsConnections.count >= 6 else { return false }
                return true
            }) {
                let (_, room) = path
                proccesedRooms.append(room.serializationId)

                // Try to get unique number of external connection by pair (source.label + source.door)

                _ = {
                    var externalConnectionsByLabelAndDoor: [LabelAndDoor: [ExploratoinDoor]] = [:]
                    
                    for externalConnection in room.externalDoorsConnections {
                        let labelAndDoor = LabelAndDoor(label: externalConnection.owner!.label, door: externalConnection.id)
                        externalConnectionsByLabelAndDoor[labelAndDoor, default: []].append(externalConnection)
                    }
                    
                    if externalConnectionsByLabelAndDoor.count > 6 {
                        print("This is the end, leave Earth immediately!")
                        fatalError("There were too many external connections: \(externalConnectionsByLabelAndDoor)")
                    }
                    
//                    print("Collapsed to \(externalConnectionsByLabelAndDoor.count)")
                    
                    guard externalConnectionsByLabelAndDoor.count == 6 else { return }
                    
//                    print("Going to collapse into 6 connections: \(externalConnectionsByLabelAndDoor.keys.map { "\($0.label):\($0.door)" }) from \(room.externalDoorsConnections.count)")
                    
                    var processedPairs: [(Int, Int)] = []
                    var processedRooms: [ExplorationRoom] = []
                    var finalConnections: [ExploratoinDoor] = []
                    for (labelAndDoor, externalConnections) in externalConnectionsByLabelAndDoor {
                        let owner = externalConnections.first!.owner!
                        finalConnections.append(owner.doors[labelAndDoor.door])
                        for externalConnection in externalConnections {
                            mergeToRoom(mergeTo: owner, additionalRoom: externalConnection.owner!, processedPairs: &processedPairs, processedRooms: &processedRooms)
                        }
                    }
                    
                    // Collapse to 6 connections
//                    print("Collapsing to 6 connections: \(finalConnections.count) from \(room.externalDoorsConnections.count)")
                    room.externalDoorsConnections = finalConnections
                    room.has6UniqueExternals = true
                }()
                
                _ = {
                    if room.has6UniqueExternals { return    }
                    var externalConnectionsByLabelAndDoor: [LabelAndDoor: [ExploratoinDoor]] = [:]
                    
                    for externalConnection in room.externalDoorsConnections {
                        if let idx = externalConnection.owner?.index {
                            let labelAndDoor = LabelAndDoor(label: idx, door: externalConnection.id)
                            externalConnectionsByLabelAndDoor[labelAndDoor, default: []].append(externalConnection)
                        }
                    }
                    
                    if externalConnectionsByLabelAndDoor.count > 6 {
                        print("This is the end, leave Earth immediately!")
                        fatalError("There were too many external connections: \(externalConnectionsByLabelAndDoor)")
                    }

//                    print("!!!!!!! Collapsed to \(externalConnectionsByLabelAndDoor.count) from \(room.externalDoorsConnections.count)")

                    guard externalConnectionsByLabelAndDoor.count == 6 else { return }
                    
                    print("!!!!!! Going to collapse into 6 connections: \(externalConnectionsByLabelAndDoor.keys.map { "\($0.label):\($0.door)" }) from \(room.externalDoorsConnections.count)")
                    
                    let totalConnections = externalConnectionsByLabelAndDoor.reduce(0) { $0 + $1.value.count }
                    print(">>>>>> Total connections to collapse: \(totalConnections)")
                    
                    var processedPairs: [(Int, Int)] = []
                    var processedRooms: [ExplorationRoom] = []
                    var finalConnections: [ExploratoinDoor] = []
                    for (labelAndDoor, externalConnections) in externalConnectionsByLabelAndDoor {
                        let owner = externalConnections.first!.owner!
                        finalConnections.append(owner.doors[labelAndDoor.door])
                        for externalConnection in externalConnections {
                            mergeToRoom(mergeTo: owner, additionalRoom: externalConnection.owner!, processedPairs: &processedPairs, processedRooms: &processedRooms)
                        }
                    }
                    
                    // Collapse to 6 connections
                    print("Collapsing to 6 connections: \(finalConnections.count) from \(room.externalDoorsConnections.count)")
                    room.externalDoorsConnections = finalConnections
                    room.has6UniqueExternals = true
                }()
            } else {
                break
            }
        }
    }

    func mergeToRoom(mergeTo: ExplorationRoom, additionalRoom: ExplorationRoom, processedPairs: inout [(Int, Int)], processedRooms: inout [ExplorationRoom]) {
        guard mergeTo.serializationId != additionalRoom.serializationId else { return }
        guard !processedPairs.contains(where: { $0.0 == mergeTo.serializationId && $0.1 == additionalRoom.serializationId }) else { return }
        processedPairs.append((mergeTo.serializationId, additionalRoom.serializationId))
        processedRooms.append(mergeTo)

        mergeTo.potential = mergeTo.potential.intersection(additionalRoom.potential)
        

        for (unboundRoomDoor, boundRoomDoor) in zip(mergeTo.doors, additionalRoom.doors) {
            
            if let dest = boundRoomDoor.destinationRoom{
                dest.externalDoorsConnections.removeAll(where: { $0 == boundRoomDoor })
                if !dest.externalDoorsConnections.contains(unboundRoomDoor) {
                    dest.externalDoorsConnections.append(unboundRoomDoor)
                }

            }
            
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

                let room1 = boundDestinationRoom
                let room2 = unboundDestinationRoom
                mergeToRoom(mergeTo: room1, additionalRoom: room2, processedPairs: &processedPairs, processedRooms: &processedRooms)

                boundRoomDoor.destinationRoom = room1
                unboundRoomDoor.destinationRoom = room1
                
//                collapseConnections(room1, room2)
            }
        }
    }

    func compactRooms() {
        // Task for compact is to simplify allVisitedRooms by changing those to defined once and cleanup
        var newUnboundedRooms: [ExplorationRoom] = []

        var processedRooms: [ExplorationRoom] = []

        for room in unboundedRooms {
            guard !processedRooms.contains(where: { $0 === room }) else { continue }
            removeAllInvalidPotentialIndexes(room)

            // As if nothing happened, leave as it is, we still not sure what this is room about
            guard let index = room.index else {
                newUnboundedRooms.append(room)
                continue
            }

            // Room is unbound, but have and index so ti basically the same as one one of bounded/defined rooms

            // Merge information with the defined room, if we know everything about it
            if let definedRoom = definedRooms[index] {
                var processedPairs: [(Int, Int)] = []
                mergeToRoom(mergeTo: room, additionalRoom: definedRoom, processedPairs: &processedPairs, processedRooms: &processedRooms)
            } else {
                // This is a new unique room found (The last room)
                logKnownState("[2]Found LAST? unique room: \(room.label) \(room.path)")
                room.potential = [foundUniqueRooms]
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

                    if definedRooms[idx] == nil {
                        // This is a new unique room found
                        logKnownState(
                            "[4]Found new unique room: \(destRoom.label) \(destRoom.path)")
                        destRoom.potential = [foundUniqueRooms] // 0
                        foundUniqueRooms += 1
                        definedRooms[destRoom.index!] = destRoom
                        logKnownState("Added unique room: with \(destRoom.index!)")
                        //                        unboundedRooms.removeAll(where: { $0 === destRoom })
                    }

                    // This can be new room

                    let definedRoom = definedRooms[idx]!

                    door.destinationRoom = definedRoom
                    // TODO: Potentially, we would need to merge information form the destRoom with a defined one <---
                }
            }
        }

        unboundedRooms = newUnboundedRooms
    }

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

    // SAFE: Totaly Safe, just removing impossible indexes from potential
    private func removeAllInvalidPotentialIndexes(_ room: ExplorationRoom) {
        for definedRoom in definedRooms {
            guard let definedRoom = definedRoom else { continue }
            guard let definedRoomIndex = definedRoom.index else { continue }
            guard room.potential.contains(definedRoomIndex) else { continue }

            if isDifferent(room: room, definedRoom: definedRoom, depth: depth) {
                room.potential.removeAll(where: { $0 == definedRoomIndex })
                continue
            }
        }
    }

    func dfsIsDifferent(room: ExplorationRoom, definedRoom: ExplorationRoom, maxDepth: Int) -> Bool {
        guard maxDepth > 0 else { return false }
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

            if dfsIsDifferent(
                room: roomDoorDestinationRoom,
                definedRoom: definedRoomDoorDestinationRoom,
                maxDepth: maxDepth - 1
            ) {
                return true
            }
        }

        return false
    }

    func isDifferent(room: ExplorationRoom, definedRoom: ExplorationRoom, depth: Int)
        -> Bool
    {
        dfsIsDifferent(room: room, definedRoom: definedRoom, maxDepth: depth)
    }

    func addRoom(_ room: ExplorationRoom) {
        if room.index != nil {
            // Room kind'a bounded, but check if there's defined room with the same index
            guard definedRooms[room.index!] == nil else { return }

            // This is a new unique room found
            logKnownState("[3]Found new unique room: \(room.label) \(room.path)")
            room.potential = [foundUniqueRooms] // 0
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
            room.potential = [foundUniqueRooms] // 0
            foundUniqueRooms += 1
            definedRooms[room.index!] = room
            logKnownState("Added unique room: with \(room.index!)")
            unboundedRooms.removeAll(where: { $0 === room })
        }
    }

    func constructGraph() -> [GraphNode] {
        guard let startingPoint = rootRoom else {
            return []
        }

        var roomToGraphNode: [Int: GraphNode] = [:]
        var rooms: [ExplorationRoom] = []

        var queue = [startingPoint]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            roomToGraphNode[current.serializationId] = GraphNode(
                nodeId: current.serializationId,
                roomLabel: current.label,
                roomIndex: current.index,
                doors: Array(repeating: nil, count: current.doors.count)
            )
            rooms.append(current)

            for door in current.doors {
                if let nextRoom = door.destinationRoom {
                    if roomToGraphNode.keys.contains(nextRoom.serializationId) {
                        continue
                    }
                    queue.append(nextRoom)
                }
            }
        }

        for room in rooms {
            let graphNode = roomToGraphNode[room.serializationId]!
            for (doorIndex, door) in room.doors.enumerated() {
                if let destRoom = door.destinationRoom {
                    graphNode.doors[doorIndex] = destRoom.serializationId
                }
            }
        }

        return Array(roomToGraphNode.values)
    }
}

private var iterationCounter: Int = 0
private var measureMap: [String: TimeInterval] = [:]

func measureTwoVariants<T: Equatable>(
    _ name: String, _ first: @autoclosure () -> T, _ name2: String, _ second: @autoclosure () -> T
) -> T {
    let start = Date()
    let result = first()
    let duration = Date().timeIntervalSince(start)
    measureMap[name, default: 0] += duration

    let start2 = Date()
    let result2 = second()
    let duration2 = Date().timeIntervalSince(start2)
    measureMap[name2, default: 0] += duration2

    iterationCounter += 1

    if iterationCounter % 1000 == 0 {
        let total1 = measureMap[name] ?? 0
        let total2 = measureMap[name2] ?? 0

        let percentage = abs(total1 - total2) / max(total1, total2) * 100
        let fasterVariant = total1 < total2 ? name : name2
        print("\(fasterVariant) is faster by \(percentage)%")
    }

    assert(result == result2)
    return result
}

private var debugCompact: Bool = false
private func log3(_ message: @autoclosure () -> String) {
    if debugCompact {
        print("[Compact] \(message())")
    }
}

private var debugKnownState: Bool = false
private func logKnownState(_ message: @autoclosure () -> String) {
    if debugKnownState {
        print("[KnownState] \(message())")
    }
}
