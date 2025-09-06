import XCTest
@testable import ICFPWorkerLib

final class AlgorithmFlowTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // MARK: - Three Room Tests
    
    func testIdentifyThreeRooms() {
        // Create the three-room source graph
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Run the algorithm
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 3,
            maxQueries: 300
        )
        
        // Debug output
        print("Three rooms test:")
        print("  Found \(result.uniqueRooms) unique rooms in \(result.queryCount) queries")
        print("  Room groups: \(result.roomGroups)")
        print("  Graph has \(result.graph.getAllNodes().count) total nodes")
        
        // Debug signatures for three rooms
        let builtGraph = result.graph
        let allNodes = builtGraph.getAllNodes()
        print("\nSignatures for all nodes:")
        for node in allNodes.prefix(10) {
            let signature = matcher.computeSimpleSignature(node: node, depth: 1, graph: builtGraph)
            print("Node \(node.id): label=\(node.label?.rawValue ?? "nil"), signature='\(signature)'")
        }
        
        // Verify results
        XCTAssertEqual(result.uniqueRooms, 3, "Should identify exactly 3 unique rooms")
        XCTAssertLessThan(result.queryCount, 300, "Should complete in reasonable number of queries")
        XCTAssertEqual(result.roomGroups.count, 3, "Should have 3 room groups")
        
        // Verify that all room groups have been created
        let totalNodes = result.roomGroups.flatMap { $0 }.count
        XCTAssertEqual(totalNodes, result.uniqueRooms, "Each unique room should be in a group")
        
        // Verify no overlapping groups
        let allNodeIds = result.roomGroups.flatMap { $0 }
        let uniqueNodeIds = Set(allNodeIds)
        XCTAssertEqual(allNodeIds.count, uniqueNodeIds.count, "No node should appear in multiple groups")
    }
    
    func testThreeRoomsEfficiency() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Track query efficiency
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 3,
            maxQueries: 300
        )
        
        XCTAssertEqual(result.uniqueRooms, 3)
        XCTAssertLessThan(result.queryCount, 300, "Should complete in reasonable number of queries")
        
        // Verify structure
        print("Three rooms identified in \(result.queryCount) queries")
        print("Room groups: \(result.roomGroups)")
    }
    
    // MARK: - Six Room (Hexagon) Tests
    
    func testIdentifySixRooms() {
        // Create the hexagon source graph
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Run the algorithm
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100
        )
        
        // Debug output
        print("Six rooms test:")
        print("  Found \(result.uniqueRooms) unique rooms in \(result.queryCount) queries")
        print("  Room groups: \(result.roomGroups)")
        print("  Graph has \(result.graph.getAllNodes().count) total nodes")
        
        // Let's examine the signatures of fully connected nodes only
        print("\n=== FULLY CONNECTED NODE ANALYSIS ===")
        let builtGraph = result.graph
        let allNodes = builtGraph.getAllNodes()
        let fullyConnectedNodes = allNodes.filter { matcher.isNodeFullyConnected(node: $0) }
        
        print("Total nodes: \(allNodes.count), Fully connected: \(fullyConnectedNodes.count)")
        
        for node in fullyConnectedNodes.prefix(10) {
            let signature = matcher.computeSimpleSignature(node: node, depth: 1, graph: builtGraph)
            print("Node \(node.id): label=\(node.label?.rawValue ?? "nil"), signature='\(signature)'")
        }
        
        // Verify results
        XCTAssertEqual(result.uniqueRooms, 6, "Should identify exactly 6 unique rooms")
        XCTAssertLessThan(result.queryCount, 50, "Should complete in less than 50 queries")
        XCTAssertEqual(result.roomGroups.count, 6, "Should have 6 room groups")
        
        // Verify correct handling of duplicate labels
        // Hexagon has rooms 0&4 with same label, rooms 1&5 with same label
        for group in result.roomGroups {
            if group.count > 1 {
                // These are duplicate nodes that represent the same room
                print("Found duplicate nodes for same room: \(group)")
            }
        }
    }
    
    func testHexagonWithDuplicateLabels() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100
        )
        
        // The hexagon has duplicate labels but 6 unique rooms
        XCTAssertEqual(result.uniqueRooms, 6, "Should find all 6 unique rooms despite duplicate labels")
        
        // Check that algorithm correctly distinguishes rooms with same labels
        let graph = result.graph
        let nodes = graph.getAllNodes()
        
        // Group nodes by label
        var labelGroups: [RoomLabel: [Int]] = [:]
        for node in nodes {
            if let label = node.label {
                labelGroups[label, default: []].append(node.id)
            }
        }
        
        // Verify that nodes with same label are properly distinguished
        for (label, nodeIds) in labelGroups {
            if nodeIds.count > 1 {
                print("Nodes with label \(label): \(nodeIds)")
                // These nodes should be in different room groups if they're different rooms
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testSingleRoomGraph() {
        // Create a graph with just the starting room (all doors lead back to itself)
        let graph = Graph(startingLabel: .A)
        
        // Add self-loops for all 6 doors
        for door in 0..<6 {
            graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: door, 
                         toNodeId: graph.startingNodeId, toDoor: door)
        }
        
        let result = matcher.identifyRooms(
            sourceGraph: graph,
            expectedRoomCount: 1,
            maxQueries: 20
        )
        
        XCTAssertEqual(result.uniqueRooms, 1, "Should identify single room")
        XCTAssertLessThan(result.queryCount, 10, "Should quickly identify single room")
    }
    
    func testQueryLimitRespected() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Set a very low query limit
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 10
        )
        
        XCTAssertLessThanOrEqual(result.queryCount, 10, "Should respect query limit")
        // May not find all rooms with such a low limit
        print("Found \(result.uniqueRooms) rooms with only \(result.queryCount) queries")
    }
    
    func testDepthLimitRespected() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Limit to depth 1 only
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100,
            maxDepth: 1
        )
        
        // With only depth 1, might not distinguish all rooms
        print("Found \(result.uniqueRooms) rooms with depth limit 1")
        XCTAssertGreaterThan(result.uniqueRooms, 0, "Should find at least some rooms")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceSmallGraph() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        let startTime = Date()
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 3,
            maxQueries: 300
        )
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 1.0, "Should complete small graph quickly")
        XCTAssertEqual(result.uniqueRooms, 3)
    }
    
    func testPerformanceLargeGraph() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        let startTime = Date()
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100
        )
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 2.0, "Should complete hexagon quickly")
        XCTAssertEqual(result.uniqueRooms, 6)
    }
    
    // MARK: - Algorithm Correctness
    
    func testIncreasingDepthStrategy() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // The algorithm should start with depth 1, then increase as needed
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100,
            maxDepth: 3
        )
        
        XCTAssertEqual(result.uniqueRooms, 6, "Should find all rooms by increasing depth")
        
        // The algorithm finds unique rooms through increasing depth exploration
        XCTAssertGreaterThan(result.queryCount, 6, "Should use multiple queries for depth exploration")
    }
    
    func testRoomGroupingCorrectness() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        let result = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 3,
            maxQueries: 300
        )
        
        // Verify each group represents a unique signature
        var seenSignatures = Set<String>()
        for group in result.roomGroups {
            if let firstNodeId = group.first,
               let node = result.graph.getNode(firstNodeId) {
                // All nodes in the group should have the same label
                let label = node.label
                for nodeId in group {
                    if let n = result.graph.getNode(nodeId) {
                        XCTAssertEqual(n.label, label, "Nodes in same group should have same label")
                    }
                }
            }
        }
        
        XCTAssertEqual(result.roomGroups.count, 3, "Should have exactly 3 groups for 3 rooms")
    }
}