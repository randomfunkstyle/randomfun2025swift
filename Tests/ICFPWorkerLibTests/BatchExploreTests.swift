import XCTest
@testable import ICFPWorkerLib

final class BatchExploreTests: XCTestCase {
    
    var matcher: GraphMatcher!
    var testGraph: Graph!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
        testGraph = matcher.createThreeRoomsTestGraph()
    }
    
    // Test 1: Batch explore multiple nodes
    func testBatchExploreMultipleNodes() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: ["0", "1"]),
            (nodeId: testGraph.startingNodeId, paths: ["5"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 3) // 2 paths from first + 1 path from second
        
        // Check first two results are from first exploration
        XCTAssertEqual(results[0].path, "0")
        XCTAssertEqual(results[1].path, "1")
        
        // Check third result is from second exploration
        XCTAssertEqual(results[2].path, "5")
    }
    
    // Test 2: Empty batch returns empty
    func testBatchExploreEmptyReturnsEmpty() {
        let explorations: [(nodeId: Int, paths: [String])] = []
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 0)
    }
    
    // Test 3: Maintains order of explorations
    func testBatchExploreMaintainsOrder() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: ["5"]),
            (nodeId: testGraph.startingNodeId, paths: ["0"]),
            (nodeId: testGraph.startingNodeId, paths: ["1"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].path, "5")
        XCTAssertEqual(results[1].path, "0")
        XCTAssertEqual(results[2].path, "1")
    }
    
    // Test 4: Performance - should be faster than individual
    func testBatchExplorePerformance() {
        // Create many explorations
        var explorations: [(nodeId: Int, paths: [String])] = []
        for _ in 0..<100 {
            explorations.append((nodeId: testGraph.startingNodeId, paths: ["0", "1", "5"]))
        }
        
        let startTime = Date()
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(results.count, 300) // 100 * 3 paths
        XCTAssertLessThan(timeInterval, 0.1, "Should process batch quickly")
    }
    
    // Test 5: Handles errors - partial failures don't break all
    func testBatchExploreHandlesErrors() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: ["0", "1"]),
            (nodeId: 9999, paths: ["5"]), // Non-existent node
            (nodeId: testGraph.startingNodeId, paths: ["2"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        // Should get results from valid nodes only
        XCTAssertEqual(results.count, 3) // 2 from first + 0 from invalid + 1 from third
        XCTAssertEqual(results[0].path, "0")
        XCTAssertEqual(results[1].path, "1")
        XCTAssertEqual(results[2].path, "2")
    }
    
    // Test 6: Single node with multiple paths
    func testBatchExploreSingleNodeMultiplePaths() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: ["0", "1", "2", "3", "4", "5"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 6)
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.path, String(index))
            XCTAssertEqual(result.startNodeId, testGraph.startingNodeId)
        }
    }
    
    // Test 7: Multiple nodes with empty path lists
    func testBatchExploreNodesWithEmptyPaths() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: []),
            (nodeId: testGraph.startingNodeId, paths: ["5"]),
            (nodeId: testGraph.startingNodeId, paths: [])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 1) // Only the middle one has paths
        XCTAssertEqual(results[0].path, "5")
    }
    
    // Test 8: Works with different graphs
    func testBatchExploreWithHexagonGraph() {
        let hexGraph = matcher.createHexagonTestGraph()
        let explorations = [
            (nodeId: hexGraph.startingNodeId, paths: ["0", "1"]),
            (nodeId: hexGraph.startingNodeId, paths: ["2", "3"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: hexGraph)
        
        XCTAssertEqual(results.count, 4)
        for result in results {
            XCTAssertGreaterThanOrEqual(result.observedLabels.count, 1)
        }
    }
    
    // Test 9: Batch with mixed valid and invalid paths
    func testBatchExploreWithMixedPaths() {
        let explorations = [
            (nodeId: testGraph.startingNodeId, paths: ["0", "999", "5"])
        ]
        
        let results = matcher.batchExplore(explorations: explorations, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 3)
        
        // First path should work
        XCTAssertEqual(results[0].path, "0")
        XCTAssertGreaterThan(results[0].observedLabels.count, 0)
        
        // Second path is invalid but still returns a result
        XCTAssertEqual(results[1].path, "999")
        
        // Third path should work
        XCTAssertEqual(results[2].path, "5")
        XCTAssertGreaterThan(results[2].observedLabels.count, 0)
    }
    
    // Test 10: Large batch with diverse explorations
    func testLargeBatchDiverseExplorations() {
        // Build a more complex graph from explorations
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B]),
            ("55", [RoomLabel.A, RoomLabel.B, RoomLabel.C])
        ]
        let complexGraph = matcher.buildGraphFromExploration(explorations: explorations)
        let allNodes = complexGraph.getAllNodes()
        
        // Create batch explorations for all nodes
        var batchExplorations: [(nodeId: Int, paths: [String])] = []
        for node in allNodes {
            batchExplorations.append((nodeId: node.id, paths: ["0", "1"]))
        }
        
        let results = matcher.batchExplore(explorations: batchExplorations, sourceGraph: complexGraph)
        
        // Should have 2 results per node
        XCTAssertEqual(results.count, allNodes.count * 2)
        
        // All results should have valid start node IDs
        for result in results {
            XCTAssertTrue(allNodes.contains { $0.id == result.startNodeId })
        }
    }
}