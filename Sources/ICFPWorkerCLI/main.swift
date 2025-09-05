import ArgumentParser
import Foundation
import ICFPWorkerLib

@main
@available(macOS 10.15, Windows 10.0, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct CountLines: AsyncParsableCommand {
    mutating func run() async throws {
        print("🚀 ICFP Worker CLI")
        print("==================")

        let worker = ICFPWorker()

        // Demo functionality
        let testInput = "Hello ICFP 2025"
        let result = worker.process(testInput)
        print("Processing result: \(result)")

        let sum = worker.calculate(a: 42, b: 13)
        print("Calculation (42 + 13): \(sum)")

        let isValid = worker.validate("test data")
        print("Validation result: \(isValid)")

        // Check command line arguments
        if CommandLine.arguments.count > 1 {
            let input = CommandLine.arguments[1]
            print("\nProcessing command line input:")
            print("Input: \(input)")
            print("Output: \(worker.process(input))")
            print("Valid: \(worker.validate(input))")
        }

        // let client = HTTPTaskClient(url: "http://localhost:8000")
        // let task = try await client.getTask(id: "task001")
        // print("\nFetched Task:")
        // print("ID: \(task.id)")

        print("\n✅ ICFP Worker completed successfully!")
    }
}
