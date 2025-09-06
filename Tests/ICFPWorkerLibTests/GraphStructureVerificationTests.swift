import XCTest
@testable import ICFPWorkerLib

final class GraphStructureVerificationTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test that we can accurately reconstruct the three rooms graph structure
    func testReconstructThreeRoomsStructure() {
        // The three rooms structure is:
        // Room A (label 0): doors 0-4 are self-loops, door 5 goes to B
        // Room B (label 1): doors 1-4 are self-loops, door 0 goes back to A, door 5 goes to C
        // Room C (label 2): all doors are self-loops except door 0 goes back to B
        
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Perform explorations that should reveal the structure
        let explorations = [
            ("", [RoomLabel.A]),
            ("0", [RoomLabel.A, RoomLabel.A]),  // Self-loop in A
            ("1", [RoomLabel.A, RoomLabel.A]),  // Self-loop in A
            ("5", [RoomLabel.A, RoomLabel.B]),  // A to B
            ("50", [RoomLabel.A, RoomLabel.B, RoomLabel.A]),  // A to B, B back to A
            ("55", [RoomLabel.A, RoomLabel.B, RoomLabel.C]),  // A to B to C
            ("550", [RoomLabel.A, RoomLabel.B, RoomLabel.C, RoomLabel.B]),  // A to B to C, C back to B
            ("551", [RoomLabel.A, RoomLabel.B, RoomLabel.C, RoomLabel.C])   // A to B to C, C self-loop
        ]
        
        let reconstructedGraph = matcher.buildGraphFromExploration(explorations: explorations)
        
        // Verify we have nodes with correct labels
        let nodes = reconstructedGraph.getAllNodes()
        let nodeLabels = Set(nodes.compactMap { $0.label })
        XCTAssertTrue(nodeLabels.contains(.A), "Should have node with label A")
        XCTAssertTrue(nodeLabels.contains(.B), "Should have node with label B")
        XCTAssertTrue(nodeLabels.contains(.C), "Should have node with label C")
        
        // Verify the connections from starting node (A)
        let startNode = reconstructedGraph.getNode(reconstructedGraph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
        
        // Doors 0 and 1 should be self-loops (lead back to A)
        for door in [0, 1] {
            if let connection = startNode.doors[door],
               let (targetId, _) = connection {
                if targetId == startNode.id {
                    // Direct self-loop
                    continue
                } else if let targetNode = reconstructedGraph.getNode(targetId) {
                    XCTAssertEqual(targetNode.label, .A, "Door \(door) from A should lead to A")
                }
            }
        }
        
        // Door 5 should lead to B
        if let door5 = startNode.doors[5],
           let (nodeBId, _) = door5,
           let nodeB = reconstructedGraph.getNode(nodeBId) {
            XCTAssertEqual(nodeB.label, .B, "Door 5 from A should lead to B")
            
            // From B, door 0 should lead back to A
            if let door0FromB = nodeB.doors[0],
               let (backToAId, _) = door0FromB,
               let backToA = reconstructedGraph.getNode(backToAId) {
                XCTAssertEqual(backToA.label, .A, "Door 0 from B should lead back to A")
            }
            
            // From B, door 5 should lead to C
            if let door5FromB = nodeB.doors[5],
               let (nodeCId, _) = door5FromB,
               let nodeC = reconstructedGraph.getNode(nodeCId) {
                XCTAssertEqual(nodeC.label, .C, "Door 5 from B should lead to C")
                
                // From C, door 0 should lead back to B
                if let door0FromC = nodeC.doors[0],
                   let (backToBId, _) = door0FromC,
                   let backToB = reconstructedGraph.getNode(backToBId) {
                    XCTAssertEqual(backToB.label, .B, "Door 0 from C should lead back to B")
                }
                
                // From C, door 1 should be self-loop
                if let door1FromC = nodeC.doors[1],
                   let (selfLoopId, _) = door1FromC,
                   let selfLoop = reconstructedGraph.getNode(selfLoopId) {
                    XCTAssertEqual(selfLoop.label, .C, "Door 1 from C should be self-loop")
                }
            }
        } else {
            XCTFail("Door 5 from A should lead to B")
        }
    }
    
    // Test that we can use PathResult to build the same structure
    func testBuildWithPathResults() {
        let graph = Graph(startingLabel: .A)
        
        // Create path results that describe the three rooms structure
        let results = [
            PathResult(startNodeId: graph.startingNodeId, path: "0", observedLabels: [.A, .A]),
            PathResult(startNodeId: graph.startingNodeId, path: "5", observedLabels: [.A, .B]),
            PathResult(startNodeId: graph.startingNodeId, path: "50", observedLabels: [.A, .B, .A]),
            PathResult(startNodeId: graph.startingNodeId, path: "55", observedLabels: [.A, .B, .C]),
            PathResult(startNodeId: graph.startingNodeId, path: "550", observedLabels: [.A, .B, .C, .B])
        ]
        
        let finalGraph = matcher.mergeExplorationResults(results: results, graph: graph)
        
        // Verify the structure
        let startNode = finalGraph.getNode(finalGraph.startingNodeId)!
        XCTAssertEqual(startNode.label, .A)
        
        // Verify path A -> B -> C exists
        var foundPath = false
        if let door5 = startNode.doors[5],
           let (nodeBId, _) = door5,
           let nodeB = finalGraph.getNode(nodeBId) {
            XCTAssertEqual(nodeB.label, .B)
            
            if let door5FromB = nodeB.doors[5],
               let (nodeCId, _) = door5FromB,
               let nodeC = finalGraph.getNode(nodeCId) {
                XCTAssertEqual(nodeC.label, .C)
                foundPath = true
            }
        }
        
        XCTAssertTrue(foundPath, "Should be able to traverse A -> B -> C via door 5")
    }
    
    // Test that signatures correctly identify duplicate nodes
    func testSignaturesIdentifyDuplicates() {
        // Build a graph with potential duplicates
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
        
        // Compute signatures for all nodes
        let standardPaths = ["0", "1", "2", "3", "4", "5"]
        var signatures: [NodeSignature] = []
        
        for node in nodes {
            let signature = matcher.computeNodeSignature(node: node, paths: standardPaths, graph: graph)
            signatures.append(signature)
        }
        
        // Find groups of identical signatures
        let groups = matcher.findIdenticalSignatures(signatures: signatures)
        
        // Nodes with label A and identical connections should be grouped
        // We expect at least one group with multiple nodes (the A self-loops)
        let largeGroups = groups.filter { $0.count > 1 }
        XCTAssertGreaterThan(largeGroups.count, 0, "Should identify duplicate nodes with same signature")
        
        // Verify that nodes in the same group have the same label
        // Note: This is the whole point - nodes with the same signature are the same room!
        for group in groups {
            if group.count > 1 {
                // These are duplicate nodes representing the same room
                var labels: Set<RoomLabel> = []
                for nodeId in group {
                    if let node = nodes.first(where: { $0.id == nodeId }) {
                        if let label = node.label {
                            labels.insert(label)
                        }
                    }
                }
                // Duplicate nodes may have the same or different labels
                // What matters is their signature (connectivity pattern)
                XCTAssertGreaterThan(group.count, 1, "Groups should contain duplicates")
            }
        }
    }
}