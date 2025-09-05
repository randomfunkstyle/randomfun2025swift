class State {
    let matrix: [[Bool]]
    let currentRoom: Int
    let steps: [Int]
    var entropy: Int
    var outcomes: [Int: [State]] = [:]

    init(matrix: [[Bool]], currentRoom: Int, steps: [Int], entropy: Int) {
        self.matrix = matrix
        self.currentRoom = currentRoom
        self.steps = steps
        self.entropy = entropy
    }

    func calcEntropy(matrix: [[Bool]]) -> Int {
        return matrix.flatMap { $0 }.filter { $0 }.count
    }

    private func getIndex(doorCount: Int, room: Int, door: Int) -> Int {
        return room * doorCount + door
    }

    func expand(roomCount: Int, doorCount: Int) {
        outcomes = [:]
        for door in 0..<doorCount {
            var possibleOutcomes: [State] = []

            for possibleResult in 0..<roomCount {
                var newMatrix = matrix

                let fromIndex = currentRoom * doorCount + door

                for roomIndex in 0..<roomCount {
                    if roomIndex == possibleResult {
                        continue
                    }

                    for destDoor in 0..<doorCount {
                        let toIndex = roomIndex * doorCount + destDoor
                        newMatrix[fromIndex][toIndex] = false
                        newMatrix[toIndex][fromIndex] = false
                    }
                }

                let newSteps = steps + [door]
                let newState = State(
                    matrix: newMatrix,
                    currentRoom: possibleResult,
                    steps: newSteps,
                    entropy: calcEntropy(matrix: newMatrix)
                )
                possibleOutcomes.append(newState)
            }
            outcomes[door] = possibleOutcomes
        }
    }

    func getDecisionEntropy(door: Int) -> Int {
        let outcomeStates = outcomes[door]
        return outcomeStates?.map { $0.entropy }.max() ?? entropy
    }
}

public final class NaiveWorker: Worker {
    var matrix: [[Bool]]
    let roomCount: Int
    let doorCount = 6
    var plan: [Int]
    var currentState: State
    var mapDescription: MapDescription? = nil

    public override init(problem: Problem, client: ExplorationClient) {
        self.roomCount = problem.roomsCount
        let size = problem.roomsCount * doorCount
        self.matrix = Array(repeating: Array(repeating: true, count: size), count: size)
        self.plan = []
        self.currentState = State(matrix: matrix, currentRoom: 0, steps: [], entropy: size * size)
        super.init(problem: problem, client: client)
    }

    private func generatePlan() -> [Int] {
        var states: [State] = [currentState]

        for step in 0..<(roomCount * doorCount * 3) {
            for state in states {
                state.expand(roomCount: roomCount, doorCount: doorCount)
            }

            var bestDoor = -1
            var bestEntropy = Int.max

            for door in 0..<doorCount {
                let doorEntropy = states.map { $0.getDecisionEntropy(door: door) }.max()!

                if doorEntropy < bestEntropy {
                    bestEntropy = doorEntropy
                    bestDoor = door
                }
            }

            if bestEntropy == roomCount * doorCount {
                let anyState = states[0]
                return anyState.steps + [bestDoor]
            }

            states = states.flatMap { $0.outcomes[bestDoor]! }
            print(
                "Step \(step), states: \(states.count), entropy: \(bestEntropy), door: \(bestDoor)")
        }

        let anyState = states[0]
        return anyState.steps
    }

    public override func generatePlans() -> [String] {
        plan = generatePlan()
        return [plan.map { String($0) }.joined()]
    }

    public override func processExplored(explored: ExploreResponse) {
        let results = explored.results[0]
        var currentRoom = 0

        for door in plan {
            let nextRoom = results[door]
            let fromIndex = currentRoom * doorCount + door
            let toIndex = nextRoom * doorCount + door

            for roomIndex in 0..<roomCount {
                for destDoor in 0..<doorCount {
                    let destIndex = roomIndex * doorCount + destDoor

                    if destIndex != toIndex {
                        matrix[fromIndex][destIndex] = false
                    }

                    if destIndex != fromIndex {
                        matrix[destIndex][fromIndex] = false
                    }
                }
            }
            currentRoom = nextRoom
        }
        self.currentState = State(
            matrix: matrix, currentRoom: currentRoom, steps: [],
            entropy: matrix.flatMap { $0 }.filter { $0 }.count)
        self.mapDescription = generateMapDescription()
    }

    private func generateMapDescription() -> MapDescription? {
        if self.currentState.entropy > self.roomCount * self.doorCount {
            return nil
        }

        var connections: [Connection] = []
        for fromRoom in 0..<self.roomCount {
            for fromDoor in 0..<self.doorCount {
                for toRoom in 0..<self.roomCount {
                    for toDoor in 0..<self.doorCount {
                        let fromIndex = fromRoom * self.doorCount + fromDoor
                        let toIndex = toRoom * self.doorCount + toDoor

                        if self.matrix[fromIndex][toIndex] {
                            let connection = Connection(
                                from: RoomDoor(room: fromRoom, door: fromDoor),
                                to: RoomDoor(room: toRoom, door: toDoor)
                            )
                            connections.append(connection)
                        }
                    }
                }
            }
        }

        return MapDescription(
            rooms: Array(0..<self.roomCount), startingRoom: 0, connections: connections)
    }

    public override func shouldContinue(iterations: Int) -> Bool {
        return self.mapDescription == nil
    }

    public override func generateGuess() -> MapDescription {
        return self.mapDescription!
    }
}
