import XCTest
@testable import ICFPWorkerLib

final class DirectExplorationTest: XCTestCase {
    
    func testDirectHexagonExploration() async {
        let mockClient = MockExplorationClient(layout: .hexagon)
        
        print("=== DIRECT EXPLORATION TEST ===")
        
        // Test direct exploration of each single door from starting room (room 0)
        for door in 0..<6 {
            let path = String(door)
            
            do {
                let response = try await mockClient.explore(plans: [path])
                if let labels = response.results.first {
                    let roomLabels = labels.map { RoomLabel(fromInt: $0)?.rawValue ?? "?" }.joined(separator: " -> ")
                    print("Path '\(path)': \(roomLabels)")
                }
            } catch {
                print("Path '\(path)': ERROR - \(error)")
            }
        }
        
        print("\nExpected starting room signature: A:BCDABA")
        print("Let's verify by mapping observed labels back to expected pattern...")
        
        // Test some two-step paths to verify connections
        let testPaths = ["01", "12", "23", "34", "45", "50"]
        for path in testPaths {
            do {
                let response = try await mockClient.explore(plans: [path])
                if let labels = response.results.first {
                    let roomLabels = labels.map { RoomLabel(fromInt: $0)?.rawValue ?? "?" }.joined(separator: " -> ")
                    print("Path '\(path)': \(roomLabels)")
                }
            } catch {
                print("Path '\(path)': ERROR - \(error)")
            }
        }
    }
}