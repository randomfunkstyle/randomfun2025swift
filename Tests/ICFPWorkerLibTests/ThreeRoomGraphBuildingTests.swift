import XCTest
@testable import ICFPWorkerLib

final class ThreeRoomGraphBuildingTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    func testThreeRoomSourceGraphStructure() {
        // First, let's understand the source graph structure
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        print("\n=== THREE ROOM SOURCE GRAPH ANALYSIS ===")
        print("Starting node ID: \(sourceGraph.startingNodeId)")
        
        let allNodes = sourceGraph.getAllNodes()
        print("Total nodes in source: \(allNodes.count)")
        
        for node in allNodes {
            print("\nNode \(node.id): label=\(node.label?.rawValue ?? "nil")")
            for door in 0..<6 {
                if let connection = node.doors[door],
                   let (nextNodeId, returnDoor) = connection {
                    let nextNode = sourceGraph.getNode(nextNodeId)
                    print("  Door \(door) -> Node \(nextNodeId) (label=\(nextNode?.label?.rawValue ?? "?")) via door \(returnDoor)")
                } else {
                    print("  Door \(door) -> UNDEFINED")
                }
            }
        }
    }
    
    func testSimpleExplorationFromThreeRooms() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Test simple exploration from starting position
        print("\n=== SIMPLE EXPLORATION TEST ===")
        
        // Explore each door from starting position
        for door in 0..<6 {
            let path = String(door)
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            print("Path '\(path)': \(labels.map { $0.rawValue }.joined(separator: " -> "))")
        }
    }
    
    func testBuildGraphFromLimitedExploration() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Manually create exploration results for first 6 paths
        var pathResults: [PathResult] = []
        
        for door in 0..<6 {
            let path = String(door)
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            
            let result = PathResult(
                startNodeId: sourceGraph.startingNodeId,
                path: path,
                observedLabels: labels
            )
            pathResults.append(result)
            
            print("PathResult: path='\(path)', labels=\(labels.map { $0.rawValue })")
        }
        
        // Build graph from these explorations
        print("\n=== BUILDING GRAPH FROM EXPLORATION ===")
        let builtGraph = matcher.buildCompleteGraph(from: pathResults)
        
        let builtNodes = builtGraph.getAllNodes()
        print("Built graph has \(builtNodes.count) nodes")
        
        for node in builtNodes {
            print("\nBuilt Node \(node.id): label=\(node.label?.rawValue ?? "nil")")
            var connectionCount = 0
            for door in 0..<6 {
                if let connection = node.doors[door],
                   let (nextNodeId, _) = connection {
                    connectionCount += 1
                    let nextNode = builtGraph.getNode(nextNodeId)
                    print("  Door \(door) -> Node \(nextNodeId) (label=\(nextNode?.label?.rawValue ?? "?"))")
                }
            }
            print("  Total connections: \(connectionCount)")
        }
        
        // Compute signatures
        print("\n=== SIGNATURE ANALYSIS ===")
        for node in builtNodes {
            let signature = matcher.computeSimpleSignature(node: node, depth: 1, graph: builtGraph)
            print("Node \(node.id): signature='\(signature)'")
        }
    }
    
    func testIdentifyUniqueSignatures() {
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        
        // Do full depth-2 exploration 
        var pathResults: [PathResult] = []
        
        // Single door paths
        for door in 0..<6 {
            let path = String(door)
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
            pathResults.append(PathResult(startNodeId: sourceGraph.startingNodeId, path: path, observedLabels: labels))
        }
        
        // Double door paths
        for door1 in 0..<6 {
            for door2 in 0..<6 {
                let path = "\(door1)\(door2)"
                let labels = matcher.explorePath(sourceGraph: sourceGraph, path: path)
                pathResults.append(PathResult(startNodeId: sourceGraph.startingNodeId, path: path, observedLabels: labels))
                
                // Debug specific paths
                if path == "55" || path == "50" || path == "05" {
                    print("DEBUG Path '\(path)': \(labels.map { $0.rawValue })")
                }
            }
        }
        
        print("\n=== FULL EXPLORATION RESULTS ===")
        print("Total explorations: \(pathResults.count)")
        
        let builtGraph = matcher.buildCompleteGraph(from: pathResults)
        let uniqueSignatures = matcher.computeSimpleSignatures(for: builtGraph, depth: 2)
        
        print("Found \(uniqueSignatures.count) unique signatures:")
        for (index, group) in uniqueSignatures.enumerated() {
            print("Group \(index): \(group)")
            if let nodeId = group.first,
               let node = builtGraph.getNode(nodeId) {
                let signature = matcher.computeSimpleSignature(node: node, depth: 2, graph: builtGraph)
                print("  Signature: '\(signature)'")
            }
        }
        
        // Also show ALL nodes and their signatures, even filtered ones
        print("\nALL NODES AND SIGNATURES:")
        let allNodes = builtGraph.getAllNodes()
        for node in allNodes {
            let signature = matcher.computeSimpleSignature(node: node, depth: 2, graph: builtGraph)
            if signature.hasPrefix("C:") {  // Focus on room C
                print("Node \(node.id): label=\(node.label?.rawValue ?? "nil"), signature='\(signature)'")
            }
        }
        
        // With exploration only from the starting node, we can only fully characterize nodes we can reach
        // Room A is fully explored, Room B is partially explored (reached via door 5), 
        // Room C is discovered but not explored (reached via path "55")
        // So we expect 1-3 unique signatures depending on how complete the exploration is
        XCTAssertGreaterThan(uniqueSignatures.count, 0, "Should find at least 1 unique signature")
        XCTAssertLessThanOrEqual(uniqueSignatures.count, 3, "Should find at most 3 unique signatures")
    }
}