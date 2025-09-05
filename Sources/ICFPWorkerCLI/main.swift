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
                try await  BasicWorker(problem: .probatio).run()
            default:
                print("Unknown worker: \(workerName)")
            }
            
        }
        
        
        print("\n✅ ICFP Worker completed successfully!")
    }
}

if #available(macOS 12.0, *) {
    do {
        try await CountLines().run()
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}
