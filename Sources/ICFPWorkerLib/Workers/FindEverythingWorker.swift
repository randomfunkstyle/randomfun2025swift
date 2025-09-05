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

        // External label
        let label: Int
        let path: [Int]
        let doors: [ExploratoinDoor] = (0..<6).map { ExploratoinDoor(id: String($0)) }

        init(label: Int, path: [Int]) {
            self.label = label
            self.path = path
        }
    }

    // When we're requesting query, we're receiving a chain of rooms we visited.
    // So the idea is to store chains with the rooms start with current label and the the rest of the chain
    // We would be able to hold this information and have sub-chains that should help us matching the chains

    // 2 Doors per room
    // 3 Rooms ....

    //  0[0]-> 0   A0
    //  0[1]-> 1   A0
    //  1[0] -> 0  B1
    //  1[1] -> 2  B1
    //  2[0] -> 2  C0
    //  2[1] -> 1  C0

    // For example for the request       
    // We would recieve a chain of rooms
    //  0 - 1 - 0 - 0 - 1 
    //  0   0   1 - 0 - 0 - 1

// // 1 00
//     000 -> 011 -> 100 -> (?)000 -> 011
//   (?)  000 -> 01 (5)
// // 2 01
//     000 -> 011 -> 100 -> (?)000 -> 011
// // 3 10
//     000 -> 011 -> 100 -> (?)000 -> 011
// // 4 11
//     000 -> 011 -> 100 -> (?)000 -> 011

//  (?) 000 -> 011 
//       4      5

//      01?     X
//      1       2      3         4      5

//  (?) 01? -> Y 
//       4      5

// // Suggested
//      011 ..
//      000 -> 011 -> 100 -> (?)010 ...

//      011 -> 100 -> 000 -> 011
     
//      100 -> 000 -> 011
    
    

    typealias RoomId = Int
    
    /// This is the bucket of rooms, that start from the same label. It contains all the rooms that we know that start with this label
    private class RoomsBucket {
        
        let startingLabel: Int
        
        /// Definitely unique rooms. Just because we know that they are unique. First one is always unique, others are questionable
        var uniqueRooms: [ExplorationRoom] = []
        
        // 010->.......->(010) --->
        
        // 010->.......->02?
        // 02?->.......
        
        // 0->[1]->1
        
        var nonUniqueRooms: [ExplorationRoom] = [
            // 10401134120
        ]
        
        struct Mapping: Hashable {
            let door: Int
            let label: Int
        }
        var uniqueMaps: [Set<Mapping>] = (0...5).map { _ in Set<Mapping>() }
        
        init(_ startingLabel: Int) {
            self.startingLabel = startingLabel
        }
        
        func addRoom(_ room: ExplorationRoom) {
            
            for door in room.doors {
                guard let destinationRoom = door.destinationRoom else {
                    continue
                }
                let doorID = Int(door.id)!
                let mapping = Mapping(door: doorID, label: destinationRoom.label)
                uniqueMaps[doorID].insert(mapping)
            }
            
            
            if uniqueRooms.isEmpty {
                uniqueRooms.append(room)
            } else {
         
                if verifyUniqueness(of: room) {
                    uniqueRooms.append(room)
                    nonUniqueRooms.removeAll(where: { $0 === room })
                } else {
                    if !nonUniqueRooms.contains(where: { $0 === room }) {
                        nonUniqueRooms.append(room)
                    }
                }
            }
        }
        
        private func verifyUniqueness(of room: ExplorationRoom) -> Bool {
            uniqueRooms.allSatisfy({
                var visitedRooms: [ExplorationRoom] = []
                return verifyUniqueness(of: room, another: $0, visitedRooms: &visitedRooms)
            })
        }
        
        private func verifyUniqueness(of room: ExplorationRoom, another: ExplorationRoom, visitedRooms: inout [ExplorationRoom]) -> Bool {
            guard room !== another else {
                return false
            }
            
            for (door1, door2) in zip(room.doors, another.doors) {
                if let dest1 = door1.destinationRoom, let dest2 = door2.destinationRoom {
                    if dest1.label != dest2.label {
                        return true
                    }
                }
            }
            
            for (door1, door2) in zip(room.doors, another.doors) {
                if let dest1 = door1.destinationRoom, let dest2 = door2.destinationRoom {
                    if visitedRooms.contains(where: { $0 === dest1}) {
                        continue
                    }
                    visitedRooms.append(dest1)
                    if verifyUniqueness(of: dest1, another: dest2, visitedRooms: &visitedRooms) {
                        return true
                    }
                }
            }
            
            return false
        }
            
    }
        

    private class KnownState: CustomStringConvertible {

        var roomsByPath: [[Int]: ExplorationRoom] = [:]

        // This is basically the room with the startPath []
        var rootRoom: ExplorationRoom?
        
        var buckets: [Int: RoomsBucket] = [
            0: RoomsBucket(0),
            1: RoomsBucket(1),
            2: RoomsBucket(2),
            3: RoomsBucket(3)
        ]
        
        func addRoom(_ room: ExplorationRoom) {
            roomsByPath[room.path] = room
            buckets[room.label]!.addRoom(room)
        }
        
        var uniqueRoomsCount: Int {
            return buckets.values.reduce(0) { $0 + max($1.uniqueRooms.count, $1.uniqueMaps.max(by: {$0.count < $1.count})!.count) }
        }
        
        var description: String {
            var desc = "KnownState:\n"
            desc += " Total unique rooms: \(uniqueRoomsCount)\n"
            for (label, bucket) in buckets.sorted(by: { $0.key < $1.key }) {
                desc += "  Label \(label): \(bucket.uniqueRooms.count) unique, \(bucket.nonUniqueRooms.count) non-unique\n"
                for unique in bucket.uniqueRooms {
                    desc += "   U: \(unique.path) -> \(unique.label)\n"
                }
            }
            return desc
        }
        
    }

    private var knownState: KnownState = KnownState()


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
        knownState.uniqueRoomsCount < problem.roomsCount && it < 1000
    }
    
    private var query: [String] = []

    public override func generatePlans() -> [String] {
        self.query = [doorPath(N: problem.roomsCount)]
        return self.query
    }
    
    
    public override func generateGuess() -> MapDescription {
        
        return MapDescription(rooms: [], startingRoom: 0, connections: [])
    }
    
    
    public override func processExplored(explored: ExploreResponse) {

        for (query, result) in zip(self.query, explored.results) {

           let querySteps = query.split(separator: "").map { Int(String($0))! }

           var currentPath: [Int] = []
           var currentRoom: ExplorationRoom = knownState.rootRoom ?? ExplorationRoom(label: result[0], path: [])
           if knownState.rootRoom == nil {
               knownState.rootRoom = currentRoom
               knownState.addRoom(currentRoom)
           }

           for i in 0..<querySteps.count {

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


