import AccelerateLinux
import Foundation

struct Matrix {
    private var data: [Double]
    private let dimension: Int

    init(matrix: [[Double]]) {
        guard !matrix.isEmpty && matrix.count == matrix[0].count else {
            fatalError("Matrix must be non-empty and square")
        }
        self.dimension = matrix.count
        self.data = matrix.flatMap { $0 }
    }

    init(size: Int, value: Double = 0.0) {
        guard size > 0 else {
            fatalError("Matrix size must be positive")
        }
        self.dimension = size
        self.data = Array(repeating: value, count: size * size)
    }

    static func empty() -> Matrix {
        return Matrix(size: 1, value: 0.0)
    }

    func copy() -> Matrix {
        var newMatrix = Matrix(size: dimension)
        newMatrix.data = self.data
        return newMatrix
    }

    subscript(row: Int, col: Int) -> Double {
        get {
            return data[row * dimension + col]
        }
        set {
            data[row * dimension + col] = newValue
        }
    }

    var size: Int {
        return dimension
    }

    var isEmpty: Bool {
        return dimension == 1 && data[0] == 0.0
    }

    func softMax() -> Matrix {
        guard !isEmpty else { return self }

        var result = copy()

        // For a symmetric matrix, normalize each row to sum to 1
        // while maintaining symmetry
        for i in 0..<dimension {
            // Get max value in row for numerical stability
            var rowMax = Double.leastNonzeroMagnitude
            for j in 0..<dimension {
                rowMax = max(rowMax, result[i, j])
            }

            // Compute exp values for the row
            var rowExpValues = [Double](repeating: 0.0, count: dimension)
            for j in 0..<dimension {
                rowExpValues[j] = exp(result[i, j] - rowMax)
            }

            // Sum exp values in row
            let rowSum = rowExpValues.reduce(0.0, +)

            // Normalize row if sum is valid
            if rowSum > Double.leastNonzeroMagnitude {
                for j in 0..<dimension {
                    let normalizedValue = rowExpValues[j] / rowSum
                    result[i, j] = normalizedValue
                    // Maintain symmetry
                    result[j, i] = normalizedValue
                }
            }
        }

        return result
    }

    func matrixOr(matrix2: Matrix) -> Matrix {
        guard self.dimension == matrix2.dimension else {
            fatalError("Matrix dimensions must match")
        }

        var result = Matrix(size: dimension)

        vDSP_vaddD(self.data, 1, matrix2.data, 1, &result.data, 1, vDSP_Length(data.count))

        return result.softMax()
    }

    func calcEntropy() -> Double {
        guard !isEmpty else { return 0.0 }

        var entropy: Double = 0.0

        for i in 0..<size {
            for j in i..<size {
                let p = min(
                    max(self[i, j], Double.leastNonzeroMagnitude),
                    1.0 - Double.leastNonzeroMagnitude)
                let h = -(p * log2(p) + (1.0 - p) * log2(1.0 - p))
                entropy += h
            }
        }
        return entropy
    }

    func countNonZero() -> Int {
        return data.reduce(0) { count, value in
            count + (value > Double.leastNonzeroMagnitude ? 1 : 0)
        }
    }

    func isValid() -> Bool {
        guard !isEmpty else { return false }

        // Check if any row is all zeros
        for i in 0..<size {
            var hasNonZero = false
            for j in 0..<size {
                if self[i, j] > Double.leastNonzeroMagnitude {
                    hasNonZero = true
                    break
                }
            }
            if !hasNonZero {
                return false
            }
        }

        // Check if any column is all zeros
        for j in 0..<size {
            var hasNonZero = false
            for i in 0..<size {
                if self[i, j] > Double.leastNonzeroMagnitude {
                    hasNonZero = true
                    break
                }
            }
            if !hasNonZero {
                return false
            }
        }

        return true
    }

