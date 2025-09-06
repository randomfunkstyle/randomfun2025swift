import XCTest
@testable import ICFPWorkerLib

final class PrioritizeLabelGroupsTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Multi-node groups get high priority
    func testMultiNodeGroupsGetHighPriority() {
        let groups: [RoomLabel: [Int]] = [
            .A: [1, 2, 3],  // 3 nodes - high priority
            .B: [4],        // 1 node - lower priority
            .C: [5, 6]      // 2 nodes - high priority
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        XCTAssertEqual(priorityGroups.count, 3)
        
        // First two should be high priority (priority = 1)
        XCTAssertEqual(priorityGroups[0].priority, 1)
        XCTAssertEqual(priorityGroups[1].priority, 1)
        
        // Last should be lower priority (priority = 2)
        XCTAssertEqual(priorityGroups[2].priority, 2)
        XCTAssertEqual(priorityGroups[2].label, .B)
    }
    
    // Test 2: Single node groups get low priority
    func testSingleNodeGroupsGetLowPriority() {
        let groups: [RoomLabel: [Int]] = [
            .A: [1],
            .B: [2],
            .C: [3],
            .D: [4]
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        // All should have priority 2 (single nodes)
        for group in priorityGroups {
            XCTAssertEqual(group.priority, 2)
            XCTAssertEqual(group.nodeIds.count, 1)
        }
    }
    
    // Test 3: Empty groups excluded
    func testEmptyGroupsExcluded() {
        let groups: [RoomLabel: [Int]] = [
            .A: [1, 2],
            .B: [],  // Empty group
            .C: [3]
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        XCTAssertEqual(priorityGroups.count, 2)
        XCTAssertFalse(priorityGroups.contains { $0.label == .B })
    }
    
    // Test 4: Stable sort within priority
    func testStableSortWithinPriority() {
        let groups: [RoomLabel: [Int]] = [
            .D: [1, 2],
            .B: [3, 4],
            .C: [5, 6],
            .A: [7, 8]
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        // All have same priority (1), should be sorted by label
        XCTAssertEqual(priorityGroups[0].label, .A)
        XCTAssertEqual(priorityGroups[1].label, .B)
        XCTAssertEqual(priorityGroups[2].label, .C)
        XCTAssertEqual(priorityGroups[3].label, .D)
    }
    
    // Test 5: Priority order (1 > 2 > 3)
    func testPriorityOrder() {
        let groups: [RoomLabel: [Int]] = [
            .A: [1],        // Priority 2
            .B: [2, 3, 4],  // Priority 1
            .C: [5, 6],     // Priority 1
            .D: [7]         // Priority 2
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        // First two should be priority 1 (multi-node)
        XCTAssertEqual(priorityGroups[0].priority, 1)
        XCTAssertEqual(priorityGroups[1].priority, 1)
        
        // Last two should be priority 2 (single-node)
        XCTAssertEqual(priorityGroups[2].priority, 2)
        XCTAssertEqual(priorityGroups[3].priority, 2)
    }
    
    // Test 6: Priority reasoning strings
    func testPriorityReasoning() {
        let groups: [RoomLabel: [Int]] = [
            .A: [1, 2, 3],
            .B: [4]
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        // Check reasoning for multi-node group
        let multiNodeGroup = priorityGroups.first { $0.label == .A }!
        XCTAssertTrue(multiNodeGroup.reason.contains("Multiple nodes"))
        XCTAssertTrue(multiNodeGroup.reason.contains("duplicates"))
        
        // Check reasoning for single-node group
        let singleNodeGroup = priorityGroups.first { $0.label == .B }!
        XCTAssertTrue(singleNodeGroup.reason.contains("Single node"))
        XCTAssertTrue(singleNodeGroup.reason.contains("unique"))
    }
    
    // Test 7: Empty input returns empty
    func testEmptyInputReturnsEmpty() {
        let groups: [RoomLabel: [Int]] = [:]
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        XCTAssertEqual(priorityGroups.count, 0)
    }
    
    // Test 8: Preserves node IDs
    func testPreservesNodeIDs() {
        let groups: [RoomLabel: [Int]] = [
            .A: [10, 20, 30],
            .B: [40, 50]
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        let groupA = priorityGroups.first { $0.label == .A }!
        XCTAssertEqual(groupA.nodeIds, [10, 20, 30])
        
        let groupB = priorityGroups.first { $0.label == .B }!
        XCTAssertEqual(groupB.nodeIds, [40, 50])
    }
    
    // Test 9: Large groups prioritized correctly
    func testLargeGroupsPrioritized() {
        let groups: [RoomLabel: [Int]] = [
            .A: Array(1...100),  // 100 nodes
            .B: [101],           // 1 node
            .C: [102, 103],      // 2 nodes
            .D: [104]            // 1 node
        ]
        
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        // Groups A and C should be priority 1
        XCTAssertEqual(priorityGroups[0].priority, 1)
        XCTAssertEqual(priorityGroups[0].label, .A)
        XCTAssertEqual(priorityGroups[0].nodeIds.count, 100)
        
        XCTAssertEqual(priorityGroups[1].priority, 1)
        XCTAssertEqual(priorityGroups[1].label, .C)
        
        // Groups B and D should be priority 2
        XCTAssertEqual(priorityGroups[2].priority, 2)
        XCTAssertEqual(priorityGroups[3].priority, 2)
    }
    
    // Test 10: Integration with groupNodesByLabel
    func testIntegrationWithGroupNodesByLabel() {
        let nodes = [
            Node(id: 1, label: .A),
            Node(id: 2, label: .A),
            Node(id: 3, label: .A),
            Node(id: 4, label: .B),
            Node(id: 5, label: .C),
            Node(id: 6, label: .C)
        ]
        
        let groups = matcher.groupNodesByLabel(nodes: nodes)
        let priorityGroups = matcher.prioritizeLabelGroups(groups: groups)
        
        XCTAssertEqual(priorityGroups.count, 3)
        
        // A has 3 nodes - priority 1
        let groupA = priorityGroups.first { $0.label == .A }!
        XCTAssertEqual(groupA.priority, 1)
        XCTAssertEqual(groupA.nodeIds.count, 3)
        
        // B has 1 node - priority 2
        let groupB = priorityGroups.first { $0.label == .B }!
        XCTAssertEqual(groupB.priority, 2)
        XCTAssertEqual(groupB.nodeIds.count, 1)
        
        // C has 2 nodes - priority 1
        let groupC = priorityGroups.first { $0.label == .C }!
        XCTAssertEqual(groupC.priority, 1)
        XCTAssertEqual(groupC.nodeIds.count, 2)
    }
}