import XCTest
@testable import ICFPWorkerLib

final class GraphMatcherTests: XCTestCase {
    
    func testHelloWorld() {
        let matcher = GraphMatcher()
        let result = matcher.helloWorld()
        XCTAssertEqual(result, "Hello, World!")
    }
    
    // MARK: - RoomLabel Tests
    
    func testRoomLabelFromInt() {
        XCTAssertEqual(RoomLabel(fromInt: 0), .A)
        XCTAssertEqual(RoomLabel(fromInt: 1), .B)
        XCTAssertEqual(RoomLabel(fromInt: 2), .C)
        XCTAssertEqual(RoomLabel(fromInt: 3), .D)
        XCTAssertNil(RoomLabel(fromInt: 4))
        XCTAssertNil(RoomLabel(fromInt: -1))
    }
    
    func testRoomLabelToInt() {
        XCTAssertEqual(RoomLabel.A.intValue, 0)
        XCTAssertEqual(RoomLabel.B.intValue, 1)
        XCTAssertEqual(RoomLabel.C.intValue, 2)
        XCTAssertEqual(RoomLabel.D.intValue, 3)
    }
    
    // MARK: - Graph Tests
    
    func testGraphInitialization() {
        let graph = Graph(startingLabel: .A)
        
        // Check starting node exists
        let startingNode = graph.getNode(graph.startingNodeId)
        XCTAssertNotNil(startingNode)
        XCTAssertEqual(startingNode?.label, .A)
        XCTAssertEqual(startingNode?.id, graph.startingNodeId)
        
        // Check all 6 doors are initialized but not connected
        XCTAssertEqual(startingNode?.doors.count, 6)
        for door in 0..<6 {
            XCTAssertNil(startingNode?.doors[door] ?? nil)
        }
    }
    
    func testAddNode() {
        let graph = Graph(startingLabel: .A)
        
        let nodeId1 = graph.addNode(label: .B)
        let nodeId2 = graph.addNode(label: .C)
        
        // Check nodes were added with correct labels
        XCTAssertEqual(graph.getNode(nodeId1)?.label, .B)
        XCTAssertEqual(graph.getNode(nodeId2)?.label, .C)
        
        // Check IDs are unique
        XCTAssertNotEqual(nodeId1, nodeId2)
        XCTAssertNotEqual(nodeId1, graph.startingNodeId)
    }
    
    func testAddEdge() {
        let graph = Graph(startingLabel: .A)
        let nodeId1 = graph.addNode(label: .B)
        
        // Connect starting node door 0 to node1 door 3
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: nodeId1, toDoor: 3)
        
        // Check connection from starting node
        let startingNode = graph.getNode(graph.startingNodeId)
        XCTAssertEqual(startingNode?.doors[0]??.nodeId, nodeId1)
        XCTAssertEqual(startingNode?.doors[0]??.doorNumber, 3)
        
        // Check reverse connection
        let node1 = graph.getNode(nodeId1)
        XCTAssertEqual(node1?.doors[3]??.nodeId, graph.startingNodeId)
        XCTAssertEqual(node1?.doors[3]??.doorNumber, 0)
        
