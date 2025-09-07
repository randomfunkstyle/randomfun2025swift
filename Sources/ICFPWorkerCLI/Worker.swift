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

            switch workerName {
            case "BasicWorker":
                if #available(macOS 13.0, *) {
                    try await BasicWorker(
                        problem: .primus, client: MockExplorationClient(layout: .hexagon)
                    ).run()
                    //                    try await  BasicWorker(problem: .secundus, client: HTTPExplorationClient(), debug: true).run()

                }
            //                try await  GenerateEverythingWorker(problem: .probatio, client: HTTPExplorationClient()).run()
            case "DeBruijnWorker":
                if #available(macOS 13.0, *) {
                    try await DeBruijnWorker(
                        problem: .probatio, client: MockExplorationClient(layout: .threeRooms)
                    ).run()
                    //                    try await DeBruijnWorker(problem: .probatio, client: HTTPExplorationClient()).run()
                }

            case "FindEverything":
                if #available(macOS 13.0, *) {
                    //                    try await  FindEverythingWorker(problem: .primus, client: MockExplorationClient(layout: .hexagon), debug: true).run()
                    try await FindEverythingWorker(
                        problem: .secundus, client: HTTPExplorationClient(), depth: 5, take: 10
                    ).run()
                }
            case "Grid":
                for depth in 1...5 {
                    for take in 5...15 {
                        print("Running with depth \(depth) and take \(take)")
                        try await FindEverythingWorker(
                            problem: .aleph, client: HTTPExplorationClient(), depth: depth,
                            take: take
                        ).run()
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
