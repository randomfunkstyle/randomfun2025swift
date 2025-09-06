import XCTest
@testable import ICFPWorkerLib

final class GroupNodesByLabelTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Groups nodes by label correctly
    func testGroupsNodesByLabel() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: .B),
            Node(id: 3, label: .A),
            Node(id: 4, label: .C),
            Node(id: 5, label: .B)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[.A], [1, 3])
        XCTAssertEqual(groups[.B], [2, 5])
        XCTAssertEqual(groups[.C], [4])
    }
    
    // Test 2: Handles nodes without labels
    func testHandlesNodesWithoutLabels() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: nil),
            Node(id: 3, label: .B),
            Node(id: 4, label: nil),
            Node(id: 5, label: .A)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[.A], [1, 5])
        XCTAssertEqual(groups[.B], [3])
        XCTAssertNil(groups[.C])
        XCTAssertNil(groups[.D])
    }
    
    // Test 3: Empty nodes returns empty groups
    func testEmptyNodesReturnsEmptyGroups() {
        let nodes: [Node] = []
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 0)
    }
    
    // Test 4: All same label single group
    func testAllSameLabelSingleGroup() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: .A),
            Node(id: 3, label: .A),
            Node(id: 4, label: .A)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[.A], [1, 2, 3, 4])
    }
    
    // Test 5: All different labels multiple groups
    func testAllDifferentLabelsMultipleGroups() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: .B),
            Node(id: 3, label: .C),
            Node(id: 4, label: .D)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 4)
        XCTAssertEqual(groups[.A], [1])
        XCTAssertEqual(groups[.B], [2])
        XCTAssertEqual(groups[.C], [3])
        XCTAssertEqual(groups[.D], [4])
    }
    
    // Test 6: Performance linear in nodes
    func testPerformanceLinearInNodes() {
        var nodes: [Node] = []
        for i in 0..<1000 {
            let label = RoomLabel(fromInt: i % 4)!
            nodes.append(Node(id: i, label: label))
        }
        
        let startTime = Date()
        _ = matcher.groupNodesByLabel(nodes: nodes)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.01, "Should process 1000 nodes quickly")
    }
    
    // Test 7: Node IDs are sorted within groups
    func testNodeIDsSortedWithinGroups() {
        let nodes = [
            Node(id: 5, label: .A),
            Node(id: 2, label: .A),
            Node(id: 8, label: .A),
            Node(id: 1, label: .A)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups[.A], [1, 2, 5, 8], "Node IDs should be sorted")
    }
    
    // Test 8: Handles only unlabeled nodes
    func testHandlesOnlyUnlabeledNodes() {
        let nodes = [
            Node(id: 1, label: nil),
            Node(id: 2, label: nil),
            Node(id: 3, label: nil)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        XCTAssertEqual(groups.count, 0, "Should return empty groups for all unlabeled nodes")
    }
    
    // Test 9: Works with real graph
    func testWorksWithRealGraph() {
        let graph = matcher.createThreeRoomsTestGraph()
        let nodes = graph.getAllNodes()
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        // Should have at least one group
        XCTAssertGreaterThan(groups.count, 0)
        
        // All node IDs should be accounted for (except unlabeled)
        let totalGroupedNodes = groups.values.reduce(0) { $0 + $1.count }
        let labeledNodes = nodes.filter { $0.label != nil }.count
        XCTAssertEqual(totalGroupedNodes, labeledNodes)
    }
    
    // Test 10: Preserves all labels
    func testPreservesAllLabels() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: .B),
            Node(id: 3, label: .C),
            Node(id: 4, label: .D),
            Node(id: 5, label: .A),
            Node(id: 6, label: .B)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        
        // Check all labels are present
        XCTAssertNotNil(groups[.A])
        XCTAssertNotNil(groups[.B])
        XCTAssertNotNil(groups[.C])
        XCTAssertNotNil(groups[.D])
        
        // Check counts
        XCTAssertEqual(groups[.A]?.count, 2)
        XCTAssertEqual(groups[.B]?.count, 2)
        XCTAssertEqual(groups[.C]?.count, 1)
        XCTAssertEqual(groups[.D]?.count, 1)
    }
}