
@available(macOS 13.0, *)
public final class GenerateEverythingWorker: Worker {


    private var debug: Bool = false
    func log(_ message: @autoclosure () -> String) {
        if debug {
        print("[GenerateEverythingWorker] \(message())")
        }
    }
    
    class ExploratoinDoor {
        let id: String
        var destinationRoom: ExplorationRoom?
        var destinationDoor: ExploratoinDoor?
        
        init(id: String) {
            self.id = id
        }
    }
    
    class ExplorationRoom {
        var doors: [ExploratoinDoor] = (0..<6).map { ExploratoinDoor(id: String($0)) }
    }
    
    var explorationRooms: [ExplorationRoom] = []
    
    var roomsToProcess: [Int] = []
    
    
    
    /// Do we have plan? ¯\_(ツ)_/¯ we don't know, but we will
    var currentRoom: Int?
    
    /// We have found rooms
    var foundRooms: [Int] = []
    var roomsCounter: Int = -1
    
    var generatedQuery: [String] = []
    
    /// External "labels" to our indexes
    var roomMappings: [Int: Int] = [:]
    
    /// Our indexes to external "labels"
    var roomReverseMappings: [Int: Int] = [:]
    
    var connections: [Connection] = []
    
    public init(problem: Problem, client: ExplorationClient, debug: Bool = false) {
        super.init(problem: problem, client: client)
        self.explorationRooms = Array(0..<problem.roomsCount).map { _ in ExplorationRoom() }
        self.roomsToProcess = Array(0..<problem.roomsCount)
        self.debug = debug
    }
    
    override public func shouldContinue(iterations _: Int) -> Bool {
        
        for room in explorationRooms {
            if room.doors.contains(where: { $0.destinationRoom == nil }) {
                return true
            }
        }

        log("All rooms are processed 🎉")
        return false
    }
    
    public override func generatePlans() -> [String] {
        defer {
            log("Generated plans: \(generatedQuery)")
        }
        if roomsCounter == -1 {
            roomsToProcess.removeAll(where: { $0 == 0 })
            self.generatedQuery = ["0", "1", "2", "3", "4", "5"]
            return generatedQuery
            
        }
        
        let roomIdToProcess = roomsToProcess.first(where: { roomReverseMappings[$0] != nil })!
        roomsToProcess.removeAll(where: { $0 == roomIdToProcess })

        let pathToRoom = findShortestPath(from: 0, to: roomIdToProcess)!
        
        self.generatedQuery = ["0", "1", "2", "3", "4", "5"].map { pathToRoom + $0 }
        return generatedQuery
    }
    
    public func findShortestPath(from: Int, to: Int) -> String? {
        var queue = [(room: from, path: "")]
        var visited = Set<Int>()
        
        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            if current == to {
                return path
            }
            visited.insert(current)
            for door in explorationRooms[current].doors {
                if let nextRoom = door.destinationRoom {
                    let id = explorationRooms.firstIndex(where: { $0 === nextRoom })!
                    queue.append((id, path + String(door.id)))
                }
            }
        }
        
        return nil
    }
    
    public override func generateGuess() -> MapDescription {
        /// TODO:
        let rooms = explorationRooms.enumerated().map { (index, _) in roomReverseMappings[index]! }
        
        for (roomIndex, room) in explorationRooms.enumerated() {
            for door in room.doors {
                if let destinationRoom = door.destinationRoom {
                    let desinaroomIndex = explorationRooms.firstIndex(where: { $0 === destinationRoom })!
                    
                    if door.destinationDoor == nil {
                        /// Connect somehow door
                        ///
                        
                        // Find fir door that goes back
                        let backDoor = destinationRoom.doors.first(where: { $0.destinationRoom === room && $0.destinationDoor == nil })!
                        
                        door.destinationDoor = backDoor
                        backDoor.destinationDoor = door
                    }
                }
            }
        }
        
        var connections: [Connection] = []
        
        for (roomIndex, room) in explorationRooms.enumerated() {
            for (doorIndex, door) in room.doors.enumerated() {
                let desinaroomIndex = explorationRooms.firstIndex(where: { $0 === door.destinationRoom })!
                connections.connect(room: roomIndex, door: doorIndex, toRoom: desinaroomIndex, toDoor: Int(door.destinationDoor!.id)!)
            }
        }
        
        return MapDescription(rooms: rooms, startingRoom: 0, connections: connections)
    }
    
    
    public override func processExplored(explored: ExploreResponse) {
        zip(generatedQuery, explored.results).forEach { (query, result) in
            
            
            let (from, toRoom) = (result[result.count - 2], result.last!)
            let fromDoor = Int(String(query.last!))!
            
            if roomMappings[from] == nil {
                roomsCounter += 1
                roomMappings[from] = roomsCounter
                roomReverseMappings[roomsCounter] = from
            }
            
            if roomMappings[toRoom] == nil {
                roomsCounter += 1
                roomMappings[toRoom] = roomsCounter
                roomReverseMappings[roomsCounter] = toRoom
            }
            
            let ourRoom = roomMappings[from]!
            let ourRoomTo = roomMappings[toRoom]!
            
            explorationRooms[ourRoom].doors[fromDoor].destinationRoom = explorationRooms[ourRoomTo]
            // We cannot make reverse connection, because we don't know the return door
            
        }
    }
    
    
}


