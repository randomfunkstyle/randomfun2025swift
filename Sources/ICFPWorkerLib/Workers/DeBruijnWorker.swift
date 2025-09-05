import Foundation

@available(macOS 13.0, *)
public final class DeBruijnWorker: Worker {

    private var debug: Bool = false
    func log(_ message: @autoclosure () -> String) {
        if debug {
            print("[DeBruijnWorker] \(message())")
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
        var id: Int?
        var doors: [ExploratoinDoor] = (0..<6).map { ExploratoinDoor(id: String($0)) }
        
        init(id: Int) {
            self.id = id
        }
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
        self.explorationRooms = Array(0..<problem.roomsCount).map { id in ExplorationRoom(id: id) }
        self.roomsToProcess = Array(0..<problem.roomsCount)
        self.debug = debug
    }
    
    override public func shouldContinue(iterations _: Int) -> Bool {
        return !wasInvoked
    }
    
    // This Worker should be invoked only once per exploration with long plan
    var wasInvoked = false
    
    public override func generatePlans() -> [String] {
        defer {
            wasInvoked = true
            log("Generated plans: \(generatedQuery)")
        }
        
        guard !wasInvoked else { fatalError("generatePlans should be called only once per exploration") }
        
        self.generatedQuery = [doorPath(N: roomsToProcess.count)]
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
        
        for (_, room) in explorationRooms.enumerated() {
            for door in room.doors {
                if let destinationRoom = door.destinationRoom {
//                    let desinaroomIndex = explorationRooms.firstIndex(where: { $0 === destinationRoom })!
                    
                    if door.destinationDoor == nil {
                        /// Connect somehow door
                        ///
                        
                        // Find fir door that goes back
                        let backDoor = destinationRoom.doors.first(where: { $0.destinationRoom === room && $0.destinationDoor == nil })
                        
                        door.destinationDoor = backDoor
                        backDoor!.destinationDoor = door
                    }
                }
            }
        }
        
        var connections: [Connection] = []
        
        for (roomIndex, room) in explorationRooms.enumerated() {
            for (doorIndex, door) in room.doors.enumerated() {
                let desinaroomIndex = explorationRooms.firstIndex(where: { $0 === door.destinationRoom }) ?? roomIndex
                let toDoor = door.destinationDoor?.id ?? door.id
                connections.connect(room: roomIndex, door: doorIndex, toRoom: desinaroomIndex, toDoor: Int(toDoor)!)
            }
        }
        
        return MapDescription(rooms: rooms, startingRoom: 0, connections: connections)
    }
    
    
    public override func processExplored(explored: ExploreResponse) {
        zip(generatedQuery, explored.results).forEach { (query, result) in
            
            let listOfRooms = result
            log("Processing explored: \(query) -> \(listOfRooms)")
            
            let querySteps = query.split(separator: "").map { Int(String($0))! }
            
            for i in 0..<querySteps.count {
                let fromDoor = querySteps[i]
                
                let from = result[i]
                let toRoom = result[i + 1]
                
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
                
                log("Connecting room \(from) (our \(ourRoom)) door \(fromDoor) -> room \(toRoom) (our \(ourRoomTo))")
            }
        }
    }
    
}

import Foundation

// MARK: - De Bruijn generator (base-k, order-n) -> String of digits "0"..."(k-1)"
func deBruijn(k: Int, n: Int) -> String {
    precondition(k >= 2 && n >= 1, "k>=2, n>=1 required")

    var a = Array(repeating: 0, count: k * n)
    var seq: [Int] = []

    func db(_ t: Int, _ p: Int) {
        if t > n {
            if n % p == 0 {
                seq.append(contentsOf: a[1...p])
            }
        } else {
            a[t] = a[t - p]
            db(t + 1, p)
            if a[t - p] + 1 < k {
                for j in (a[t - p] + 1)..<k {
                    a[t] = j
                    db(t + 1, t)
                }
            }
        }
    }

    db(1, 1)
    // Map ints 0..k-1 to chars '0'.., concatenate
    let chars = seq.map { Character(String($0)) }
    return String(chars)
}

// MARK: - Utilities
@inline(__always)
func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a), y = abs(b)
    while y != 0 { (x, y) = (y, x % y) }
    return x
}

@inline(__always)
func rotatePrefix(_ s: String, by offset: Int) -> String {
    guard !s.isEmpty else { return s }
    let L = s.count
    let off = ((offset % L) + L) % L
    if off == 0 { return s }
    // Convert to array once to make indexing O(1) on slices
    let arr = Array(s)
    return String(arr[off..<L] + arr[0..<off])
}

// MARK: - Main API
/// Return a door sequence of exactly 18*N digits in {0,1,2,3,4,5}.
func doorPath(N: Int) -> String {
    let rooms = max(0, N)
    let limit = 18 * rooms
    if limit == 0 { return "" }

    let base = 6

    // Choose the largest order with block length 6^order <= limit
    // (maximize local coverage without overshooting)
    let order: Int = {
        let lf = floor(log(Double(limit)) / log(Double(base)))
        return max(1, Int(lf))
    }()

    let block = deBruijn(k: base, n: order)      // length L0 = 6^order
    let L0 = block.count

    if L0 >= limit {
        // Just take a prefix to match exactly 18N
        return String(block.prefix(limit))
    }

    // Otherwise tile rotated copies until we reach exactly 'limit'.
    // Use a rotation step co-prime with L0 to avoid aligning repeats.
    var step = 5 % L0
    if gcd(step, L0) != 1 { step = 1 }

    var out = ""
    out.reserveCapacity(limit)
    var offset = 0

    while out.count < limit {
        let rotated = rotatePrefix(block, by: offset)
        let need = limit - out.count
        if need < L0 {
            out += String(rotated.prefix(need))
            break
        } else {
            out += rotated
            offset = (offset + step) % L0
        }
    }

    return out
}