        // Check edge was stored
        let edges = graph.getAllEdges()
        XCTAssertEqual(edges.count, 1)
        XCTAssertEqual(edges.first?.fromNodeId, graph.startingNodeId)
        XCTAssertEqual(edges.first?.fromDoor, 0)
        XCTAssertEqual(edges.first?.toNodeId, nodeId1)
        XCTAssertEqual(edges.first?.toDoor, 3)
    }
    
    func testUpdateNodeLabel() {
        let graph = Graph(startingLabel: .A)
        let nodeId = graph.addNode(label: nil)
        
        // Initially no label
        XCTAssertNil(graph.getNode(nodeId)?.label)
        
        // Update label
        graph.updateNodeLabel(nodeId: nodeId, label: .D)
        XCTAssertEqual(graph.getNode(nodeId)?.label, .D)
    }
    
    // MARK: - MapDescription Conversion Tests
    
    func testConvertMapDescriptionToGraph() {
        let matcher = GraphMatcher()
        
        // Create a simple MapDescription
        let mapDesc = MapDescription(
            rooms: [0, 1, 2],  // A, B, C
            startingRoom: 0,
            connections: [
                Connection(from: RoomDoor(room: 0, door: 0), to: RoomDoor(room: 1, door: 3)),
                Connection(from: RoomDoor(room: 1, door: 2), to: RoomDoor(room: 2, door: 5))
            ]
        )
        
        let graph = matcher.convertMapDescriptionToGraph(mapDesc)
        
        // Check nodes are created with correct labels
        XCTAssertEqual(graph.getAllNodes().count, 3)
        XCTAssertEqual(graph.getNode(graph.startingNodeId)?.label, .A)
        
        // Check that all labels are correctly converted
        let allLabels = graph.getAllNodes().compactMap { $0.label }
        XCTAssertTrue(allLabels.contains(.A))
        XCTAssertTrue(allLabels.contains(.B))
        XCTAssertTrue(allLabels.contains(.C))
        
        // Check edges are created
        XCTAssertEqual(graph.getAllEdges().count, 2)
    }
    
    func testCreateHexagonTestGraph() {
        let matcher = GraphMatcher()
        let graph = matcher.createHexagonTestGraph()
        
        // Hexagon layout should have 6 rooms
        XCTAssertEqual(graph.getAllNodes().count, 6)
        
        // Check labels: should have [A, B, C, D, A, B] pattern
        let labels = graph.getAllNodes().sorted { $0.id < $1.id }.compactMap { $0.label }
        XCTAssertEqual(labels.count, 6)
        XCTAssertEqual(labels[0], .A)
        XCTAssertEqual(labels[1], .B)
        XCTAssertEqual(labels[2], .C)
        XCTAssertEqual(labels[3], .D)
        XCTAssertEqual(labels[4], .A)
        XCTAssertEqual(labels[5], .B)
        
        // Should have many edges (hexagon is fully connected)
        XCTAssertGreaterThan(graph.getAllEdges().count, 0)
    }
    
    func testCreateThreeRoomsTestGraph() {
        let matcher = GraphMatcher()
        let graph = matcher.createThreeRoomsTestGraph()
        
        // Three rooms layout should have 3 rooms
        XCTAssertEqual(graph.getAllNodes().count, 3)
        
        // Check labels: should have [A, B, C] pattern
        let labels = graph.getAllNodes().sorted { $0.id < $1.id }.compactMap { $0.label }
        XCTAssertEqual(labels.count, 3)
        XCTAssertEqual(labels[0], .A)
        XCTAssertEqual(labels[1], .B)
        XCTAssertEqual(labels[2], .C)
        
        // Should have some edges
        XCTAssertGreaterThan(graph.getAllEdges().count, 0)
    }
    
    func testLabelConversionInMapDescription() {
        let matcher = GraphMatcher()
        
        // Test all label conversions
        let mapDesc = MapDescription(
            rooms: [0, 1, 2, 3],  // A, B, C, D
            startingRoom: 0,
            connections: []
        )
        
        let graph = matcher.convertMapDescriptionToGraph(mapDesc)
        
        // Get all labels and sort nodes by ID to ensure consistent ordering
        let sortedNodes = graph.getAllNodes().sorted { $0.id < $1.id }
        let labels = sortedNodes.compactMap { $0.label }
        
        // Should have all four label types
        XCTAssertTrue(labels.contains(.A))
        XCTAssertTrue(labels.contains(.B))
        XCTAssertTrue(labels.contains(.C))
        XCTAssertTrue(labels.contains(.D))
    }
    
    // MARK: - Exploration Tests
    
    func testExplorePath() {
        let matcher = GraphMatcher()
        
        // Create a simple test graph
        let graph = Graph(startingLabel: .A)
        let node1 = graph.addNode(label: .B)
        let node2 = graph.addNode(label: .C)
        
        // Connect: starting (A) -door0-> node1 (B) -door1-> node2 (C)
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: node1, toDoor: 3)
        graph.addEdge(fromNodeId: node1, fromDoor: 1, toNodeId: node2, toDoor: 4)
        
        // Test exploring path "0"
        let labels1 = matcher.explorePath(sourceGraph: graph, path: "0")
        XCTAssertEqual(labels1, [.A, .B])
        
        // Test exploring path "01"
        let labels2 = matcher.explorePath(sourceGraph: graph, path: "01")
        XCTAssertEqual(labels2, [.A, .B, .C])
        
        // Test exploring empty path
        let labels3 = matcher.explorePath(sourceGraph: graph, path: "")
        XCTAssertEqual(labels3, [.A])
        
        // Test exploring non-existent door
        let labels4 = matcher.explorePath(sourceGraph: graph, path: "5")
        XCTAssertEqual(labels4, [.A, .A])  // Should stay in same room
    }
    
    func testBuildGraphFromExploration() {
        let matcher = GraphMatcher()
        
        // Simulate exploration results
        let explorations: [(path: String, labels: [RoomLabel])] = [
            ("0", [.A, .B]),           // Starting room A, door 0 leads to room B
            ("1", [.A, .C]),           // Starting room A, door 1 leads to room C
            ("01", [.A, .B, .D]),      // From A through door 0 to B, then door 1 to D
        ]
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Check starting node
        XCTAssertEqual(graph.getNode(graph.startingNodeId)?.label, .A)
        
        // Check that we have at least 4 nodes (A, B, C, D)
        XCTAssertGreaterThanOrEqual(graph.getAllNodes().count, 4)
        
        // Check that all expected labels exist
        let allLabels = graph.getAllNodes().compactMap { $0.label }
        XCTAssertTrue(allLabels.contains(.A))
        XCTAssertTrue(allLabels.contains(.B))
        XCTAssertTrue(allLabels.contains(.C))
        XCTAssertTrue(allLabels.contains(.D))
    }
    
    func testExploreAndRebuildHexagon() {
        let matcher = GraphMatcher()
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Explore various paths through the hexagon
        let explorations: [(path: String, labels: [RoomLabel])] = [
            ("0", matcher.explorePath(sourceGraph: sourceGraph, path: "0")),
            ("1", matcher.explorePath(sourceGraph: sourceGraph, path: "1")),
            ("2", matcher.explorePath(sourceGraph: sourceGraph, path: "2")),
            ("3", matcher.explorePath(sourceGraph: sourceGraph, path: "3")),
            ("4", matcher.explorePath(sourceGraph: sourceGraph, path: "4")),
            ("5", matcher.explorePath(sourceGraph: sourceGraph, path: "5")),
        ]
        
        let rebuiltGraph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Should have created at least 6 nodes (one for each door from starting room)
        // Note: May have more due to duplicates, which is fine
        XCTAssertGreaterThanOrEqual(rebuiltGraph.getAllNodes().count, 6)
        
        // Starting node should still be A
        XCTAssertEqual(rebuiltGraph.getNode(rebuiltGraph.startingNodeId)?.label, .A)
    }
    
    func testExploreAndRebuildThreeRooms() {
        let matcher = GraphMatcher()
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Explore paths through the three rooms - note that path "55" should go A->B->C
        let explorations: [(path: String, labels: [RoomLabel])] = [
            ("5", matcher.explorePath(sourceGraph: sourceGraph, path: "5")),     // Should go to room B
            ("55", matcher.explorePath(sourceGraph: sourceGraph, path: "55")),   // Should go to room B then C
            ("0", matcher.explorePath(sourceGraph: sourceGraph, path: "0")),     // Self-loop in room A
        ]
        
        // Verify our exploration results are what we expect
        XCTAssertEqual(explorations[0].labels, [.A, .B])      // Path "5"
        XCTAssertEqual(explorations[1].labels, [.A, .B, .C])  // Path "55"
        XCTAssertEqual(explorations[2].labels, [.A, .A])      // Path "0" (self-loop)
        
        let rebuiltGraph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Should have at least 3 nodes (may have more due to duplicates, which is fine)
        XCTAssertGreaterThanOrEqual(rebuiltGraph.getAllNodes().count, 3)
        
        // Check starting node
        XCTAssertEqual(rebuiltGraph.getNode(rebuiltGraph.startingNodeId)?.label, .A)
        
        // Check that we have the expected labels (A, B, and at least one C)
        let allLabels = rebuiltGraph.getAllNodes().compactMap { $0.label }
        XCTAssertTrue(allLabels.contains(.A))
        XCTAssertTrue(allLabels.contains(.B))
        
        // Since we're exploring "55" which goes A->B->C, we should have created a C node
        // Even though it might be a duplicate (not connected back properly)
        XCTAssertTrue(allLabels.contains(.C), "Missing label C. Path '55' with labels [A,B,C] should create a C node.")
    }
    
    func testComplexGraph() {
        let graph = Graph(startingLabel: .A)
        let node1 = graph.addNode(label: .B)
        let node2 = graph.addNode(label: .C)
        let node3 = graph.addNode(label: .D)
        
        // Create a small network
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 0, toNodeId: node1, toDoor: 2)
        graph.addEdge(fromNodeId: graph.startingNodeId, fromDoor: 1, toNodeId: node2, toDoor: 4)
        graph.addEdge(fromNodeId: node1, fromDoor: 3, toNodeId: node3, toDoor: 5)
        graph.addEdge(fromNodeId: node2, fromDoor: 0, toNodeId: node3, toDoor: 1)
        
        // Verify all connections
        XCTAssertEqual(graph.getAllNodes().count, 4)
        XCTAssertEqual(graph.getAllEdges().count, 4)
        
        // Check specific paths exist
        let startNode = graph.getNode(graph.startingNodeId)
        XCTAssertEqual(startNode?.doors[0]??.nodeId, node1)
        XCTAssertEqual(startNode?.doors[1]??.nodeId, node2)
        
        let node3Final = graph.getNode(node3)
        XCTAssertEqual(node3Final?.doors[5]??.nodeId, node1)
        XCTAssertEqual(node3Final?.doors[1]??.nodeId, node2)
    }
}