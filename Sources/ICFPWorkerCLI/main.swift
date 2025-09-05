import ArgumentParser
import Foundation
import ICFPWorkerLib

struct CountLines: AsyncParsableCommand {
    func run() async throws {
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

         let config = EnvConfig()
         let client = HTTPTaskClient(config: config)
         let selected = try await client.selectProblem(problemName: "probatio")
         print("Select problem result: \(selected.problemName)")

        print("\n✅ ICFP Worker completed successfully!")
    }
}

try await CountLines().run()
