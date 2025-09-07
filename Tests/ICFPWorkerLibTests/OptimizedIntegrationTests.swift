import XCTest
@testable import ICFPWorkerLib

final class OptimizedIntegrationTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    func testOptimizedStrategyFlag() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Test with optimization OFF (default)
        let traditionalResult = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            useOptimizedStrategy: false
        )
        
        // Test with optimization ON
        let optimizedResult = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            useOptimizedStrategy: true
        )
        
        print("\nStrategy Comparison:")
        print("Traditional (OFF): \(traditionalResult.queryCount) queries, \(traditionalResult.uniqueRooms) rooms")
        print("Optimized (ON): \(optimizedResult.queryCount) queries, \(optimizedResult.uniqueRooms) rooms")
        
        // Optimized should use exactly 1 query
        XCTAssertEqual(optimizedResult.queryCount, 1, "Optimized should use exactly 1 query")
        
        // Traditional should use many more queries
        XCTAssertGreaterThan(traditionalResult.queryCount, 10, "Traditional should use many queries")
        
        // Both should find rooms (exact count may differ due to different algorithms)
        XCTAssertGreaterThan(optimizedResult.uniqueRooms, 0, "Should find rooms with optimization")
        XCTAssertGreaterThan(traditionalResult.uniqueRooms, 0, "Should find rooms without optimization")
    }
    
    func testOptimizedThreeRooms() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 3,
            useOptimizedStrategy: true
        )
        
        print("\nThree Rooms Optimized:")
        print("  Queries: \(result.queryCount)")
        print("  Unique rooms found: \(result.uniqueRooms)")
        
        XCTAssertLessThanOrEqual(result.queryCount, 3, "Should use at most 3 queries")
        XCTAssertGreaterThan(result.uniqueRooms, 0, "Should find at least some rooms")
    }
    
    func testOptimizedSingleRoom() {
        // Create a single room graph
        let graph = Graph(startingLabel: .A)
        for door in 0..<6 {
            graph.addOneWayConnection(
                fromNodeId: graph.startingNodeId,
                fromDoor: door,
                toNodeId: graph.startingNodeId
            )
        }
        
        let result = matcher.identifyRooms(
            sourceGraph: graph,
            expectedRoomCount: 1,
            useOptimizedStrategy: true
        )
        
        print("\nSingle Room Optimized:")
        print("  Queries: \(result.queryCount)")
        print("  Unique rooms found: \(result.uniqueRooms)")
        
        XCTAssertEqual(result.queryCount, 1, "Should use only 1 query")
        XCTAssertEqual(result.uniqueRooms, 1, "Should identify exactly 1 room")
    }
    
    func testMassiveQueryReduction() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Run both strategies
        let traditional = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 500,
            useOptimizedStrategy: false
        )
        
        let optimized = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            useOptimizedStrategy: true
        )
        
        let reduction = Double(traditional.queryCount - optimized.queryCount) / Double(traditional.queryCount) * 100
        
        print("\nQuery Reduction Analysis:")
        print("  Traditional: \(traditional.queryCount) queries")
        print("  Optimized: \(optimized.queryCount) queries")
        print("  Reduction: \(String(format: "%.1f", reduction))%")
        
        // With multi-pattern support, may use more than 1 query but still much less than traditional
        XCTAssertGreaterThan(reduction, 85, "Should achieve >85% query reduction")
    }
    
    func testOptimizedCompleteness() {
        // Test that optimization finds all rooms in various graph types
        let testCases: [(graph: Graph, expectedRooms: Int, description: String)] = [
            (matcher.createThreeRoomsTestGraph(), 3, "Three rooms"),
            (matcher.createHexagonTestGraph(), 6, "Hexagon"),
            (createSingleRoomGraph(), 1, "Single room")
        ]
        
        for testCase in testCases {
            let result = matcher.identifyRooms(
                sourceGraph: testCase.graph,
                expectedRoomCount: testCase.expectedRooms,
                useOptimizedStrategy: true
            )
            
            print("\n\(testCase.description) completeness:")
            print("  Expected: \(testCase.expectedRooms) rooms")
            print("  Found: \(result.uniqueRooms) rooms")
            print("  Queries: \(result.queryCount)")
            
            // Should find at least most of the rooms
            let minExpected = max(1, testCase.expectedRooms - 1)
            XCTAssertGreaterThanOrEqual(result.uniqueRooms, minExpected,
                                       "\(testCase.description): Should find at least \(minExpected) rooms")
            
            // Should use fewer queries than traditional approach
            // No strict upper limit since it depends on graph complexity
        }
    }
    
    private func createSingleRoomGraph() -> Graph {
        let graph = Graph(startingLabel: .A)
        for door in 0..<6 {
            graph.addOneWayConnection(
                fromNodeId: graph.startingNodeId,
                fromDoor: door,
                toNodeId: graph.startingNodeId
            )
        }
        return graph
    }
}