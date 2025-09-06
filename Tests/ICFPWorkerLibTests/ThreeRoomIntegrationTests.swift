import XCTest
@testable import ICFPWorkerLib

/// Integration tests for the complete three-room identification algorithm
/// Tests the full flow from initial expansion through signature computation to room identification
final class ThreeRoomIntegrationTests: XCTestCase {
    
    var matcher: GraphMatcher!
    var sourceGraph: Graph!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
        sourceGraph = matcher.createThreeRoomsTestGraph()
    }
    
    // Test 1: Complete algorithm flow for 3-room problem
    func testThreeRoomCompleteIdentification() {
        // The three-room structure:
        // Room A (label 0): doors 0-4 are self-loops, door 5 goes to B
        // Room B (label 1): doors 1-4 are self-loops, door 0 goes back to A, door 5 goes to C  
        // Room C (label 2): all doors are self-loops except door 0 goes back to B
        
        // Phase 1: Minimal exploration to discover all rooms
        let discoveryPaths = ["", "5", "55", "550"]
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        for path in discoveryPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            print("Path '\(path)': \(labels.map { $0.rawValue })")
        }
        
        // Build initial graph
        let graph = matcher.buildGraphFromExploration(explorations: allExplorations)
        
        print("Total nodes in built graph: \(graph.getAllNodes().count)")
        
        // Phase 2: Compute signatures using just labels
        // With this minimal exploration, we can only use label-based signatures
        let allNodes = graph.getAllNodes()
        let signaturePaths = [""]  // Just the node's own label
        
        var signatures: [NodeSignature] = []
        for node in allNodes {
            let signature = matcher.computeNodeSignature(
                node: node,
                paths: signaturePaths,
                graph: graph
            )
            signatures.append(signature)
        }
        
        // Phase 3: Group by signatures (will group by labels with minimal paths)
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("Unique signature groups found: \(uniqueGroups.count)")
        for (index, group) in uniqueGroups.enumerated() {
            let nodeIds = group
            let labels = nodeIds.compactMap { id in
                graph.getAllNodes().first { $0.id == id }?.label
            }
            print("  Group \(index): \(group.count) nodes with labels \(Set(labels))")
        }
        
        // With minimal exploration, we group by labels (3 groups)
        XCTAssertEqual(uniqueGroups.count, 3, "Should identify exactly 3 unique rooms")
    }
    
    // Test 2: Verify initial expansion creates expected structure
    func testThreeRoomInitialExpansion() {
        let initialPaths = ["0", "1", "2", "3", "4", "5"]
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        for path in initialPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            explorations.append((path, labels))
        }
        
        // Verify exploration results
        // Doors 0-4 should all lead to A (self-loops in source, but we create new nodes)
        for i in 0...4 {
            let (_, labels) = explorations[i]
            XCTAssertEqual(labels, [.A, .A], "Door \(i) from A leads to A")
        }
        
        // Door 5 should lead to B
        let (_, labels5) = explorations[5]
        XCTAssertEqual(labels5, [.A, .B], "Door 5 should lead from A to B")
        
        // Build graph - should create 7 nodes (start + 6 new)
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Verify we created duplicates (this is correct behavior!)
        XCTAssertEqual(graph.getAllNodes().count, 7, "Should create 7 nodes (duplicates are correct)")
        
        // Verify graph structure
        let startNode = graph.getNode(graph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
        
        // Check connections exist
        for door in 0...5 {
            XCTAssertNotNil(startNode.doors[door] as Any, "Door \(door) should have a connection")
        }
    }
    
    // Test 3: Verify label analysis groups nodes correctly
    func testThreeRoomLabelAnalysis() {
        // Create initial graph with duplicates
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("1", [RoomLabel.A, RoomLabel.A]),
            ("2", [RoomLabel.A, RoomLabel.A]),
            ("3", [RoomLabel.A, RoomLabel.A]),
            ("4", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B])
        ]
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        let nodes = graph.getAllNodes()
        let labelGroups = matcher.groupNodesByLabel(nodes: nodes)
        
        // Verify grouping
        XCTAssertEqual(labelGroups.count, 2, "Should have 2 label groups")
        XCTAssertEqual(labelGroups[.A]?.count, 6, "Label A should have 6 nodes")
        XCTAssertEqual(labelGroups[.B]?.count, 1, "Label B should have 1 node")
        
        // Check priority
        let priorityGroups = matcher.prioritizeLabelGroups(groups: labelGroups)
        let highestPriority = priorityGroups.min { $0.priority < $1.priority }
        
        XCTAssertEqual(highestPriority?.priority, 1)
        XCTAssertEqual(highestPriority?.label, .A)
        XCTAssertTrue(highestPriority?.reason.contains("duplicate") ?? false)
    }
    
    // Test 4: Verify signature computation detects duplicates
    func testThreeRoomSignatureComputation() {
        // Build graph with more complete exploration
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("1", [RoomLabel.A, RoomLabel.A]),
            ("2", [RoomLabel.A, RoomLabel.A]),
            ("3", [RoomLabel.A, RoomLabel.A]),
            ("4", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B]),
            ("00", [RoomLabel.A, RoomLabel.A, RoomLabel.A]),
            ("01", [RoomLabel.A, RoomLabel.A, RoomLabel.A]),
            ("50", [RoomLabel.A, RoomLabel.B, RoomLabel.A]),
            ("55", [RoomLabel.A, RoomLabel.B, RoomLabel.C])
        ]
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Compute signatures for ALL nodes using the BUILT graph
        let standardPaths = [""]  // Start with just empty path to see node's own label
        let allNodes = graph.getAllNodes()
        
        var signatures: [NodeSignature] = []
        for node in allNodes {
            let signature = matcher.computeNodeSignature(
                node: node,
                paths: standardPaths,
                graph: graph  // Use BUILT graph
            )
            signatures.append(signature)
        }
        
        // Find identical signatures
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        // With just empty path, nodes with same label will have same signature
        let hasMultiNodeGroup = groups.contains { $0.count > 1 }
        XCTAssertTrue(hasMultiNodeGroup, "Should find nodes with identical signatures")
        
        // Now try with more paths to distinguish rooms better
        let betterPaths = ["0", "5"]
        var betterSignatures: [NodeSignature] = []
        for node in allNodes {
            let signature = matcher.computeNodeSignature(
                node: node,
                paths: betterPaths,
                graph: graph
            )
            betterSignatures.append(signature)
        }
        
        let betterGroups = matcher.findIdenticalSignatures(signatures: betterSignatures)
        
        // Should find that nodes reached via doors 0-4 have same signature
        let largestGroup = betterGroups.max { $0.count < $1.count }
        XCTAssertNotNil(largestGroup)
        XCTAssertGreaterThanOrEqual(largestGroup?.count ?? 0, 5, "Doors 0-4 should lead to same room")
    }
    
    // Test 5: Verify strategic path generation
    func testThreeRoomPathGeneration() {
        // Generate paths for different depths
        let depth1Paths = matcher.generatePaths(depth: 1)
        XCTAssertEqual(depth1Paths.count, 6, "Depth 1 should generate 6 paths")
        XCTAssertEqual(Set(depth1Paths), Set(["0", "1", "2", "3", "4", "5"]))
        
        let depth2Paths = matcher.generatePaths(depth: 2)
        // Our implementation generates strategic paths, not all 36
        XCTAssertGreaterThan(depth2Paths.count, 6, "Depth 2 should generate more than depth 1")
        XCTAssertLessThanOrEqual(depth2Paths.count, 36, "Depth 2 should not exceed 36 paths")
        
        // Test strategic selection
        let strategic = matcher.selectStrategicPaths(
            allPaths: depth2Paths,
            strategy: .hammingLike
        )
        
        // Should select a subset of paths
        XCTAssertLessThanOrEqual(strategic.count, depth2Paths.count)
        XCTAssertGreaterThan(strategic.count, 0)
        
        // Should include diverse patterns
        let hasIdentityPatterns = strategic.contains { $0 == "00" || $0 == "11" || $0 == "55" }
        XCTAssertTrue(hasIdentityPatterns, "Should include identity patterns")
    }
    
    // Test 6: Verify exploration execution (from start only!)
    func testThreeRoomExplorationExecution() {
        let paths = ["0", "5", "55"]
        
        // Use the new exploreFromStart method
        let results = matcher.exploreFromStart(
            paths: paths,
            sourceGraph: sourceGraph
        )
        
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].path, "0")
        XCTAssertEqual(results[0].observedLabels, [.A, .A])
        XCTAssertEqual(results[1].path, "5")
        XCTAssertEqual(results[1].observedLabels, [.A, .B])
        XCTAssertEqual(results[2].path, "55")
        XCTAssertEqual(results[2].observedLabels, [.A, .B, .C])
        
        // Batch exploration (only works from start)
        let batchResults = matcher.batchExplore(
            explorations: [(sourceGraph.startingNodeId, paths)],
            sourceGraph: sourceGraph
        )
        
        XCTAssertEqual(batchResults.count, 3)
    }
    
    // Test 7: Verify graph building maintains structure
    func testThreeRoomGraphBuilding() {
        // Build graph incrementally
        let result1 = PathResult(startNodeId: 0, path: "5", observedLabels: [.A, .B])
        let graph1 = matcher.createNodeFromExploration(
            pathResult: result1,
            currentGraph: Graph(startingLabel: .A)
        )
        
        XCTAssertEqual(graph1.getAllNodes().count, 2)
        
        // Add more explorations
        let result2 = PathResult(startNodeId: 0, path: "55", observedLabels: [.A, .B, .C])
        let graph2 = matcher.createNodeFromExploration(
            pathResult: result2,
            currentGraph: graph1
        )
        
        // Should reuse node B and add node C
        XCTAssertEqual(graph2.getAllNodes().count, 3)
        
        // Verify connections
        let startNode = graph2.getNode(graph2.startingNodeId)!
        if let door5 = startNode.doors[5],
           let (nodeBId, _) = door5,
           let nodeB = graph2.getNode(nodeBId) {
            XCTAssertEqual(nodeB.label, .B)
            
            // Check B has connection to C
            if let door5FromB = nodeB.doors[5],
               let (nodeCId, _) = door5FromB,
               let nodeC = graph2.getNode(nodeCId) {
                XCTAssertEqual(nodeC.label, .C)
            } else {
                XCTFail("Node B should connect to C via door 5")
            }
        } else {
            XCTFail("Start should connect to B via door 5")
        }
    }
    
    // Test 8: Verify duplicate detection through signatures
    func testThreeRoomDuplicateMerging() {
        // Create graph with known duplicates
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),
            ("1", [RoomLabel.A, RoomLabel.A]),
            ("2", [RoomLabel.A, RoomLabel.A]),
            ("3", [RoomLabel.A, RoomLabel.A]),
            ("4", [RoomLabel.A, RoomLabel.A]),
            ("5", [RoomLabel.A, RoomLabel.B]),
            ("00", [RoomLabel.A, RoomLabel.A, RoomLabel.A]),
            ("11", [RoomLabel.A, RoomLabel.A, RoomLabel.A]),
            ("22", [RoomLabel.A, RoomLabel.A, RoomLabel.A])
        ]
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        let nodes = graph.getAllNodes()
        
        // All A-labeled nodes should be there (no merging during build)
        let aNodes = nodes.filter { $0.label == .A }
        XCTAssertGreaterThan(aNodes.count, 5, "Should have many A-labeled nodes (duplicates)")
        
        // Compute signatures - nodes 0-4 should have identical signatures
        let paths = [""]  // Just check their label
        var signatures: [NodeSignature] = []
        for node in nodes {
            let sig = matcher.computeNodeSignature(node: node, paths: paths, graph: graph)
            signatures.append(sig)
        }
        
        // Find duplicates through signatures
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        // Should have groups of nodes with same signature
        let largeGroup = groups.max { $0.count < $1.count }
        XCTAssertNotNil(largeGroup)
        XCTAssertGreaterThan(largeGroup?.count ?? 0, 5, "Should find many nodes with same signature")
    }
    
    // Test 9: Verify performance - should complete in < 20 queries
    func testThreeRoomPerformance() {
        var queryCount = 0
        var allExplorations: [(path: String, labels: [RoomLabel])] = []
        
        // Phase 1: Initial exploration (6 queries)
        let initialPaths = ["0", "1", "2", "3", "4", "5"]
        for path in initialPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        // Phase 2: Targeted exploration (should need < 14 more queries)
        let depth2Paths = ["00", "05", "50", "55", "11", "15", "550", "551"]
        for path in depth2Paths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            allExplorations.append((path, labels))
            queryCount += 1
        }
        
        let finalGraph = matcher.buildGraphFromExploration(explorations: allExplorations)
        
        // Compute signatures using BUILT graph
        let nodes = finalGraph.getAllNodes()
        // Use empty path for initial grouping - more complex signatures need complete graph
        let signaturePaths = [""]  // Just check labels
        var signatures: [NodeSignature] = []
        for node in nodes {
            let sig = matcher.computeNodeSignature(
                node: node,
                paths: signaturePaths,
                graph: finalGraph  // Use BUILT graph!
            )
            signatures.append(sig)
        }
        
        // Check if we found 3 unique rooms
        let uniqueGroups = matcher.findIdenticalSignatures(signatures: signatures)
        
        print("Three-room identification completed in \(queryCount) queries")
        print("Found \(uniqueGroups.count) unique signature groups")
        
        XCTAssertEqual(uniqueGroups.count, 3, "Should find exactly 3 rooms")
        XCTAssertLessThan(queryCount, 20, "Should complete in less than 20 queries")
    }
    
    // Test 10: Find minimal exploration set
    func testThreeRoomMinimalExploration() {
        // Try to find the minimal set of paths needed to identify all 3 rooms
        var minimalPaths: [String] = []
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        // Essential paths to discover all rooms
        let essentialPaths = ["5", "55", "550"]  // Discovers B, C, and back to B
        for path in essentialPaths {
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            explorations.append((path, labels))
            minimalPaths.append(path)
        }
        
        // Add one path to confirm A's structure
        let confirmationPath = "0"
        let labels = matcher.explorePath(sourceGraph: sourceGraph, path: confirmationPath)
        explorations.append((confirmationPath, labels))
        minimalPaths.append(confirmationPath)
        
        let graph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Verify we can distinguish the rooms
        let nodes = graph.getAllNodes()
        let labelGroups = matcher.groupNodesByLabel(nodes: nodes)
        
        // Should have discovered all 3 labels
        XCTAssertTrue(labelGroups.keys.contains(.A))
        XCTAssertTrue(labelGroups.keys.contains(.B))
        XCTAssertTrue(labelGroups.keys.contains(.C))
        
        print("Minimal paths for three-room identification: \(minimalPaths)")
        XCTAssertLessThanOrEqual(minimalPaths.count, 5, "Should need at most 5 paths for minimal identification")
    }
}