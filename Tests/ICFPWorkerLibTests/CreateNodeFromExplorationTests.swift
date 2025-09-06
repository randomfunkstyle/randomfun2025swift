import XCTest
@testable import ICFPWorkerLib

final class CreateNodeFromExplorationTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Creates new node for unexplored path
    func testCreatesNewNodeForUnexploredPath() {
        let graph = Graph(startingLabel: .A)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "0",
            observedLabels: [.A, .B]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should have 2 nodes now (starting + new)
        XCTAssertEqual(newGraph.getAllNodes().count, 2)
        
        // Starting node should have connection through door 0
        let startNode = newGraph.getNode(newGraph.startingNodeId)!
        XCTAssertNotNil(startNode.doors[0])
        
        // Verify the connection leads to a node with label B
        if let connection = startNode.doors[0],
           let (targetNodeId, _) = connection,
           let targetNode = newGraph.getNode(targetNodeId) {
            XCTAssertEqual(targetNode.label, .B, "Door 0 should lead to node with label B")
        } else {
            XCTFail("Door 0 should have a valid connection")
        }
    }
    
    // Test 2: Reuses existing node for explored path
    func testReusesExistingNodeForExploredPath() {
        // Create graph with existing connection
        let graph = Graph(startingLabel: .A)
        let nodeB = graph.addNode(label: .B)
        graph.addOneWayConnection(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: nodeB)
        
        // Try to explore same path again
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "0",
            observedLabels: [.A, .B]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should still have only 2 nodes
        XCTAssertEqual(newGraph.getAllNodes().count, 2)
    }
    
    // Test 3: Updates node labels
    func testUpdatesNodeLabels() {
        let graph = Graph(startingLabel: nil)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "",
            observedLabels: [.A]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        let startNode = newGraph.getNode(newGraph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
    }
    
    // Test 4: Preserves existing connections
    func testPreservesExistingConnections() {
        // Create graph with some connections
        let graph = Graph(startingLabel: .A)
        let nodeB = graph.addNode(label: .B)
        graph.addOneWayConnection(fromNodeId: graph.startingNodeId, fromDoor: 1, toNodeId: nodeB)
        
        // Add new exploration through different door
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "2",
            observedLabels: [.A, .C]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should have 3 nodes now
        XCTAssertEqual(newGraph.getAllNodes().count, 3)
        
        // Original connection should still exist
        let startNode = newGraph.getNode(newGraph.startingNodeId)!
        XCTAssertNotNil(startNode.doors[1])
        XCTAssertNotNil(startNode.doors[2])
    }
    
    // Test 5: Handles empty path result
    func testHandlesEmptyPathResult() {
        let graph = Graph(startingLabel: .A)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "",
            observedLabels: [.A]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should still have just 1 node
        XCTAssertEqual(newGraph.getAllNodes().count, 1)
    }
    
    // Test 6: Immutability - original graph unchanged
    func testImmutability() {
        let graph = Graph(startingLabel: .A)
        let originalNodeCount = graph.getAllNodes().count
        
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "012",
            observedLabels: [.A, .B, .C, .D]
        )
        
        _ = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Original graph should be unchanged
        XCTAssertEqual(graph.getAllNodes().count, originalNodeCount)
    }
    
    // Test 7: Handles multi-step paths
    func testHandlesMultiStepPaths() {
        let graph = Graph(startingLabel: .A)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "012",
            observedLabels: [.A, .B, .C, .D]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should have 4 nodes (start + 3 new)
        XCTAssertEqual(newGraph.getAllNodes().count, 4)
        
        // Verify the path structure: A -0-> B -1-> C -2-> D
        let startNode = newGraph.getNode(newGraph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
        
        // Check door 0 leads to B
        if let door0Connection = startNode.doors[0],
           let (nodeBId, _) = door0Connection,
           let nodeB = newGraph.getNode(nodeBId) {
            XCTAssertEqual(nodeB.label, .B)
            
            // Check door 1 from B leads to C
            if let door1Connection = nodeB.doors[1],
               let (nodeCId, _) = door1Connection,
               let nodeC = newGraph.getNode(nodeCId) {
                XCTAssertEqual(nodeC.label, .C)
                
                // Check door 2 from C leads to D
                if let door2Connection = nodeC.doors[2],
                   let (nodeDId, _) = door2Connection,
                   let nodeD = newGraph.getNode(nodeDId) {
                    XCTAssertEqual(nodeD.label, .D)
                } else {
                    XCTFail("Node C should have door 2 leading to D")
                }
            } else {
                XCTFail("Node B should have door 1 leading to C")
            }
        } else {
            XCTFail("Start node should have door 0 leading to B")
        }
    }
    
    // Test 8: Handles invalid paths gracefully
    func testHandlesInvalidPaths() {
        let graph = Graph(startingLabel: .A)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "9x@",  // Invalid characters
            observedLabels: [.A]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should handle gracefully, keeping original structure
        XCTAssertEqual(newGraph.getAllNodes().count, 1)
    }
    
    // Test 9: Works with complex existing graph
    func testWorksWithComplexGraph() {
        // Start with a more complex graph
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B])
        ]
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        let initialNodeCount = graph.getAllNodes().count
        
        // Add new exploration
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "55",
            observedLabels: [.A, .B, .C]
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should have added at least one new node
        XCTAssertGreaterThan(newGraph.getAllNodes().count, initialNodeCount)
    }
    
    // Test 10: Handles paths with insufficient labels
    func testHandlesInsufficientLabels() {
        let graph = Graph(startingLabel: .A)
        let pathResult = PathResult(
            startNodeId: graph.startingNodeId,
            path: "012",
            observedLabels: [.A, .B]  // Not enough labels for the path
        )
        
        let newGraph = matcher.createNodeFromExploration(pathResult: pathResult, currentGraph: graph)
        
        // Should handle gracefully by not processing the path (due to label count mismatch)
        XCTAssertEqual(newGraph.getAllNodes().count, 1)  // Just the starting node
    }
}