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
            case "VibeWorkerSingle":
                print("🚀 Starting VibeWorker with two rooms, single connection...")
                try await VibeWorker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsSingleConnection
                ).run()
            case "VibeWorkerFull":
                print("🚀 Starting VibeWorker with two rooms, fully connected...")
                try await VibeWorker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsFullyConnected
                ).run()
            case "SmartWorkerSingle":
                print("🧠 Starting SmartVibeWorker with pattern-first analysis...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsSingleConnection
                ).run()
            case "SmartWorkerFull":
                print("🧠 Starting SmartVibeWorker with fully connected rooms...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsFullyConnected
                ).run()
            case "SmartThreeRoomsOne":
                print("🧠 Starting SmartVibeWorker with 3 rooms (1 self-loop each)...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsOneSelfLoop
                ).run()
            case "SmartThreeRoomsTwo":
                print("🧠 Starting SmartVibeWorker with 3 rooms (2 self-loops each)...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsTwoSelfLoops
                ).run()
            case "SmartThreeRoomsThree":
                print("🧠 Starting SmartVibeWorker with 3 rooms (3 self-loops each)...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsThreeSelfLoops
                ).run()
            case "SmartThreeRoomsFour":
                print("🧠 Starting SmartVibeWorker with 3 rooms (4 self-loops each)...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsFourSelfLoops
                ).run()
            case "SmartThreeRoomsFive":
                print("🧠 Starting SmartVibeWorker with 3 rooms (5 self-loops each)...")
                try await SmartVibeWorker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsFiveSelfLoops
                ).run()
            case "Phase1Test":
                print("🔬 Testing Phase 1 comprehensive discovery...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRooms
                ).run()
            case "Phase1Two":
                print("🔬 Testing Phase 1 with two rooms...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsSingleConnection
                ).run()
            case "Phase1Three":
                print("🔬 Testing Phase 1 with three rooms (2 self-loops)...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsTwoSelfLoops
                ).run()
            case "Phase1TwoFull":
                print("🔬 Testing Phase 1 with two rooms fully connected...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .twoRoomsFullyConnected
                ).run()
            case "Phase1Three1":
                print("🔬 Testing Phase 1 with three rooms (1 self-loop)...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsOneSelfLoop
                ).run()
            case "Phase1Three3":
                print("🔬 Testing Phase 1 with three rooms (3 self-loops)...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsThreeSelfLoops
                ).run()
            case "Phase1Three4":
                print("🔬 Testing Phase 1 with three rooms (4 self-loops)...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsFourSelfLoops
                ).run()
            case "Phase1Three5":
                print("🔬 Testing Phase 1 with three rooms (5 self-loops)...")
                try await Phase1Worker.forTesting(
                    problem: .probatio,
                    layout: .threeRoomsFiveSelfLoops
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
