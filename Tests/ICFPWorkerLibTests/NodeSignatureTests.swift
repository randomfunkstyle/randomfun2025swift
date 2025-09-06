import XCTest
@testable import ICFPWorkerLib

final class NodeSignatureTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Compute signature for fully explored node
    func testComputesSignatureForFullyExploredNode() {
        // Create a simple test graph
        let graph = Graph(startingLabel: .A)
        let node2 = graph.addNode(label: .B)
        let node3 = graph.addNode(label: .C)
        
        // Connect nodes
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: node2, toDoor: 1)
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 1, toNodeId: node3, toDoor: 2)
        
        // Get starting node
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Compute signature for paths
        let paths = ["", "0", "1"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Verify results
        XCTAssertEqual(signature.nodeId, graph.startingNodeId)
        XCTAssertEqual(signature.pathLabels[""], .A)
        XCTAssertEqual(signature.pathLabels["0"], .B)
        XCTAssertEqual(signature.pathLabels["1"], .C)
    }
    
    // Test 2: Compute partial signature when some paths can't be followed
    func testComputesPartialSignature() {
        // Create a graph with limited connections
        let graph = Graph(startingLabel: .A)
        let node2 = graph.addNode(label: .B)
        
        // Only connect door 0
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: node2, toDoor: 1)
        
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Try to explore paths including non-existent connections
        let paths = ["0", "1", "2"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Should only have successful path
        XCTAssertEqual(signature.pathLabels.count, 1)
        XCTAssertEqual(signature.pathLabels["0"], .B)
    }
    
    // Test 3: Empty paths returns empty signature
    func testEmptyPathsEmptySignature() {
        let graph = Graph(startingLabel: .A)
        let startNode = graph.getNode(graph.startingNodeId)!
        
        let paths: [String] = []
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        XCTAssertEqual(signature.pathLabels.count, 0)
    }
    
    // Test 4: Signature consistency - same input produces same output
    func testSignatureConsistency() {
        let graph = matcher.createThreeRoomsTestGraph()
        let startNode = graph.getNode(graph.startingNodeId)!
        
        let paths = ["0", "1", "5", "55"]
        
        // Compute signature twice
        let signature1 = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        let signature2 = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Should be identical
        XCTAssertEqual(signature1.nodeId, signature2.nodeId)
        XCTAssertEqual(signature1.pathLabels, signature2.pathLabels)
    }
    
    // Test 5: Handles non-existent paths gracefully
    func testHandlesNonExistentPaths() {
        let graph = Graph(startingLabel: .A)
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Try paths with no connections
        let paths = ["0", "1", "2", "3", "4", "5"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Should have no successful paths (except empty if included)
        XCTAssertEqual(signature.pathLabels.count, 0)
    }
    
    // Test 6: Signature completeness correctly identifies when all paths explored
    func testSignatureCompleteness() {
        let graph = matcher.createThreeRoomsTestGraph()
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Test with paths that all exist
        let existingPaths = ["", "5"]
        let signature1 = matcher.computeNodeSignature(node: startNode, paths: existingPaths, graph: graph)
        XCTAssertEqual(signature1.pathLabels.count, 2) // Both paths should succeed
        
        // Test with mix of existing and non-existing
        let mixedPaths = ["5", "99"] // "99" is invalid
        let signature2 = matcher.computeNodeSignature(node: startNode, paths: mixedPaths, graph: graph)
        XCTAssertEqual(signature2.pathLabels.count, 1) // Only "5" should succeed
    }
    
    // Test 7: Multi-step paths work correctly
    func testMultiStepPaths() {
        let graph = matcher.createThreeRoomsTestGraph()
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Test longer paths
        let paths = ["5", "55", "555", "5555"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Based on three rooms structure:
        // From A: door 5 -> B
        // From B: door 5 -> C
        // From C: door 5 -> C (self-loop)
        XCTAssertEqual(signature.pathLabels["5"], .B)
        XCTAssertEqual(signature.pathLabels["55"], .C)
        XCTAssertEqual(signature.pathLabels["555"], .C)
        XCTAssertEqual(signature.pathLabels["5555"], .C)
    }
    
    // Test 8: Empty path returns node's own label
    func testEmptyPathReturnsOwnLabel() {
        let graph = Graph(startingLabel: .D)
        let startNode = graph.getNode(graph.startingNodeId)!
        
        let paths = [""]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        XCTAssertEqual(signature.pathLabels[""], .D)
    }
    
    // Test 9: Invalid door numbers in path are handled
    func testInvalidDoorNumbers() {
        let graph = Graph(startingLabel: .A)
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Paths with invalid door numbers
        let paths = ["6", "7", "a", "-1"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // None should succeed
        XCTAssertEqual(signature.pathLabels.count, 0)
    }
    
    // Test 10: Works with complex graph structure
    func testComplexGraphStructure() {
        let graph = matcher.createHexagonTestGraph()
        let startNode = graph.getNode(graph.startingNodeId)!
        
        // Explore various paths
        let paths = ["0", "1", "2", "3", "4", "5", "01", "23", "45"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        // Should have results for all valid paths
        XCTAssertGreaterThan(signature.pathLabels.count, 0)
    }
}