import Foundation
import ICFPWorkerLib

let matcher = GraphMatcher()
let sourceGraph = matcher.createHexagonTestGraph()

// Let's explore manually and see what signatures we get
let result = matcher.identifyRooms(
    sourceGraph: sourceGraph,
    expectedRoomCount: 6,
    maxQueries: 50
)

print("=== SIGNATURE ANALYSIS ===")
print("Found \(result.uniqueRooms) unique signatures from \(result.roomGroups.count) groups")

// Let's compute signatures for the first few nodes and see what they look like
let builtGraph = result.graph
let allNodes = builtGraph.getAllNodes().prefix(10)

for node in allNodes {
    let signature = matcher.computeSimpleSignature(node: node, depth: 1, graph: builtGraph)
    print("Node \(node.id): label=\(node.label?.rawValue ?? "nil"), signature='\(signature)'")
    
    // Show what each door leads to
    print("  Doors: ", terminator: "")
    for door in 0..<6 {
        if let connection = node.doors[door],
           let (nextNodeId, _) = connection,
           let nextNode = builtGraph.getNode(nextNodeId) {
            print("\(door)->\(nextNode.label?.rawValue ?? "?") ", terminator: "")
        } else {
            print("\(door)->X ", terminator: "")
        }
    }
    print("")
}