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
            case "SixWorker":
                try await SixWorker(
                    problem: .probatio, client: MockExplorationClient(layout: .threeRooms)
                ).run()
            default:
                print("Unknown worker: \(workerName)")
                print("Available workers:")
                print("  BasicWorker      - Simple test worker")
                print("  VibeWorker       - Advanced worker with 3-room test layout")
                print("  VibeWorkerSingle - Two rooms with single connection")
                print("  VibeWorkerFull   - Two rooms fully connected")
                print("  SmartWorkerSingle - Smart pattern analysis for single connection")
                print("  SmartWorkerFull  - Smart pattern analysis for fully connected")
                print("  SmartThreeRoomsOne - Three rooms with 1 self-loop each")
                print("  SmartThreeRoomsTwo - Three rooms with 2 self-loops each")
                print("  SmartThreeRoomsThree - Three rooms with 3 self-loops each")
                print("  SmartThreeRoomsFour - Three rooms with 4 self-loops each")
                print("  SmartThreeRoomsFive - Three rooms with 5 self-loops each")
                print("  Phase1Test - Phase 1 comprehensive discovery (3 rooms)")
                print("  Phase1Two - Phase 1 with two rooms")
                print("  Phase1Three - Phase 1 with three rooms (2 self-loops)")
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
