import XCTest
@testable import ICFPWorkerLib

final class ExplorePathsFromNodeTests: XCTestCase {
    
    var matcher: GraphMatcher!
    var testGraph: Graph!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
        testGraph = matcher.createThreeRoomsTestGraph()
    }
    
    // Test 1: Explore single path from node
    func testExploreSinglePathFromNode() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = ["5"]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].startNodeId, testGraph.startingNodeId)
        XCTAssertEqual(results[0].path, "5")
        XCTAssertEqual(results[0].observedLabels.count, 2) // Starting room + 1 step
        XCTAssertEqual(results[0].observedLabels[0], .A) // Starting room
        XCTAssertEqual(results[0].observedLabels[1], .B) // After door 5
    }
    
    // Test 2: Explore multiple paths from node
    func testExploreMultiplePathsFromNode() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = ["0", "1", "5"]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 3)
        
        // Check each result has correct path
        XCTAssertEqual(results[0].path, "0")
        XCTAssertEqual(results[1].path, "1")
        XCTAssertEqual(results[2].path, "5")
        
        // All should start from same node
        for result in results {
            XCTAssertEqual(result.startNodeId, testGraph.startingNodeId)
        }
    }
    
    // Test 3: Explore empty path returns start label
    func testExploreEmptyPathReturnsStartLabel() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = [""]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].path, "")
        XCTAssertEqual(results[0].observedLabels.count, 1)
        XCTAssertEqual(results[0].observedLabels[0], .A)
    }
    
    // Test 4: Explore invalid path returns partial results
    func testExploreInvalidPathReturnsPartialResults() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = ["999"] // Invalid door number
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].path, "999")
        XCTAssertEqual(results[0].observedLabels.count, 1) // Only starting room
    }
    
    // Test 5: Explore from non-existent node handles gracefully
    func testExploreFromNonExistentNode() {
        // Create a graph and get a valid node
        let graph = Graph(startingLabel: .A)
        let nodeId = graph.addNode(label: .B)
        
        // Try to explore from a non-existent node (not the starting node)
        let fakeNode = Node(id: 9999, label: .C)
        let paths = ["0", "1"]
        
        let results = matcher.explorePathsFromNode(node: fakeNode, paths: paths, sourceGraph: graph)
        
        // In reality, we can only explore from the starting node
        // Non-starting nodes should return empty results
        XCTAssertEqual(results.count, 0)
        
        // Test that starting node works correctly
        let startNode = graph.getNode(graph.startingNodeId)!
        let startResults = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: graph)
        XCTAssertEqual(startResults.count, 2)
    }
    
    // Test 6: Performance - should be O(path.length)
    func testExplorePerformance() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let longPath = String(repeating: "5", count: 100)
        let paths = [longPath]
        
        let startTime = Date()
        _ = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.01, "Should explore long paths quickly")
    }
    
    // Test 7: Explore multiple depths
    func testExploreMultipleDepths() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = ["5", "55", "555"]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 3)
        
        // Check depth 1
        XCTAssertEqual(results[0].observedLabels.count, 2)
        XCTAssertEqual(results[0].observedLabels[1], .B)
        
        // Check depth 2
        XCTAssertEqual(results[1].observedLabels.count, 3)
        XCTAssertEqual(results[1].observedLabels[2], .C)
        
        // Check depth 3
        XCTAssertEqual(results[2].observedLabels.count, 4)
        XCTAssertEqual(results[2].observedLabels[3], .C) // Should stay in C
    }
    
    // Test 8: Empty paths array returns empty results
    func testEmptyPathsReturnsEmpty() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths: [String] = []
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 0)
    }
    
    // Test 9: Maintains path order
    func testMaintainsPathOrder() {
        let startNode = testGraph.getNode(testGraph.startingNodeId)!
        let paths = ["2", "0", "5", "1", "3", "4"]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: testGraph)
        
        XCTAssertEqual(results.count, 6)
        for (index, path) in paths.enumerated() {
            XCTAssertEqual(results[index].path, path)
        }
    }
    
    // Test 10: Works with hexagon graph
    func testWorksWithHexagonGraph() {
        let hexGraph = matcher.createHexagonTestGraph()
        let startNode = hexGraph.getNode(hexGraph.startingNodeId)!
        let paths = ["0", "1", "2", "3", "4", "5"]
        
        let results = matcher.explorePathsFromNode(node: startNode, paths: paths, sourceGraph: hexGraph)
        
        XCTAssertEqual(results.count, 6)
        
        // Each exploration should have results
        for result in results {
            XCTAssertGreaterThanOrEqual(result.observedLabels.count, 1)
            XCTAssertEqual(result.startNodeId, hexGraph.startingNodeId)
        }
    }
}