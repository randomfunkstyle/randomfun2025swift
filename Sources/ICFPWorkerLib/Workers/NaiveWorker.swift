class State {
    let matrix: [[Bool]]
    let currentRoom: Int
    let steps: [Int]
    let entropy: Int

    init(matrix: [[Bool]], currentRoom: Int, steps: [Int]) {
        self.matrix = matrix
        self.currentRoom = currentRoom
        self.steps = steps
        self.entropy = Self.calcEntropy(matrix: matrix)
    }

    private static func calcEntropy(matrix: [[Bool]]) -> Int {
        return matrix.flatMap { $0 }.filter { $0 }.count
    }

    private func getIndex(doorCount: Int, room: Int, door: Int) -> Int {
        return room * doorCount + door
    }

    private func breakConnections(
        matrix: [[Bool]], fromIndex: Int, toIndex: Int
    ) -> [[Bool]] {
        var newMatrix = matrix
        newMatrix[fromIndex][toIndex] = false
        newMatrix[toIndex][fromIndex] = false

        // check if the row or column is now all false
        let rowAllFalse = !newMatrix[fromIndex].contains(true)
        let colAllFalse = !newMatrix.map { $0[toIndex] }.contains(true)

        if rowAllFalse || colAllFalse {
            return matrix
        }

        return newMatrix
    }

    func expand(roomCount: Int, doorCount: Int) -> [Int: [State]] {
        var outcomes: [Int: [State]] = [:]
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
                        newMatrix = breakConnections(
                            matrix: newMatrix, fromIndex: fromIndex, toIndex: toIndex)
                    }
                }

                let newSteps = steps + [door]
                let newState = State(
                    matrix: newMatrix,
                    currentRoom: possibleResult,
                    steps: newSteps
                )
                possibleOutcomes.append(newState)
            }
            outcomes[door] = possibleOutcomes
        }
        return outcomes
    }

    func getDecisionEntropy(door: Int, outcomes: [Int: [State]]) -> Int {
        let outcomeStates = outcomes[door]
        return outcomeStates?.map { $0.entropy }.max() ?? entropy
    }
}

public final class NaiveWorker: Worker {
    private let roomCount: Int
    private let doorCount = 6
    private var currentState: State
    private var mapDescription: MapDescription? = nil
    private var plan: [Int] = []

    public override init(problem: Problem, client: ExplorationClient) {
        self.roomCount = problem.roomsCount
        let size = problem.roomsCount * doorCount
        let initialMatrix = Array(repeating: Array(repeating: true, count: size), count: size)
        self.currentState = State(matrix: initialMatrix, currentRoom: 0, steps: [])
        super.init(problem: problem, client: client)
    }

    private func generatePlan() -> [Int] {
        var states: [State] = [currentState]

        for step in 0..<(roomCount * doorCount * 3) {
            let stateOutcomes = states.map { state in
                (state, state.expand(roomCount: roomCount, doorCount: doorCount))
            }

            var bestDoor = -1
            var bestEntropy = Int.max

            for door in 0..<doorCount {
                let doorEntropy = stateOutcomes.map { (state, outcomes) in
                    state.getDecisionEntropy(door: door, outcomes: outcomes)
                }.max()!

                if doorEntropy < bestEntropy {
                    bestEntropy = doorEntropy
                    bestDoor = door
                }
            }

            if bestEntropy == roomCount * doorCount {
                let anyState = states[0]
                return anyState.steps + [bestDoor]
            }

            states = stateOutcomes.flatMap { (_, outcomes) in outcomes[bestDoor]! }
            printMatrix(matrix: states[0].matrix)
            print(
                "Step \(step), states: \(states.count), entropy: \(bestEntropy), door: \(bestDoor)")
        }

        let anyState = states[0]
        return anyState.steps
    }

    private func printMatrix(matrix: [[Bool]]) {
        for row in matrix {
            let line = row.map { $0 ? "X" : "." }.joined(separator: " ")
            print(line)
        }
    }

    public override func generatePlans() -> [String] {
        plan = generatePlan()
        return [plan.map { String($0) }.joined()]
    }

    public override func processExplored(explored: ExploreResponse) {
        let results = explored.results[0]
        let newState = updateStateWithResults(
            currentState: currentState, plan: plan, results: results)
        self.currentState = newState
        self.mapDescription = generateMapDescription()
    }

    private func updateStateWithResults(currentState: State, plan: [Int], results: [Int]) -> State {
        var matrix = currentState.matrix
        var currentRoom = currentState.currentRoom

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

        return State(matrix: matrix, currentRoom: currentRoom, steps: [])
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

                        if self.currentState.matrix[fromIndex][toIndex] {
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
