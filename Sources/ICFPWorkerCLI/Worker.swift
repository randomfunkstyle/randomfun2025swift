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
                try await BasicWorker(
                    problem: .probatio, client: MockExplorationClient(layout: .threeRooms)
                ).run()
            case "VibeWorker":
                print("🚀 Starting VibeWorker with sophisticated exploration algorithms...")
                try await VibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRooms
                ).run()
            default:
                print("Unknown worker: \(workerName)")
                print("Available workers:")
                print("  BasicWorker     - Simple test worker")
                print("  VibeWorker      - Advanced worker with 3-room test layout")
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
