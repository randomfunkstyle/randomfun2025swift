import XCTest
@testable import ICFPWorkerLib

final class FindIdenticalSignaturesTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Groups identical signatures correctly
    func testGroupsIdenticalSignatures() {
        // Create three nodes with two having identical signatures
        let signature1 = NodeSignature(
            nodeId: 1,
            pathLabels: ["0": .A, "1": .B]
        )
        
        let signature2 = NodeSignature(
            nodeId: 2,
            pathLabels: ["0": .A, "1": .B] // Same as signature1
        )
        
        let signature3 = NodeSignature(
            nodeId: 3,
            pathLabels: ["0": .C, "1": .D] // Different
        )
        
        let groups = matcher.findIdenticalSignatures(signatures: [signature1, signature2, signature3])
        
        XCTAssertEqual(groups.count, 2, "Should have 2 groups")
        XCTAssertTrue(groups.contains([1, 2]), "Nodes 1 and 2 should be grouped together")
        XCTAssertTrue(groups.contains([3]), "Node 3 should be in its own group")
    }
    
    // Test 2: Separates different signatures
    func testSeparatesDifferentSignatures() {
        let signatures = [
            NodeSignature(nodeId: 1, pathLabels: ["0": .A]),
            NodeSignature(nodeId: 2, pathLabels: ["0": .B]),
            NodeSignature(nodeId: 3, pathLabels: ["0": .C]),
            NodeSignature(nodeId: 4, pathLabels: ["0": .D])
        ]
        
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        XCTAssertEqual(groups.count, 4, "Each signature should be in its own group")
        for group in groups {
            XCTAssertEqual(group.count, 1, "Each group should have exactly one node")
        }
    }
    
    // Test 3: Handles empty signatures
    func testHandlesEmptySignatures() {
        let signatures: [NodeSignature] = []
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        XCTAssertEqual(groups.count, 0, "Empty input should produce empty output")
    }
    
    // Test 4: Single node forms single group
    func testSingleNodeGroups() {
        let signature = NodeSignature(
            nodeId: 42,
            pathLabels: ["0": .A, "1": .B, "2": .C]
        )
        
        let groups = matcher.findIdenticalSignatures(signatures: [signature])
        
        XCTAssertEqual(groups.count, 1, "Should have one group")
        XCTAssertEqual(groups[0], [42], "Group should contain the single node")
    }
    
    // Test 5: All identical signatures form single group
    func testAllIdenticalSingleGroup() {
        let pathLabels: [String: RoomLabel] = ["0": .A, "1": .B, "5": .C]
        let signatures = (1...10).map { nodeId in
            NodeSignature(
                nodeId: nodeId,
                pathLabels: pathLabels
            )
        }
        
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        XCTAssertEqual(groups.count, 1, "All identical signatures should form one group")
        XCTAssertEqual(groups[0].count, 10, "The group should contain all 10 nodes")
        XCTAssertEqual(groups[0], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "Nodes should be sorted")
    }
    
    // Test 6: Performance with large number of signatures
    func testPerformanceNLogN() {
        // Create 1000 signatures with 100 unique patterns
        var signatures: [NodeSignature] = []
        for i in 0..<1000 {
            let patternId = i % 100
            let pathLabels = [
                "0": RoomLabel(fromInt: patternId % 4)!,
                "1": RoomLabel(fromInt: (patternId / 4) % 4)!,
                "2": RoomLabel(fromInt: (patternId / 16) % 4)!
            ]
            
            signatures.append(NodeSignature(
                nodeId: i,
                pathLabels: pathLabels
            ))
        }
        
        let startTime = Date()
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(timeInterval, 0.1, "Should process 1000 signatures quickly")
        XCTAssertEqual(groups.count, 64, "Should have 64 unique patterns (4^3 combinations for first 64)")
    }
    
    // Test 7: Groups are sorted consistently
    func testGroupsSortedConsistently() {
        let signatures = [
            NodeSignature(nodeId: 5, pathLabels: ["0": .A]),
            NodeSignature(nodeId: 3, pathLabels: ["0": .A]),
            NodeSignature(nodeId: 8, pathLabels: ["0": .B]),
            NodeSignature(nodeId: 1, pathLabels: ["0": .A])
        ]
        
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        // Check that nodes within groups are sorted
        for group in groups {
            let sorted = group.sorted()
            XCTAssertEqual(group, sorted, "Nodes within group should be sorted")
        }
        
        // Groups should be sorted by their first element
        XCTAssertEqual(groups[0], [1, 3, 5], "First group should have nodes with label A")
        XCTAssertEqual(groups[1], [8], "Second group should have node with label B")
    }
    
    // Test 8: Handles signatures with different path sets
    func testDifferentPathSets() {
        let signature1 = NodeSignature(
            nodeId: 1,
            pathLabels: ["0": .A, "1": .B]
        )
        
        let signature2 = NodeSignature(
            nodeId: 2,
            pathLabels: ["0": .A] // Different path set
        )
        
        let signature3 = NodeSignature(
            nodeId: 3,
            pathLabels: ["0": .A, "1": .B] // Same as signature1
        )
        
        let groups = matcher.findIdenticalSignatures(signatures: [signature1, signature2, signature3])
        
        XCTAssertEqual(groups.count, 2, "Should have 2 groups")
        XCTAssertTrue(groups.contains([1, 3]), "Nodes 1 and 3 should be grouped")
        XCTAssertTrue(groups.contains([2]), "Node 2 should be alone")
    }
    
    // Test 9: Real-world test with three rooms graph
    func testThreeRoomsGraphSignatures() {
        // Build graph from explorations to get multiple nodes
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("1", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B]),
            ("55", [RoomLabel.A, RoomLabel.B, RoomLabel.C])
        ]
        
        let exploredGraph = matcher.buildGraphFromExploration(explorations: explorations)
        let nodes = exploredGraph.getAllNodes()
        
        // Compute signatures for all nodes
        let paths = ["0", "1", "5"]
        var signatures: [NodeSignature] = []
        
        for node in nodes {
            let signature = matcher.computeNodeSignature(node: node, paths: paths, graph: exploredGraph)
            signatures.append(signature)
        }
        
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        // Should have identified duplicate nodes (same room) vs unique rooms
        XCTAssertGreaterThan(groups.count, 0, "Should have at least one group")
        
        // Check that grouping is working
        let totalNodes = groups.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalNodes, nodes.count, "All nodes should be in exactly one group")
    }
    
    // Test 10: Empty path labels still group correctly
    func testEmptyPathLabels() {
        let signature1 = NodeSignature(
            nodeId: 1,
            pathLabels: [:]
        )
        
        let signature2 = NodeSignature(
            nodeId: 2,
            pathLabels: [:]
        )
        
        let signature3 = NodeSignature(
            nodeId: 3,
            pathLabels: ["0": .A]
        )
        
        let groups = matcher.findIdenticalSignatures(signatures: [signature1, signature2, signature3])
        
        XCTAssertEqual(groups.count, 2, "Should have 2 groups")
        XCTAssertTrue(groups.contains([1, 2]), "Empty signatures should group together")
        XCTAssertTrue(groups.contains([3]), "Non-empty signature should be separate")
    }
}