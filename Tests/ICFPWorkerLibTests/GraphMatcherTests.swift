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