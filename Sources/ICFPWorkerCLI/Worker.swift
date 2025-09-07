import ArgumentParser
import Foundation
import ICFPWorkerLib

struct CountLines: AsyncParsableCommand {
    func run() async throws {
        print("🚀 ICFP Worker CLI")
        print("==================")

        // Check command line arguments
        if CommandLine.arguments.count > 1 {
            let input = CommandLine.arguments[1]
            print("\nProcessing command line input:")
            print("Input: \(input)")

            let workerName = input

            let problemName: String? =
                CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
            let problem: Problem? = problemName.map { Problem.fromName(name: $0) }

            switch workerName {
            case "BasicWorker":
                if #available(macOS 13.0, *) {
                    try await BasicWorker(
                        problem: problem ?? .primus, client: MockExplorationClient(layout: .hexagon)
                    ).run()
                    //                    try await  BasicWorker(problem: .secundus, client: HTTPExplorationClient(), debug: true).run()

                }
            //                try await  GenerateEverythingWorker(problem: .probatio, client: HTTPExplorationClient()).run()
            case "DeBruijnWorker":
                if #available(macOS 13.0, *) {
                    try await DeBruijnWorker(
                        problem: problem ?? .probatio,
                        client: MockExplorationClient(layout: .threeRooms)
                    ).run()
                    //                    try await DeBruijnWorker(problem: .probatio, client: HTTPExplorationClient()).run()
                }

            case "FindEverything":
                if #available(macOS 13.0, *) {
                    //                    try await  FindEverythingWorker(problem: .primus, client: MockExplorationClient(layout: .hexagon), debug: true).run()
                    try await FindEverythingWorker(
                        problem: problem ?? .secundus, client: HTTPExplorationClient(), depth: 5,
                        take: 10
                    ).run()
                }

            case "Ping":
                if #available(macOS 13.0, *) {
                    //                    try await  PingWorker(problem: .primus, client: MockExplorationClient(layout: .hexagon), debug: true).run()
                    try await PingWorker(
                        problem: problem ?? .aleph, client: HTTPExplorationClient(), depth: 5,
                        take: 5
                    ).run()
                }

            case "Score":
                let client = HTTPTaskClient(config: EnvConfig())
                let score = try await client.score()
                print("Score: \(score)")

            case "Grid":
                let problems: [Problem] = Problem.gridProblems()

                for depth in (5...6).reversed() {
                    for take in (1...5).reversed() {
                        for p in problems {

                            let ttake = take * 3
                            print("Running problem \(p.name) with depth \(depth) and take \(ttake)")
                            if #available(macOS 13.0, *) {

                                for retry: Int in 1...5 {
                                    do {
                                        //throw HTTPError(statusCode: 501, message: "Exception happundo")
                                        if let res = try await PingWorker(
                                            problem: p, client: HTTPExplorationClient(),
                                            depth: depth,
                                            take: ttake
                                        ).run() {
                                            print("Found solution with \(res)")
                                            break
                                        }
                                    } catch let error {
                                        print("Exception happened \(error)")
                                    }
                                    print("retrying \(retry)")
                                }

                            }
                        }
                    }
                }

            default:
                print("Unknown worker: \(workerName)")
            }

        }

        print("\n✅ ICFP Worker completed successfully!")
    }
}

@main
struct Main {
    static func main() async {
        do {
            try await CountLines().run()
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
