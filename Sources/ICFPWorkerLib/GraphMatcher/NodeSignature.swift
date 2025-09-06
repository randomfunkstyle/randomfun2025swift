import Foundation

/// Represents a node's signature based on path explorations
public struct NodeSignature {
    public let nodeId: Int
    /// Maps path strings to observed room labels (e.g., "01" -> B)
    public let pathLabels: [String: RoomLabel]
    
    public init(nodeId: Int, pathLabels: [String: RoomLabel]) {
        self.nodeId = nodeId
        self.pathLabels = pathLabels
    }
}

extension GraphMatcher {
    /// Compute signature for a single node based on exploring specific paths
    /// - Parameters:
    ///   - node: The node to compute signature for
    ///   - paths: The paths to explore from this node
    ///   - graph: The graph containing the node
    /// - Returns: NodeSignature containing the path->label mappings
    public func computeNodeSignature(node: Node, paths: [String], graph: Graph) -> NodeSignature {
        var pathLabels: [String: RoomLabel] = [:]
        
        // For each requested path, explore from this node
        for path in paths {
            var currentNodeId = node.id
            var validPath = true
            
            // Handle empty path (stay at current node)
            if path.isEmpty {
                if let currentNode = graph.getNode(currentNodeId) {
                    pathLabels[path] = currentNode.label ?? .A
                }
                continue
            }
            
            // Walk through each door in the path
            for doorChar in path {
                guard let door = Int(String(doorChar)), door >= 0 && door < 6 else {
                    validPath = false
                    break
                }
                
                // Find where this door leads
                if let currentNode = graph.getNode(currentNodeId),
                   let connection = currentNode.doors[door],
                   let (nextNodeId, _) = connection {
                    currentNodeId = nextNodeId
                } else {
                    // Path cannot be followed from this node
                    validPath = false
                    break
                }
            }
            
            // If we successfully followed the path, record the final label
            if validPath {
                if let finalNode = graph.getNode(currentNodeId) {
                    pathLabels[path] = finalNode.label ?? .A
                }
            }
        }
        
        return NodeSignature(
            nodeId: node.id,
            pathLabels: pathLabels
        )
    }
    
    /// Create a comparable hash from a signature
    /// Since we always explore the same paths in the same order, we can rely on that ordering
    /// - Parameter signature: The signature to hash
    /// - Returns: A deterministic string hash representing the signature
    public func hashSignature(signature: NodeSignature) -> String {
        // Sort paths to ensure consistency (even though they should already be in order)
        // This is just a safety measure in case paths are explored in different orders
        let sortedPaths = signature.pathLabels.keys.sorted()
        
        // Build hash string from sorted path:label pairs
        var hashComponents: [String] = []
        for path in sortedPaths {
            if let label = signature.pathLabels[path] {
                hashComponents.append("\(path):\(label.rawValue)")
            }
        }
        
        // Join all components with separator
        return hashComponents.joined(separator: "|")
    }
    
    /// Group nodes with identical signatures
    /// - Parameter signatures: Array of node signatures to compare
    /// - Returns: Array of arrays, where each inner array contains node IDs with identical signatures
    public func findIdenticalSignatures(signatures: [NodeSignature]) -> [[Int]] {
        // Group signatures by their hash
        var hashGroups: [String: [Int]] = [:]
        
        for signature in signatures {
            let hash = hashSignature(signature: signature)
            if hashGroups[hash] == nil {
                hashGroups[hash] = []
            }
            hashGroups[hash]?.append(signature.nodeId)
        }
        
        // Convert to array of arrays, sorted for consistency
        let groups = hashGroups.values.map { nodeIds in
            nodeIds.sorted()
        }.sorted { $0.first ?? 0 < $1.first ?? 0 }
        
        return groups
    }
}