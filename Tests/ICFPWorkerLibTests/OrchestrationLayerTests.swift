import XCTest
@testable import ICFPWorkerLib

final class OrchestrationLayerTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // MARK: - shouldContinueExploration Tests
    
    // Test 1: Continues when insufficient rooms found
    func testContinuesWhenInsufficientRooms() {
        let state = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 1,
            queryCount: 10,
            maxQueries: 100,
            maxDepth: 3
        )
        
        let decision = matcher.shouldContinueExploration(state: state)
        
        switch decision {
        case .continue(let reason):
            XCTAssertTrue(reason.contains("1 more room"))
            XCTAssertTrue(reason.contains("90 queries remaining"))
        default:
            XCTFail("Should continue exploration")
        }
    }
    
    // Test 2: Stops when enough rooms found
    func testStopsWhenEnoughRooms() {
        let state = ExplorationState(
            uniqueRooms: 3,
            expectedRooms: 3,
            explorationDepth: 2,
            queryCount: 20,
            maxQueries: 100,
            maxDepth: 3
        )
        
        let decision = matcher.shouldContinueExploration(state: state)
        
        switch decision {
        case .stop(let reason):
            XCTAssertTrue(reason.contains("Found exactly 3 expected rooms"))
        default:
            XCTFail("Should stop exploration")
        }
    }
    
    // Test 3: Stops at max depth
    func testStopsAtMaxDepth() {
        let state = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 3,
            queryCount: 50,
            maxQueries: 100,
            maxDepth: 3
        )
        
        let decision = matcher.shouldContinueExploration(state: state)
        
        switch decision {
        case .stop(let reason):
            XCTAssertTrue(reason.contains("maximum exploration depth"))
        default:
            XCTFail("Should stop at max depth")
        }
    }
    
    // Test 4: Stops at query limit
    func testStopsAtQueryLimit() {
        let state = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 2,
            queryCount: 100,
            maxQueries: 100,
            maxDepth: 3
        )
        
        let decision = matcher.shouldContinueExploration(state: state)
        
        switch decision {
        case .stop(let reason):
            XCTAssertTrue(reason.contains("maximum query limit"))
        default:
            XCTFail("Should stop at query limit")
        }
    }
    
    // Test 5: Provides helpful reasons
    func testProvidesReasons() {
        // Test multiple rooms remaining
        let state1 = ExplorationState(
            uniqueRooms: 1,
            expectedRooms: 6,
            explorationDepth: 1,
            queryCount: 10
        )
        
        let decision1 = matcher.shouldContinueExploration(state: state1)
        switch decision1 {
        case .continue(let reason):
            XCTAssertTrue(reason.contains("5 more rooms"))
        default:
            XCTFail("Should provide reason for continuing")
        }
        
        // Test single room remaining
        let state2 = ExplorationState(
            uniqueRooms: 5,
            expectedRooms: 6,
            explorationDepth: 2,
            queryCount: 30
        )
        
        let decision2 = matcher.shouldContinueExploration(state: state2)
        switch decision2 {
        case .continue(let reason):
            XCTAssertTrue(reason.contains("1 more room"))
        default:
            XCTFail("Should provide reason for continuing")
        }
    }
    
    // Test 6: Handles invalid state
    func testHandlesInvalidState() {
        // Invalid expected rooms
        let state1 = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 0,
            explorationDepth: 1,
            queryCount: 10
        )
        
        let decision1 = matcher.shouldContinueExploration(state: state1)
        switch decision1 {
        case .error(let message):
            XCTAssertTrue(message.contains("Invalid expected room count"))
        default:
            XCTFail("Should return error for invalid state")
        }
        
        // Negative values
        let state2 = ExplorationState(
            uniqueRooms: -1,
            expectedRooms: 3,
            explorationDepth: 1,
            queryCount: 10
        )
        
        let decision2 = matcher.shouldContinueExploration(state: state2)
        switch decision2 {
        case .error(let message):
            XCTAssertTrue(message.contains("negative values"))
        default:
            XCTFail("Should return error for negative values")
        }
    }
    
    // MARK: - selectNextExplorations Tests
    
    // Test 7: Selects high priority groups
    func testSelectsHighPriorityGroups() {
        let graph = Graph(startingLabel: .A)
        let labelGroups = [
            PriorityGroup(priority: 1, label: .A, nodeIds: [0, 1, 2], reason: "Multiple nodes with same label"),
            PriorityGroup(priority: 2, label: .B, nodeIds: [3], reason: "Single node")
        ]
        
        let state = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 1,
            queryCount: 10
        )
        
        let nextPaths = matcher.selectNextExplorations(
            state: state,
            graph: graph,
            labelGroups: labelGroups,
            exploredPaths: Set(["0", "1"])
        )
        
        XCTAssertGreaterThan(nextPaths.count, 0, "Should suggest new paths")
        XCTAssertFalse(nextPaths.contains("0"), "Should not include already explored paths")
        XCTAssertFalse(nextPaths.contains("1"), "Should not include already explored paths")
    }
    
    // Test 8: Expands exploration depth
    func testExpandsExplorationDepth() {
        let graph = Graph(startingLabel: .A)
        let labelGroups: [PriorityGroup] = []
        
        // Low progress should increase depth
        let state = ExplorationState(
            uniqueRooms: 1,
            expectedRooms: 6,
            explorationDepth: 1,
            queryCount: 20
        )
        
        let nextPaths = matcher.selectNextExplorations(
            state: state,
            graph: graph,
            labelGroups: labelGroups,
            exploredPaths: Set(["0", "1", "2", "3", "4", "5"])
        )
        
        // Should suggest depth-2 paths since depth-1 are explored
        let hasDepth2 = nextPaths.contains { $0.count == 2 }
        XCTAssertTrue(hasDepth2, "Should expand to depth 2 when progress is low")
    }
    
    // Test 9: Avoids redundant exploration
    func testAvoidsRedundantExploration() {
        let graph = Graph(startingLabel: .A)
        let labelGroups: [PriorityGroup] = []
        
        let state = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 1,
            queryCount: 10
        )
        
        let exploredPaths = Set(["0", "1", "2", "5", "00", "11"])
        
        let nextPaths = matcher.selectNextExplorations(
            state: state,
            graph: graph,
            labelGroups: labelGroups,
            exploredPaths: exploredPaths
        )
        
        // Should not include any already explored paths
        for path in nextPaths {
            XCTAssertFalse(exploredPaths.contains(path), "Should not suggest already explored path: \(path)")
        }
    }
    
    // Test 10: Returns empty when complete
    func testReturnsEmptyWhenComplete() {
        let graph = Graph(startingLabel: .A)
        let labelGroups: [PriorityGroup] = []
        
        // All rooms found
        let state1 = ExplorationState(
            uniqueRooms: 3,
            expectedRooms: 3,
            explorationDepth: 2,
            queryCount: 20
        )
        
        let nextPaths1 = matcher.selectNextExplorations(
            state: state1,
            graph: graph,
            labelGroups: labelGroups
        )
        
        XCTAssertEqual(nextPaths1.count, 0, "Should return empty when all rooms found")
        
        // Query limit reached
        let state2 = ExplorationState(
            uniqueRooms: 2,
            expectedRooms: 3,
            explorationDepth: 2,
            queryCount: 100,
            maxQueries: 100
        )
        
        let nextPaths2 = matcher.selectNextExplorations(
            state: state2,
            graph: graph,
            labelGroups: labelGroups
        )
        
        XCTAssertEqual(nextPaths2.count, 0, "Should return empty when query limit reached")
    }
    
    // Test 11: Performance with large graph
    func testPerformanceWithLargeGraph() {
        // Create a larger graph
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("1", [RoomLabel.A, RoomLabel.B]),
            ("2", [RoomLabel.A, RoomLabel.C]),
            ("3", [RoomLabel.A, RoomLabel.D]),
            ("4", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B])
        ]
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        let nodes = graph.getAllNodes()
        let labelGroups = [
            PriorityGroup(priority: 1, label: .A, nodeIds: [0, 1, 4], reason: "Multiple A"),
            PriorityGroup(priority: 1, label: .B, nodeIds: [2, 5], reason: "Multiple B"),
            PriorityGroup(priority: 2, label: .C, nodeIds: [3], reason: "Single C"),
            PriorityGroup(priority: 2, label: .D, nodeIds: [6], reason: "Single D")
        ]
        
        let state = ExplorationState(
            uniqueRooms: 4,
            expectedRooms: 6,
            explorationDepth: 1,
            queryCount: 20
        )
        
        let startTime = Date()
        let nextPaths = matcher.selectNextExplorations(
            state: state,
            graph: graph,
            labelGroups: labelGroups,
            exploredPaths: Set(["0", "1", "2", "3", "4", "5"])
        )
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.1, "Should select paths quickly")
        XCTAssertGreaterThan(nextPaths.count, 0, "Should suggest some paths")
    }
    
    // Test 12: Balances exploration across groups
    func testBalancesExplorationAcrossGroups() {
        let graph = Graph(startingLabel: .A)
        
        // Multiple high-priority groups
        let labelGroups = [
            PriorityGroup(priority: 1, label: .A, nodeIds: [0, 1], reason: "Duplicate A"),
            PriorityGroup(priority: 1, label: .B, nodeIds: [2, 3], reason: "Duplicate B"),
            PriorityGroup(priority: 2, label: .C, nodeIds: [4], reason: "Single C")
        ]
        
        let state = ExplorationState(
            uniqueRooms: 3,
            expectedRooms: 5,
            explorationDepth: 1,
            queryCount: 10,
            maxQueries: 50
        )
        
        let nextPaths = matcher.selectNextExplorations(
            state: state,
            graph: graph,
            labelGroups: labelGroups,
            exploredPaths: Set(["0", "1", "2"])
        )
        
        XCTAssertGreaterThan(nextPaths.count, 0, "Should suggest paths")
        XCTAssertLessThanOrEqual(nextPaths.count, 12, "Should limit queries per iteration")
        
        // Should include variety of starting doors
        let startingDoors = Set(nextPaths.compactMap { $0.first })
        XCTAssertGreaterThan(startingDoors.count, 1, "Should explore diverse doors")
    }
}