    func printMatrix() {
        guard !isEmpty else {
            print("Empty matrix")
            return
        }

        for i in 0..<size {
            let row = (0..<size).map { j in
                let value = self[i, j]
                return value <= Double.leastNonzeroMagnitude
                    ? "...." : String(format: "%.2f", value)
            }
            print(row.joined(separator: " "))
        }
    }
}

class State {
    let matrix: Matrix
    let currentRoom: Int
    let steps: [Int]
    let entropy: Double

    init(matrix: Matrix, currentRoom: Int, steps: [Int]) {
        self.matrix = matrix
        self.currentRoom = currentRoom
        self.steps = steps
        self.entropy = matrix.calcEntropy()
    }

    private func getIndex(doorCount: Int, room: Int, door: Int) -> Int {
        return room * doorCount + door
    }

    func isPossible() -> Bool {
        return matrix.isValid()
    }

    private func breakConnections(
        matrix: Matrix, fromIndex: Int, toIndex: Int
    ) -> Matrix {
        var newMatrix = matrix
        newMatrix[fromIndex, toIndex] = 0
        newMatrix[toIndex, fromIndex] = 0

        if newMatrix.isValid() {
            return newMatrix.softMax()
        }

        return matrix
    }

    func sampleOutcome(door: Int, roomCount: Int, doorCount: Int) -> State {
        let outcome = allOutcomes(door: door, roomCount: roomCount, doorCount: doorCount)
            .randomElement()

        guard let outcome = outcome else {
            return self
        }
        return outcome
    }

    func allOutcomes(door: Int, roomCount: Int, doorCount: Int) -> [State] {
        var outcomes: [State] = []

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
            if newState.isPossible() {
                outcomes.append(newState)
            }
        }

        return outcomes
    }
}

public final class NaiveWorker: Worker {
    private let roomCount: Int
    private let doorCount = 6
    private var currentStates: [State]
    private var mapDescription: MapDescription? = nil
    private var plan: [Int] = []

    // Monte Carlo configuration parameters
    private let monteCarloSamples = 100
    private let rolloutDepth = 2
    private let confidenceThreshold = 0.05

    public override init(problem: Problem, client: ExplorationClient) {
        self.roomCount = problem.roomsCount
        let size = problem.roomsCount * doorCount
        let prob = 1.0 / Double(size)
        let initialMatrix = Matrix(size: size, value: prob)
        self.currentStates = [State(matrix: initialMatrix, currentRoom: 0, steps: [])]
        super.init(problem: problem, client: client)
    }

    private func performRollout(state: State, depth: Int) -> Double {
        var currentState = state

        for _ in 0..<depth {
            let randomDoor = Int.random(in: 0..<doorCount)
            currentState = currentState.sampleOutcome(
                door: randomDoor, roomCount: roomCount, doorCount: doorCount)
        }

        return currentState.entropy
    }

    func aggregateMatrices(states: [State]) -> Matrix {
        guard !states.isEmpty else {
            return Matrix.empty()
        }
        var aggregatedMatrix = states[0].matrix
        for state in states.dropFirst() {
            aggregatedMatrix = aggregatedMatrix.matrixOr(matrix2: state.matrix)
        }
        return aggregatedMatrix
    }

