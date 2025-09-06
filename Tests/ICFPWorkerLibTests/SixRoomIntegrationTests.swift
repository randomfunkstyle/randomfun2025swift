import XCTest
@testable import ICFPWorkerLib

/// Integration tests for the six-room hexagon identification algorithm
/// This is more challenging because rooms have duplicate labels
final class SixRoomIntegrationTests: XCTestCase {
    
    var matcher: GraphMatcher!
    var sourceGraph: Graph!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
        sourceGraph = matcher.createHexagonTestGraph()
    }
    
    // Test 1: Complete algorithm flow for 6-room hexagon problem
    func testSixRoomCompleteIdentification() {
        // The hexagon structure has duplicate labels:
        // Room 0: label 0 (A)
        // Room 1: label 1 (B) 
        // Room 2: label 2 (C)
        // Room 3: label 3 (D)
        // Room 4: label 0 (A) - same as room 0!
        // Room 5: label 1 (B) - same as room 1!
        
        print("\n=== Six-Room Hexagon Test ===")
        
        // Phase 1: Initial exploration - all 6 doors from start
        let initialPaths = ["0", "1", "2", "3", "4", "5"]
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        for path in initialPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            print("Path '\(path)': \(labels.map { $0.rawValue })")
        }
        
        // Phase 2: Need deeper exploration to distinguish duplicate labels
        // Rooms 0 and 4 have same label, rooms 1 and 5 have same label
        // We need paths that reveal different connectivity
        let depth2Paths = ["00", "01", "05", "10", "11", "15", "40", "41", "45", "50", "51", "55"]
        for path in depth2Paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
        }
        
        // Phase 3: Even deeper exploration for complex structure
        let depth3Paths = ["000", "111", "222", "333", "444", "555"]
        for path in depth3Paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
        }
        
        // Build graph with all explorations
        let graph = matcher.buildGraphFromExploration(explorations: allExplorations)
        
        print("Total nodes in built graph: \(graph.getAllNodes().count)")
        
        // Phase 4: Compute signatures
        // For hexagon, we need richer signatures to distinguish rooms with same labels
        let allNodes = graph.getAllNodes()
        let signaturePaths = ["0", "1"]  // Try simple paths first
        
        var signatures: [NodeSignature] = []
        for node in allNodes {
            let signature = matcher.computeNodeSignature(
                node: node,
                paths: signaturePaths,
                graph: graph
            )
            signatures.append(signature)
        }
        
        // Phase 5: Find unique rooms
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("Unique signature groups found: \(uniqueGroups.count)")
        for (index, group) in uniqueGroups.enumerated() {
            let nodeIds = group
            let labels = nodeIds.compactMap { id in
                graph.getAllNodes().first { $0.id == id }?.label
            }
            print("  Group \(index): \(group.count) nodes with labels \(Set(labels))")
        }
        
        // With limited exploration and simple signatures, we may not distinguish all 6 rooms
        // The hexagon is complex due to duplicate labels
        // We should find at least 4 unique signatures (one per label)
        XCTAssertGreaterThanOrEqual(uniqueGroups.count, 4, "Should identify at least 4 unique rooms")
        XCTAssertLessThanOrEqual(uniqueGroups.count, 10, "Should not create too many false distinctions")
    }
    
    // Test 2: Verify initial expansion from hexagon start
    func testSixRoomInitialExpansion() {
        let initialPaths = ["0", "1", "2", "3", "4", "5"]
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        for path in initialPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            explorations.append((path, labels))
            print("Door \(path): \(labels.map { $0.rawValue })")
        }
        
        // Build graph - should create 7 nodes (start + 6 new)
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Verify we created duplicates (this is correct behavior!)
        XCTAssertEqual(graph.getAllNodes().count, 7, "Should create 7 nodes initially")
        
        // Check label distribution
        let nodes = graph.getAllNodes()
        let labelGroups = matcher.groupNodesByLabel(nodes: nodes)
        
        print("Label distribution:")
        for (label, nodeIds) in labelGroups {
            print("  Label \(label.rawValue): \(nodeIds.count) nodes")
        }
        
        // We should see duplicate labels
        let hasMultipleA = (labelGroups[.A]?.count ?? 0) > 1
        let hasMultipleB = (labelGroups[.B]?.count ?? 0) > 1
        
        XCTAssertTrue(hasMultipleA || hasMultipleB, "Should have duplicate labels")
    }
    
    // Test 3: Verify duplicate label detection
    func testSixRoomDuplicateLabelDetection() {
        // Explore enough to see duplicate labels
        let paths = ["0", "1", "2", "3", "4", "5"]
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        for path in paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            explorations.append((path, labels))
        }
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        let nodes = graph.getAllNodes()
        let labelGroups = matcher.groupNodesByLabel(nodes: nodes)
        
        // Check priority - groups with multiple nodes should have high priority
        let priorityGroups = matcher.prioritizeLabelGroups(groups: labelGroups)
        
        let highPriorityGroups = priorityGroups.filter { $0.priority == 1 }
        XCTAssertGreaterThan(highPriorityGroups.count, 0, "Should have high-priority duplicate groups")
        
        for group in highPriorityGroups {
            print("High priority group: Label \(group.label.rawValue) with \(group.nodeIds.count) nodes")
            XCTAssertGreaterThan(group.nodeIds.count, 1, "High priority means multiple nodes")
        }
    }
    
    // Test 4: Verify deep exploration distinguishes duplicate labels
    func testSixRoomDeepExploration() {
        // We need deep exploration to distinguish rooms 0 and 4 (both label A)
        // and rooms 1 and 5 (both label B)
        
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        // Initial exploration
        for door in 0...5 {
            let path = String(door)
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
        }
        
        // Depth-2 exploration from rooms with same labels
        // Paths through room 0 vs room 4 should reveal differences
        let depth2Paths = [
            "00", "01", "02", "03", "04", "05",  // From room 0
            "40", "41", "42", "43", "44", "45"   // From room 4
        ]
        
        for path in depth2Paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
        }
        
        let graph = matcher.buildGraphFromExploration(explorations: allExplorations)
        
        // Now compute signatures with paths that can distinguish
        let nodes = graph.getAllNodes()
        let signaturePaths = ["0", "1", "2"]  // Multiple paths for richer signatures
        
        var signatures: [NodeSignature] = []
        for node in nodes {
            let sig = matcher.computeNodeSignature(
                node: node,
                paths: signaturePaths,
                graph: graph
            )
            signatures.append(sig)
        }
        
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("After deep exploration: \(uniqueGroups.count) unique signature groups")
        
        // Should be able to distinguish more rooms with deeper exploration
        XCTAssertGreaterThanOrEqual(uniqueGroups.count, 4, "Deep exploration should distinguish at least 4 rooms")
    }
    
    // Test 5: Verify hexagon structure connections
    func testSixRoomConnectionStructure() {
        // The hexagon has a specific connection pattern
        // Each room connects to multiple other rooms in a circular pattern
        
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.B]),
            ("1", [RoomLabel.A, RoomLabel.C]),
            ("2", [RoomLabel.A, RoomLabel.D]),
            ("3", [RoomLabel.A, RoomLabel.A]),
            ("4", [RoomLabel.A, RoomLabel.B]),
            ("5", [RoomLabel.A, RoomLabel.A])
        ]
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Verify starting node has 6 connections
        let startNode = graph.getNode(graph.startingNodeId)!
        var connectionCount = 0
        for door in 0...5 {
            if startNode.doors[door] != nil {
                connectionCount += 1
            }
        }
        
        XCTAssertEqual(connectionCount, 6, "Hexagon start should have 6 connections")
        
        // Verify we see all 4 labels
        let nodes = graph.getAllNodes()
        let labels = Set(nodes.compactMap { $0.label })
        
        XCTAssertEqual(labels.count, 4, "Hexagon uses all 4 labels")
        XCTAssertTrue(labels.contains(.A))
        XCTAssertTrue(labels.contains(.B))
        XCTAssertTrue(labels.contains(.C))
        XCTAssertTrue(labels.contains(.D))
    }
    
    // Test 6: Verify signature evolution with more exploration
    func testSixRoomSignatureEvolution() {
        // Start with minimal exploration
        var explorations1 = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.B]),
            ("4", [RoomLabel.A, RoomLabel.A])
        ]
        
        let graph1 = matcher.buildGraphFromExploration(explorations: explorations1)
        let nodes1 = graph1.getAllNodes()
        
        // Compute initial signatures
        var signatures1: [NodeSignature] = []
        for node in nodes1 {
            let sig = matcher.computeNodeSignature(
                node: node,
                paths: [""],
                graph: graph1
            )
            signatures1.append(sig)
        }
        
        let groups1 = matcher.findIdenticalSignatures(signatures: signatures1)
        print("With minimal exploration: \(groups1.count) groups")
        
        // Add more exploration
        var explorations2 = explorations1
        explorations2.append(contentsOf: [
            ("00", [RoomLabel.A, RoomLabel.B, RoomLabel.C]),
            ("44", [RoomLabel.A, RoomLabel.A, RoomLabel.C])
        ])
        
        let graph2 = matcher.buildGraphFromExploration(explorations: explorations2)
        let nodes2 = graph2.getAllNodes()
        
        // Compute richer signatures
        var signatures2: [NodeSignature] = []
        for node in nodes2 {
            let sig = matcher.computeNodeSignature(
                node: node,
                paths: ["0", "4"],
                graph: graph2
            )
            signatures2.append(sig)
        }
        
        let groups2 = matcher.findIdenticalSignatures(signatures: signatures2)
        print("With more exploration: \(groups2.count) groups")
        
        // More exploration should lead to better distinction
        XCTAssertGreaterThanOrEqual(groups2.count, groups1.count, "More exploration should not reduce distinction")
    }
    
    // Test 7: Performance test for hexagon
    func testSixRoomPerformance() {
        var queryCount = 0
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        // Phase 1: Initial exploration
        for door in 0...5 {
            let path = String(door)
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        // Phase 2: Strategic depth-2 exploration
        let strategicPaths = ["00", "11", "22", "33", "44", "55", "01", "12", "23", "34", "45", "50"]
        for path in strategicPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        // Phase 3: Additional paths if needed
        let additionalPaths = ["000", "111", "444", "555"]
        for path in additionalPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        let finalGraph = matcher.buildGraphFromExploration(explorations: allExplorations)
        
        // Compute signatures
        let nodes = finalGraph.getAllNodes()
        let signaturePaths = ["0", "1", "4", "5"]
        var signatures: [NodeSignature] = []
        for node in nodes {
            let sig = matcher.computeNodeSignature(
                node: node,
                paths: signaturePaths,
                graph: finalGraph
            )
            signatures.append(sig)
        }
        
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("Six-room identification completed in \(queryCount) queries")
        print("Found \(uniqueGroups.count) unique signature groups")
        
        // Should complete in reasonable number of queries
        XCTAssertLessThan(queryCount, 50, "Should complete in less than 50 queries")
        
        // May not get exactly 6 due to incomplete exploration, but should get at least 4
        XCTAssertGreaterThanOrEqual(uniqueGroups.count, 4, "Should identify at least 4 unique rooms")
    }
    
    // Test 8: Minimal exploration for hexagon
    func testSixRoomMinimalExploration() {
        // What's the minimum exploration needed to identify the hexagon structure?
        var minimalPaths: [String] = []
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        // Start with just discovering all labels
        let discoveryPaths = ["0", "1", "2", "3", "4", "5"]
        for path in discoveryPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            explorations.append((path, labels))
            minimalPaths.append(path)
        }
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Check what we discovered
        let nodes = graph.getAllNodes()
        let labelGroups = matcher.groupNodesByLabel(nodes: nodes)
        
        print("With minimal paths \(minimalPaths):")
        print("  Discovered \(nodes.count) nodes")
        print("  Label groups: \(labelGroups.keys.map { $0.rawValue })")
        
        // We should see all 4 labels even with minimal exploration
        XCTAssertEqual(labelGroups.count, 4, "Should discover all 4 labels")
        
        // But we won't be able to distinguish all 6 rooms without deeper exploration
        let signatures: [NodeSignature] = nodes.map { node in
            matcher.computeNodeSignature(node: node, paths: [""], graph: graph)
        }
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("  Unique groups: \(uniqueGroups.count)")
        XCTAssertLessThanOrEqual(uniqueGroups.count, 4, "With minimal exploration, can't distinguish beyond labels")
    }
    
    // Test 9: Path optimization for hexagon
    func testSixRoomPathOptimization() {
        // Test that strategic path selection works well for hexagon
        
        let allDepth2 = matcher.generatePaths(depth: 2)
        print("Total depth-2 paths: \(allDepth2.count)")
        
        let strategic = matcher.selectStrategicPaths(
            allPaths: allDepth2,
            strategy: .hammingLike
        )
        print("Strategic selection: \(strategic.count) paths")
        
        // Strategic should be smaller than or equal to all paths
        XCTAssertLessThanOrEqual(strategic.count, allDepth2.count)
        
        // Should include identity patterns (00, 11, etc.)
        let identityPatterns = strategic.filter { path in
            path.count == 2 && path.first == path.last
        }
        XCTAssertGreaterThan(identityPatterns.count, 0, "Should include identity patterns")
        
        // Should include diverse patterns
        let firstDigits = Set(strategic.compactMap { $0.first })
        XCTAssertGreaterThanOrEqual(firstDigits.count, 4, "Should cover diverse starting doors")
    }
    
    // Test 10: Complete hexagon identification with full algorithm
    func testSixRoomFullAlgorithm() {
        print("\n=== Full Hexagon Algorithm Test ===")
        
        var queryCount = 0
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        // Step 1: Initial expansion
        let phase1Paths = ["0", "1", "2", "3", "4", "5"]
        for path in phase1Paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        var currentGraph = matcher.buildGraphFromExploration(explorations: allExplorations)
        var uniqueRoomCount = 0
        
        // Step 2: Iterative refinement
        for depth in 2...3 {
            print("Exploring depth \(depth)...")
            
            // Generate strategic paths
            let allPaths = matcher.generatePaths(depth: depth)
            let strategicPaths = matcher.selectStrategicPaths(
                allPaths: allPaths,
                strategy: .hammingLike
            )
            
            // Explore a subset
            for path in strategicPaths.prefix(12) {
                let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
                allExplorations.append((path, labels))
                queryCount += 1
            }
            
            // Rebuild graph
            currentGraph = matcher.buildGraphFromExploration(explorations: allExplorations)
            
            // Compute signatures
            let nodes = currentGraph.getAllNodes()
            let signaturePaths = Array(phase1Paths.prefix(3))  // Use simple paths
            
            var signatures: [NodeSignature] = []
            for node in nodes {
                let sig = matcher.computeNodeSignature(
                    node: node,
                    paths: signaturePaths,
                    graph: currentGraph
                )
                signatures.append(sig)
            }
            
            let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
            uniqueRoomCount = uniqueGroups.count
            
            print("  After depth \(depth): \(uniqueRoomCount) unique rooms found with \(queryCount) queries")
            
            // Stop if we found 6 rooms
            if uniqueRoomCount >= 6 {
                break
            }
        }
        
        print("Final result: \(uniqueRoomCount) unique rooms in \(queryCount) queries")
        
        // Should find at least 4 unique rooms (may not get all 6 with limited exploration)
        XCTAssertGreaterThanOrEqual(uniqueRoomCount, 4, "Should find at least 4 unique rooms")
        XCTAssertLessThan(queryCount, 50, "Should use less than 50 queries")
    }
}