
public class Worker {
    // Take a problem

    let problem: Problem
    let client: ExplorationClient

    private var iterations: Int = 0

    public init(problem: Problem, client: ExplorationClient) {
        self.client = client
        self.problem = problem
    }

    public func run() async throws {
        /// Firs select the problem
        let selected = try await client.selectProblem(problemName: problem.name)
        print("Running worker for problem: \(selected.problemName)")

        while shouldContinue(iterations: iterations) {
            iterations += 1

            let plans = generatePlans()
            print("Generated plans: \(plans)")

            /// Then explore the problem
            let explored = try await client.explore(plans: plans)

            processExplored(explored: explored)
            print("Explored: \(explored.results)")
        }

        let guess = generateGuess()
        print("Generated guess: \(guess)")

        let guessResponse = try await client.submitGuess(map: guess)
        print("Guess response: \(guessResponse)")
    }

    open func generatePlans() -> [String] {
        return []
    }

    open func processExplored(explored: ExploreResponse) {
        print("Processing explored: \(explored.results)")
    }

    open func shouldContinue(iterations _: Int) -> Bool {
        return false
    }

    open func generateGuess() -> MapDescription {
        return MapDescription(rooms: [], startingRoom: 0, connections: [])
    }
}
