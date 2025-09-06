import XCTest
@testable import ICFPWorkerLib

final class IncrementalGrowthTest: XCTestCase {
    
    func testIncrementalGraphGrowth() {
        let matcher = GraphMatcher()
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        print("\n=== Three Rooms Layout Exploration ===")
        print("Starting with room A (label 0)")
        print()
        
        // We'll explore incrementally and show how the graph grows
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        // Helper function to print graph state
        func printGraphState(_ graph: Graph, iteration: Int) {
            print("--- After exploration #\(iteration) ---")
            let nodes = graph.getAllNodes().sorted { $0.id < $1.id }
            print("Total nodes: \(nodes.count)")
            for node in nodes {
                print("  Node \(node.id): Label=\(node.label?.rawValue ?? "?")", terminator: "")
                
                // Show connections
                var connections: [String] = []
                for door in 0..<6 {
                    if let connection = node.doors[door],
                       let (toNode, _) = connection {
                        connections.append("door\(door)→node\(toNode)")
                    }
                }
                if !connections.isEmpty {
                    print(" | Connections: \(connections.joined(separator: ", "))")
                } else {
                    print(" | No connections")
                }
            }
            print()
        }
        
        // Exploration 1: Just check the starting room
        print("Exploration 1: Path '' (stay in starting room)")
        let path1 = ""
        let labels1 = matcher.explorePath(sourceGraph: sourceGraph, path: path1)
        print("  Observed labels: \(labels1.map { $0.rawValue })")
        allExplorations.append((path1, labels1))
        let graph1 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph1, iteration: 1)
        
        // Exploration 2: Try door 0 (self-loop in room A)
        print("Exploration 2: Path '0' (door 0 from A)")
        let path2 = "0"
        let labels2 = matcher.explorePath(sourceGraph: sourceGraph, path: path2)
        print("  Observed labels: \(labels2.map { $0.rawValue })")
        allExplorations.append((path2, labels2))
        let graph2 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph2, iteration: 2)
        
        // Exploration 3: Try door 5 (goes to room B)
        print("Exploration 3: Path '5' (door 5 from A)")
        let path3 = "5"
        let labels3 = matcher.explorePath(sourceGraph: sourceGraph, path: path3)
        print("  Observed labels: \(labels3.map { $0.rawValue })")
        allExplorations.append((path3, labels3))
        let graph3 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph3, iteration: 3)
        
        // Exploration 4: Try door 1 (self-loop in room A)
        print("Exploration 4: Path '1' (door 1 from A)")
        let path4 = "1"
        let labels4 = matcher.explorePath(sourceGraph: sourceGraph, path: path4)
        print("  Observed labels: \(labels4.map { $0.rawValue })")
        allExplorations.append((path4, labels4))
        let graph4 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph4, iteration: 4)
        
        // Exploration 5: Go to B then through door 5 (goes to room C)
        print("Exploration 5: Path '55' (door 5 from A, then door 5 from B)")
        let path5 = "55"
        let labels5 = matcher.explorePath(sourceGraph: sourceGraph, path: path5)
        print("  Observed labels: \(labels5.map { $0.rawValue })")
        allExplorations.append((path5, labels5))
        let graph5 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph5, iteration: 5)
        
        // Exploration 6: Try a longer path
        print("Exploration 6: Path '555' (following door 5 three times)")
        let path6 = "555"
        let labels6 = matcher.explorePath(sourceGraph: sourceGraph, path: path6)
        print("  Observed labels: \(labels6.map { $0.rawValue })")
        allExplorations.append((path6, labels6))
        let graph6 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph6, iteration: 6)
        
        // Exploration 7: Try door 50 (from A to B, then door 0 from B)
        print("Exploration 7: Path '50' (door 5 to B, then door 0 from B)")
        let path7 = "50"
        let labels7 = matcher.explorePath(sourceGraph: sourceGraph, path: path7)
        print("  Observed labels: \(labels7.map { $0.rawValue })")
        allExplorations.append((path7, labels7))
        let graph7 = matcher.buildGraphFromExploration(explorations: allExplorations)
        printGraphState(graph7, iteration: 7)
        
        print("=== Summary ===")
        print("Original three rooms graph has rooms: A(0), B(1), C(2)")
        print("- Room A: doors 0-4 are self-loops, door 5 goes to B")
        print("- Room B: doors 1-4 are self-loops, door 0 goes back to A, door 5 goes to C")
        print("- Room C: all doors are self-loops except door 0 goes back to B")
        print()
        print("Final reconstructed graph has \(graph7.getAllNodes().count) nodes")
        print("Note: Duplicates are expected since we don't merge rooms")
        
        // Basic assertions to ensure test passes
        XCTAssertEqual(graph1.getAllNodes().count, 1)  // Just starting room
        XCTAssertGreaterThanOrEqual(graph7.getAllNodes().count, 3)  // At least 3 rooms discovered
    }
}