    private func generatePlan() -> [Int] {
        var currentPlanStates = currentStates
        let prevStates = currentPlanStates

        for step in 0..<(roomCount * doorCount * 3) {
            var bestDoor = -1
            var bestAverageEntropy = Double.infinity

            for door in 0..<doorCount {
                var entropyResults: [Double] = []
                for currentPlanState in currentPlanStates {
                    // Run Monte Carlo samples for this door
                    for _ in 0..<monteCarloSamples {
                        let sampledState = currentPlanState.sampleOutcome(
                            door: door, roomCount: roomCount, doorCount: doorCount)

                        let rolloutResult = performRollout(
                            state: sampledState, depth: rolloutDepth)
                        entropyResults.append(rolloutResult)
                    }
                }

                let averageEntropy =
                    Double(entropyResults.reduce(0, +)) / Double(entropyResults.count)

                if averageEntropy < bestAverageEntropy {
                    bestAverageEntropy = averageEntropy
                    bestDoor = door
                }
            }

            bestDoor = max(0, bestDoor)

            // get all outcomes for each current state and the best door
            var nextPlanStates: [State] = []
            for currentPlanState in currentPlanStates {
                let outcomes = currentPlanState.allOutcomes(
                    door: bestDoor, roomCount: roomCount, doorCount: doorCount)
                nextPlanStates.append(contentsOf: outcomes)
            }

            // aggregate states with the same currentRoom
            var aggregatedStates: [Int: State] = [:]
            for state in nextPlanStates {
                if let existingState = aggregatedStates[state.currentRoom] {
                    let combinedMatrix = existingState.matrix.matrixOr(matrix2: state.matrix)
                    let combinedSteps = existingState.steps

                    aggregatedStates[state.currentRoom] = State(
                        matrix: combinedMatrix,
                        currentRoom: state.currentRoom,
                        steps: combinedSteps)
                } else {
                    aggregatedStates[state.currentRoom] = state
                }
            }
            currentPlanStates = Array(aggregatedStates.values)

            let aggregatedMatrix = aggregateMatrices(states: currentPlanStates)

            aggregatedMatrix.printMatrix()
            print(
                "Step \(step), states: \(currentPlanStates.count), entropy: \(aggregatedMatrix.calcEntropy()), door: \(bestDoor)"
            )
        }

        if currentPlanStates.isEmpty {
            currentPlanStates = prevStates
        }
        self.currentStates = currentPlanStates
        return currentStates[0].steps
    }

    public override func generatePlans() -> [String] {
        plan = generatePlan()
        return [plan.map { String($0) }.joined()]
    }

    public override func processExplored(explored: ExploreResponse) {
        let results = explored.results[0]
        var newStates: [State] = []
        for state in currentStates {
            let newState = updateStateWithResults(
                currentState: state, plan: plan, results: results)
            if newState.isPossible() {
                newStates.append(newState)
            }
        }

        self.currentStates = newStates
        self.mapDescription = generateMapDescription()
    }

    private func updateStateWithResults(currentState: State, plan: [Int], results: [Int]) -> State {
        var matrix = currentState.matrix
        print("Current state: \(currentState.steps)")
        print("Matrix before update:")
        matrix.printMatrix()

        var currentRoom = results[0]

        // skip first in the results
        for (door, nextRoom) in zip(plan, results.dropFirst()) {
            let fromIndex = currentRoom * doorCount + door

            for roomIndex in 0..<roomCount {
                if roomIndex == nextRoom {
                    continue
                }
                for destDoor in 0..<doorCount {
                    let destIndex = roomIndex * doorCount + destDoor

                    matrix[fromIndex, destIndex] = 0
                    matrix[destIndex, fromIndex] = 0
                }
            }

            matrix = matrix.softMax()
            currentRoom = nextRoom
        }

        return State(matrix: matrix, currentRoom: currentRoom, steps: [])
    }

    private func generateMapDescription() -> MapDescription? {
        let aggregatedMatrix = aggregateMatrices(states: currentStates)

        if aggregatedMatrix.isEmpty {
            return nil
        }

        if aggregatedMatrix.countNonZero() > self.roomCount * self.doorCount {
            return nil
        }

        var connections: [Connection] = []
        for fromRoom in 0..<self.roomCount {
            for fromDoor in 0..<self.doorCount {
                for toRoom in 0..<self.roomCount {
                    for toDoor in 0..<self.doorCount {
                        let fromIndex = fromRoom * self.doorCount + fromDoor
                        let toIndex = toRoom * self.doorCount + toDoor

                        if aggregatedMatrix[fromIndex, toIndex] > 0 {
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
