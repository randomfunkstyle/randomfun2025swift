import Foundation

extension GraphMatcher {
    
    /// Compute a simple concatenation-based signature for a node
    /// - Parameters:
    ///   - node: The node to compute signature for
    ///   - depth: How deep to explore (1 = immediate neighbors, 2 = depth-2 paths)
    ///   - graph: The graph containing the node
    /// - Returns: A string signature that uniquely identifies the room structure
    public func computeSimpleSignature(node: Node, depth: Int, graph: Graph) -> String {
        var signature = ""
        
        // Start with the node's own label
        signature += node.label?.rawValue ?? "?"
        
        if depth >= 1 {
            // Add immediate neighbors (doors 0-5)
            signature += ":"
            for door in 0..<6 {
                if let connection = node.doors[door],
                   let (nextNodeId, _) = connection,
                   let nextNode = graph.getNode(nextNodeId) {
                    signature += nextNode.label?.rawValue ?? "?"
                } else {
                    signature += "X"  // Unknown/undefined
                }
            }
        }
        
        if depth >= 2 {
            // Add all depth-2 paths (00-55)
            signature += ":"
            for firstDoor in 0..<6 {
                for secondDoor in 0..<6 {
                    // Try to follow the path
                    if let firstConnection = node.doors[firstDoor],
                       let (firstNodeId, _) = firstConnection,
                       let firstNode = graph.getNode(firstNodeId),
                       let secondConnection = firstNode.doors[secondDoor],
                       let (secondNodeId, _) = secondConnection,
                       let secondNode = graph.getNode(secondNodeId) {
                        signature += secondNode.label?.rawValue ?? "?"
                    } else {
                        signature += "X"  // Path not available
                    }
                }
            }
        }
        
        return signature
    }
    
    /// Check if a node is fully connected (all 6 doors are defined)
    public func isNodeFullyConnected(node: Node) -> Bool {
        for door in 0..<6 {
            // Check if door connection exists and is not nil
            // node.doors[door] returns Optional<(Int, Int)?>, we need to check if the inner value is nil
            if let doorConnection = node.doors[door] {
                if doorConnection == nil {
                    return false  // Door exists in dictionary but maps to nil (unexplored)
                }
            } else {
                return false  // Door key doesn't exist in dictionary (should not happen)
            }
        }
        return true
    }
    
    /// Find groups of nodes with identical simple signatures
    /// - Parameters:
    ///   - nodes: All nodes to compare
    ///   - depth: Depth of signature to use
    ///   - graph: The graph containing the nodes
    /// - Returns: Groups of node IDs that have identical signatures
    public func groupBySimpleSignature(nodes: [Node], depth: Int, graph: Graph) -> [[Int]] {
        var signatureGroups: [String: [Int]] = [:]
        
        // First, collect all signatures (including partially explored nodes)
        var allSignatures: [(nodeId: Int, signature: String)] = []
        
        for node in nodes {
            let signature = computeSimpleSignature(node: node, depth: depth, graph: graph)
            // Skip nodes with no meaningful connections (all X's except self label)
            if !signature.hasSuffix("XXXXXX") {
                allSignatures.append((nodeId: node.id, signature: signature))
            }
        }
        
        // Group by signature
        for (nodeId, signature) in allSignatures {
            signatureGroups[signature, default: []].append(nodeId)
        }
        
        // Convert to array of arrays
        return signatureGroups.values
            .map { $0.sorted() }
            .sorted { $0.first ?? 0 < $1.first ?? 0 }
    }
    
    /// Compute signatures for the built graph using the simple approach
    public func computeSimpleSignatures(for graph: Graph, depth: Int = 1) -> [[Int]] {
        let nodes = graph.getAllNodes()
        return groupBySimpleSignature(nodes: nodes, depth: depth, graph: graph)
    }
}