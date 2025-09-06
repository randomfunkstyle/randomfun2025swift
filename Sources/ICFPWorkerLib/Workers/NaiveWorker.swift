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

    func sampleOutcome(door: Int, roomCount: Int, doorCount: Int) -> State {
        let possibleResult = Int.random(in: 0..<roomCount)
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
        return State(
            matrix: newMatrix,
            currentRoom: possibleResult,
            steps: newSteps
        )
    }
}

public final class NaiveWorker: Worker {
    private let roomCount: Int
    private let doorCount = 6
    private var currentState: State
    private var mapDescription: MapDescription? = nil
    private var plan: [Int] = []

    // Monte Carlo configuration parameters
    private let monteCarloSamples = 1000
    private let rolloutDepth = 8
    private let confidenceThreshold = 0.05

    public override init(problem: Problem, client: ExplorationClient) {
        self.roomCount = problem.roomsCount
        let size = problem.roomsCount * doorCount
        let initialMatrix = Array(repeating: Array(repeating: true, count: size), count: size)
        self.currentState = State(matrix: initialMatrix, currentRoom: 0, steps: [])
        super.init(problem: problem, client: client)
    }

    private func performRollout(state: State, depth: Int) -> Int {
        var currentState = state

        for _ in 0..<depth {
            if currentState.entropy <= roomCount * doorCount {
                break
            }

            let randomDoor = Int.random(in: 0..<doorCount)
            currentState = currentState.sampleOutcome(
                door: randomDoor, roomCount: roomCount, doorCount: doorCount)
        }

        return currentState.entropy
    }

    private func generatePlan() -> [Int] {
        var currentPlanState = currentState

        for step in 0..<(roomCount * doorCount * 3) {
            var bestDoor = -1
            var bestAverageEntropy = Double.infinity

            for door in 0..<doorCount {
                var entropyResults: [Int] = []

                // Run Monte Carlo samples for this door
                for _ in 0..<monteCarloSamples {
                    let sampledState = currentPlanState.sampleOutcome(
                        door: door, roomCount: roomCount, doorCount: doorCount)
                    let rolloutResult = performRollout(state: sampledState, depth: rolloutDepth)
                    entropyResults.append(rolloutResult)
                }

                let averageEntropy =
                    Double(entropyResults.reduce(0, +)) / Double(entropyResults.count)

                if averageEntropy < bestAverageEntropy {
                    bestAverageEntropy = averageEntropy
                    bestDoor = door
                }
            }

            if bestAverageEntropy <= Double(roomCount * doorCount) {
                return currentPlanState.steps + [bestDoor]
            }

            // Take the best door and sample one outcome for the next iteration
            currentPlanState = currentPlanState.sampleOutcome(
                door: bestDoor, roomCount: roomCount, doorCount: doorCount)

            printMatrix(matrix: currentPlanState.matrix)
            print(
                "Step \(step), entropy: \(bestAverageEntropy), door: \(bestDoor)")
        }

        return currentPlanState.steps
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
