import XCTest
@testable import ICFPWorkerLib

final class MergeExplorationResultsTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Merges multiple results correctly
    func testMergesMultipleResults() {
        let graph = Graph(startingLabel: .A)
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "1", observedLabels: [.A, .C]),
            PathResult(startNodeId: graph.startingNodeId, path: "2", observedLabels: [.A, .D])
        ]
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should have 4 nodes (start + 3 new)
        XCTAssertEqual(newGraph.getAllNodes().count, 4)
        
        // Verify the structure - starting node should have 3 connections
        let startNode = newGraph.getNode(newGraph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
        
        // Check door 0 leads to B
        if let door0 = startNode.doors[0],
           let (node0Id, _) = door0,
           let node0 = newGraph.getNode(node0Id) {
            XCTAssertEqual(node0.label, .B, "Door 0 should lead to label B")
        } else {
            XCTFail("Door 0 should exist")
        }
        
        // Check door 1 leads to C
        if let door1 = startNode.doors[1],
           let (node1Id, _) = door1,
           let node1 = newGraph.getNode(node1Id) {
            XCTAssertEqual(node1.label, .C, "Door 1 should lead to label C")
        } else {
            XCTFail("Door 1 should exist")
        }
        
        // Check door 2 leads to D
        if let door2 = startNode.doors[2],
           let (node2Id, _) = door2,
           let node2 = newGraph.getNode(node2Id) {
            XCTAssertEqual(node2.label, .D, "Door 2 should lead to label D")
        } else {
            XCTFail("Door 2 should exist")
        }
    }
    
    // Test 2: Handles duplicate paths
    func testHandlesDuplicatePaths() {
        let graph = Graph(startingLabel: .A)
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B])
        ]
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should only have 2 nodes despite duplicates
        XCTAssertEqual(newGraph.getAllNodes().count, 2)
    }
    
    // Test 3: Preserves node identities
    func testPreservesNodeIdentities() {
        let graph = Graph(startingLabel: .A)
        let nodeB = graph.addNode(label: .B)
        graph.addOneWayConnection(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: nodeB)
        
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "1", observedLabels: [.A, .C])
        ]
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should have 3 nodes (original 2 + 1 new)
        XCTAssertEqual(newGraph.getAllNodes().count, 3)
    }
    
    // Test 4: Merge empty results returns original
    func testMergeEmptyResultsReturnsOriginal() {
        let graph = Graph(startingLabel: .A)
        graph.addNode(label: .B)
        
        let results: [PathResult] = []
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should have same number of nodes
        XCTAssertEqual(newGraph.getAllNodes().count, graph.getAllNodes().count)
    }
    
    // Test 5: Performance - should be O(n)
    func testMergePerformance() {
        let graph = Graph(startingLabel: .A)
        
        // Create many results
        var results: [PathResult] = []
        for i in 0..<100 {
            let path = String(i % 6)
            results.append(PathResult(
                startNodeId: graph.startingNodeId,
                path: path,
                observedLabels: [.A, RoomLabel(fromInt: i % 4)!]
            ))
        }
        
        let startTime = Date()
        _ = matcher.mergeExplorationResults(results: results, graph: graph)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.1, "Should merge quickly")
    }
    
    // Test 6: Order independent - same results regardless of order
    func testMergeOrderIndependent() {
        let graph = Graph(startingLabel: .A)
        
        let results1 = [
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "1", observedLabels: [.A, .C])
        ]
        
        let results2 = [
            PathResult(startNodeId: graph.startingNodeId, path: "1", observedLabels: [.A, .C]),
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B])
        ]
        
        let graph1 = matcher.mergeExplorationResults(results: results1, graph: graph)
        let graph2 = matcher.mergeExplorationResults(results: results2, graph: graph)
        
        // Should have same structure
        XCTAssertEqual(graph1.getAllNodes().count, graph2.getAllNodes().count)
    }
    
    // Test 7: Handles mixed valid and invalid results
    func testHandlesMixedValidInvalid() {
        let graph = Graph(startingLabel: .A)
        
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "xyz", observedLabels: [.A]), // Invalid
            PathResult(startNodeId: graph.startingNodeId, path: "1", observedLabels: [.A, .C])
        ]
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should have 3 nodes (start + 2 valid)
        XCTAssertEqual(newGraph.getAllNodes().count, 3)
    }
    
    // Test 8: Works with complex paths
    func testWorksWithComplexPaths() {
        let graph = Graph(startingLabel: .A)
        
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "01", observedLabels: [.A, .B, .C]),
            PathResult(startNodeId: graph.startingNodeId, path: "02", observedLabels: [.A, .B, .D]),
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .B])
        ]
        
        let newGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Should have at least 4 nodes
        XCTAssertGreaterThanOrEqual(newGraph.getAllNodes().count, 4)
    }
    
    // Test 9: Immutability - original graph unchanged
    func testImmutabilityOfOriginalGraph() {
        let graph = Graph(startingLabel: .A)
        let originalCount = graph.getAllNodes().count
        
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "012", observedLabels: [.A, .B, .C, .D])
        ]
        
        _ = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Original should be unchanged
        XCTAssertEqual(graph.getAllNodes().count, originalCount)
    }
    
    // Test 10: Integration with real exploration
    func testIntegrationWithRealExploration() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        let startNode = sourceGraph.getNode(sourceGraph.startingNodeId)!
        
        // Perform actual exploration
        let paths = ["0", "5", "55"]
        let pathResults = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: sourceGraph)
        
        // Start with empty graph
        let graph = Graph(startingLabel: .A)
        
        // Merge exploration results
        let finalGraph = matcher.mergeExplorationResults(results: pathResults, graph: graph)
        
        // Should have discovered multiple nodes
        XCTAssertGreaterThan(finalGraph.getAllNodes().count, 1)
    }
}