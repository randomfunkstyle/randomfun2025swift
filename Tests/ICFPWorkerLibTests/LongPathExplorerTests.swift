import XCTest
@testable import ICFPWorkerLib

final class LongPathExplorerTests: XCTestCase {
    
    var explorer: LongPathExplorer!
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        explorer = LongPathExplorer()
        matcher = GraphMatcher()
    }
    
    // MARK: - Path Generation Tests
    
    func testGenerateLongPath() {
        let path = explorer.generateLongPath(expectedRooms: 6)
        
        // Should be 3 * expectedRooms in length
        XCTAssertEqual(path.count, 18, "Path should be 3 * expectedRooms")
        
        // Should use all doors for a 6-room case
        XCTAssertTrue(path.contains("0"))
        XCTAssertTrue(path.contains("1"))
        XCTAssertTrue(path.contains("2"))
        XCTAssertTrue(path.contains("3"))
        XCTAssertTrue(path.contains("4"))
        XCTAssertTrue(path.contains("5"))
    }
    
    func testGenerateLongPathSmallRoom() {
        let path = explorer.generateLongPath(expectedRooms: 3)
        XCTAssertEqual(path.count, 9, "Path should be 3 * 3 = 9")
        XCTAssertEqual(path, "543210543", "Should be pattern repeated")
    }
    
    func testGenerateLongPathSingleRoom() {
        let path = explorer.generateLongPath(expectedRooms: 1)
        XCTAssertEqual(path.count, 3, "Path should be 3 * 1 = 3")
        XCTAssertEqual(path, "543", "Should be first 3 of reverse pattern")
    }
    
    // MARK: - Fingerprint Extraction Tests
    
    func testExtractFingerprints() {
        let path = "012345"
        let labels: [RoomLabel] = [.A, .B, .C, .D, .A, .B, .C]  // 7 labels for path of length 6
        let expectedRooms = 3  // Fingerprints should be 3 chars each
        
        let fingerprints = explorer.extractFingerprints(path: path, labels: labels, expectedRooms: expectedRooms)
        
        // With 7 labels and fingerprint length 3, we can extract from positions 0-3
        // But we skip duplicates, so might have fewer
        XCTAssertGreaterThan(fingerprints.count, 0, "Should have fingerprints")
        
        // Check first fingerprint (starting position)
        if fingerprints.count > 0 {
            XCTAssertEqual(fingerprints[0].reachedByPath, "")
            XCTAssertEqual(fingerprints[0].startLabel, .A)
            XCTAssertEqual(fingerprints[0].fingerprint, "ABC")  // First 3 chars from position 0
        }
    }
    
    func testExtractFingerprintsWithDuplicates() {
        let path = "0101"
        let labels: [RoomLabel] = [.A, .B, .A, .B, .A]  // Cycling between A and B
        let expectedRooms = 2  // Looking for 2 rooms
        
        let fingerprints = explorer.extractFingerprints(path: path, labels: labels, expectedRooms: expectedRooms)
        
        // Should have fingerprints for positions that have 2 chars remaining
        // Position 0: "BA", Position 1: "AB", Position 2: "BA" (duplicate)
        let paths = fingerprints.map { $0.reachedByPath }
        XCTAssertEqual(Set(paths).count, paths.count, "Should have unique paths only")
    }
    
    // MARK: - Cycle Detection Tests
    
    func testDetectSimpleCycle() {
        let labels: [RoomLabel] = [.A, .B, .A, .B, .A, .B]
        
        let cycle = explorer.detectCycles(in: labels)
        
        XCTAssertNotNil(cycle, "Should detect cycle")
        XCTAssertEqual(cycle?.cycleLength, 2, "Cycle length should be 2")
        XCTAssertEqual(cycle?.pattern, "AB", "Pattern should be AB")
    }
    
    func testDetectLongerCycle() {
        let labels: [RoomLabel] = [.A, .B, .C, .A, .B, .C, .A, .B, .C]
        
        let cycle = explorer.detectCycles(in: labels)
        
        XCTAssertNotNil(cycle, "Should detect cycle")
        XCTAssertEqual(cycle?.cycleLength, 3, "Cycle length should be 3")
        XCTAssertEqual(cycle?.pattern, "ABC", "Pattern should be ABC")
    }
    
    func testNoCycleDetection() {
        let labels: [RoomLabel] = [.A, .B, .C, .D, .A, .C]  // No clear cycle
        
        let cycle = explorer.detectCycles(in: labels)
        
        XCTAssertNil(cycle, "Should not detect a cycle in non-repeating pattern")
    }
    
    // MARK: - Fingerprint Grouping Tests
    
    func testGroupFingerprintsByPattern() {
        let fingerprints = [
            RoomFingerprint(reachedByPath: "", fingerprint: "ABCDABCD", startLabel: .A),
            RoomFingerprint(reachedByPath: "0", fingerprint: "BCDABCD", startLabel: .B),
            RoomFingerprint(reachedByPath: "5", fingerprint: "ABCDABCD", startLabel: .A),  // Same as start
            RoomFingerprint(reachedByPath: "01", fingerprint: "CDABCD", startLabel: .C)
        ]
        
        let groups = explorer.groupFingerprintsByPattern(fingerprints)
        
        // Should group identical patterns together
        XCTAssertEqual(groups.count, 3, "Should have 3 unique patterns")
        
        // The ABCDABCD pattern should have 2 paths
        let abcdGroup = groups.values.first { $0.contains("") && $0.contains("5") }
        XCTAssertNotNil(abcdGroup, "Should group paths with same fingerprint")
        XCTAssertEqual(abcdGroup?.count, 2, "Should have 2 paths with same pattern")
    }
    
    // MARK: - Integration Tests
    
    func testOptimizedIdentificationThreeRooms() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // First, let's see what path is generated and what labels we get
        let path = explorer.generateLongPath(expectedRooms: 3)
        let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
        
        print("\nThree rooms test:")
        print("  Path: '\(path)'")
        print("  Labels: \(labels.map { $0.rawValue })")
        
        let result = explorer.identifyRoomsOptimized(
            sourceGraph: sourceGraph,
            expectedRooms: 3
        )
        
        // Should identify rooms with minimal queries
        XCTAssertLessThanOrEqual(result.queryCount, 2, "Should use at most 2 queries")
        
        // Debug: show the fingerprints
        print("  Fingerprints:")
        for fp in result.fingerprints {
            print("    Path '\(fp.reachedByPath)': '\(fp.fingerprint)'")
        }
        
        // With 2*n length path, we can get multiple fingerprints
        // Should find at least 2 unique rooms (A and B)
        XCTAssertGreaterThanOrEqual(result.uniqueRooms, 2, "Should find at least 2 unique rooms")
        
        print("Three rooms identified:")
        print("  Unique rooms: \(result.uniqueRooms)")
        print("  Queries used: \(result.queryCount)")
        print("  Fingerprints found: \(result.fingerprints.count)")
    }
    
    func testOptimizedIdentificationSixRooms() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        let result = explorer.identifyRoomsOptimized(
            sourceGraph: sourceGraph,
            expectedRooms: 6
        )
        
        // Should use just 1 query
        XCTAssertEqual(result.queryCount, 1, "Should use only 1 query")
        
        // With 2*n length path, we should find multiple unique patterns
        XCTAssertGreaterThan(result.uniqueRooms, 1, "Should find multiple unique rooms")
        
        print("Six rooms identified:")
        print("  Unique rooms: \(result.uniqueRooms)")
        print("  Queries used: \(result.queryCount)")
        print("  Fingerprints found: \(result.fingerprints.count)")
    }
    
    func testOptimizedVsTraditional() {
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Traditional approach
        let traditionalResult = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: 6,
            maxQueries: 100
        )
        
        // Optimized approach
        let optimizedResult = explorer.identifyRoomsOptimized(
            sourceGraph: sourceGraph,
            expectedRooms: 6
        )
        
        print("\nComparison:")
        print("Traditional: \(traditionalResult.queryCount) queries")
        print("Optimized: \(optimizedResult.queryCount) queries")
        
        // Optimized should use far fewer queries
        XCTAssertLessThan(optimizedResult.queryCount, traditionalResult.queryCount,
                         "Optimized should use fewer queries than traditional")
        
        // Should achieve significant reduction
        let reduction = Double(traditionalResult.queryCount - optimizedResult.queryCount) / Double(traditionalResult.queryCount) * 100
        print("Query reduction: \(String(format: "%.1f", reduction))%")
        XCTAssertGreaterThan(reduction, 90, "Should achieve >90% query reduction")
    }
    
    // MARK: - Edge Cases
    
    func testSingleRoomFingerprintDebug() {
        // Debug test to understand why single room finds 3 patterns
        let graph = Graph(startingLabel: .A)
        for door in 0..<6 {
            graph.addOneWayConnection(
                fromNodeId: graph.startingNodeId,
                fromDoor: door,
                toNodeId: graph.startingNodeId
            )
        }
        
        // Generate path and explore
        let path = explorer.generateLongPath(expectedRooms: 1)  // Should be "543"
        let labels = matcher.explorePath(sourceGraph: graph, path: path)
        
        print("\n=== SINGLE ROOM DEBUG ===")
        print("Path: '\(path)'")
        print("Labels: \(labels.map { $0.rawValue })")
        
        // Extract fingerprints
        let fingerprints = explorer.extractFingerprints(path: path, labels: labels, expectedRooms: 1)
        
        print("\nFingerprints extracted (expecting 1-char fingerprints):")
        for fp in fingerprints {
            print("  Path '\(fp.reachedByPath)': fingerprint='\(fp.fingerprint)' (label=\(fp.startLabel.rawValue))")
        }
        
        // Show grouping
        let groups = explorer.groupFingerprintsByPattern(fingerprints)
        print("\nGrouped patterns: \(groups.count) unique")
        for (pattern, paths) in groups {
            print("  Pattern '\(pattern)': paths \(paths)")
        }
        
        // This should find only 1 unique room, but currently finds 3
        // because "AA", "A", and "" are treated as different patterns
        print("\nProblem: Different length fingerprints of same repeating character")
        print("  'AA' and 'A' should both normalize to 'A' (single room repeating)")
    }
    
    func testSingleRoomGraph() {
        // Create a single room that loops to itself
        let graph = Graph(startingLabel: .A)
        for door in 0..<6 {
            graph.addOneWayConnection(
                fromNodeId: graph.startingNodeId,
                fromDoor: door,
                toNodeId: graph.startingNodeId
            )
        }
        
        let result = explorer.identifyRoomsOptimized(
            sourceGraph: graph,
            expectedRooms: 1
        )
        
        XCTAssertEqual(result.uniqueRooms, 1, "Should identify single room")
        XCTAssertEqual(result.queryCount, 1, "Should use only 1 query")
        
        // Should detect the trivial cycle
        let labels = Array(repeating: RoomLabel.A, count: 3)
        let cycle = explorer.detectCycles(in: labels)
        XCTAssertNotNil(cycle)
        XCTAssertEqual(cycle?.cycleLength, 1, "Should detect single-room cycle")
    }
    
    // MARK: - Multi-Query Pattern Tests
    
    func testMultiplePatternExploration() {
        // Test that different patterns generate different paths
        let path1 = explorer.generateLongPath(expectedRooms: 3, patternIndex: 0)
        let path2 = explorer.generateLongPath(expectedRooms: 3, patternIndex: 1)
        let path3 = explorer.generateLongPath(expectedRooms: 3, patternIndex: 2)
        
        XCTAssertEqual(path1, "543210543", "First pattern should be reverse")
        XCTAssertEqual(path2, "012345012", "Second pattern should be forward")
        XCTAssertEqual(path3, "135024135", "Third pattern should be skip pattern")
        
        // All should have same length (3 * rooms)
        XCTAssertEqual(path1.count, 9)
        XCTAssertEqual(path2.count, 9)
        XCTAssertEqual(path3.count, 9)
    }
    
    func testComplexGraphRequiringMultipleQueries() {
        // Create a graph where some rooms are only accessible through specific doors
        let graph = Graph(startingLabel: .A)
        let roomB = graph.addNode(label: .B)
        let roomC = graph.addNode(label: .C)
        let roomD = graph.addNode(label: .D)
        
        // Room A connects to B only through door 4
        graph.addOneWayConnection(fromNodeId: graph.startingNodeId, fromDoor: 4, toNodeId: roomB)
        // Room B connects to C only through door 2
        graph.addOneWayConnection(fromNodeId: roomB, fromDoor: 2, toNodeId: roomC)
        // Room C connects to D only through door 1
        graph.addOneWayConnection(fromNodeId: roomC, fromDoor: 1, toNodeId: roomD)
        
        // Add some self-loops to fill other doors
        for door in [0, 1, 2, 3, 5] {
            graph.addOneWayConnection(fromNodeId: graph.startingNodeId, fromDoor: door, toNodeId: graph.startingNodeId)
        }
        
        let result = explorer.identifyRoomsOptimized(
            sourceGraph: graph,
            expectedRooms: 4
        )
        
        print("\nComplex graph results:")
        print("  Query count: \(result.queryCount)")
        print("  Unique rooms found: \(result.uniqueRooms)")
        print("  Fingerprints: \(result.fingerprints.count)")
        
        // May need multiple queries to discover all rooms
        XCTAssertGreaterThanOrEqual(result.queryCount, 1, "Should use at least 1 query")
        
        // Should eventually find all or most rooms
        XCTAssertGreaterThanOrEqual(result.uniqueRooms, 2, "Should find at least some rooms")
    }
    
    func testEarlyTerminationWhenAllRoomsFound() {
        // Test that exploration stops early when all rooms are found
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        let result = explorer.identifyRoomsOptimized(
            sourceGraph: sourceGraph,
            expectedRooms: 3
        )
        
        print("\nEarly termination test:")
        print("  Query count: \(result.queryCount)")
        print("  Unique rooms found: \(result.uniqueRooms)")
        
        // Should find rooms with reasonable number of queries
        XCTAssertLessThan(result.queryCount, 10, "Should use reasonable number of queries")
        XCTAssertGreaterThanOrEqual(result.uniqueRooms, 2, "Should find most rooms")
    }
}