import Foundation

/// Represents the result of exploring a path from a node
public struct PathResult {
    public let startNodeId: Int
    public let path: String
    public let observedLabels: [RoomLabel]
    
    public init(startNodeId: Int, path: String, observedLabels: [RoomLabel]) {
        self.startNodeId = startNodeId
        self.path = path
        self.observedLabels = observedLabels
    }
}

extension GraphMatcher {
    /// Execute exploration from a single node for multiple paths
    /// - Parameters:
    ///   - node: The node to explore from
    ///   - paths: Array of paths to explore
    ///   - sourceGraph: The graph to explore
    /// - Returns: Array of PathResult for each exploration
    public func explorePathsFromNode(node: Node, paths: [String], sourceGraph: Graph) -> [PathResult] {
        var results: [PathResult] = []
        
        for path in paths {
            // Use existing explorePath method to get labels
            let labels = explorePath(sourceGraph: sourceGraph, 
                                    path: path, 
                                    startingNodeId: node.id)
            
            let result = PathResult(
                startNodeId: node.id,
                path: path,
                observedLabels: labels
            )
            results.append(result)
        }
        
        return results
    }
    
    /// Helper method for explorePath with custom starting node
    private func explorePath(sourceGraph: Graph, path: String, startingNodeId: Int) -> [RoomLabel] {
        var currentNodeId = startingNodeId
        var labels: [RoomLabel] = []
        
        // Add starting room label
        if let startingNode = sourceGraph.getNode(currentNodeId) {
            labels.append(startingNode.label ?? .A)  // Default to A if no label
        }
        
        // Walk through each door in the path
        for doorChar in path {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            // Find where this door leads
            if let currentNode = sourceGraph.getNode(currentNodeId),
               let connection = currentNode.doors[door],
               let (nextNodeId, _) = connection {
                currentNodeId = nextNodeId
                
                // Add the label of the room we entered
                if let nextNode = sourceGraph.getNode(nextNodeId) {
                    labels.append(nextNode.label ?? .A)  // Default to A if no label
                }
            } else {
                // If door doesn't exist or leads nowhere, stay in current room
                if let currentNode = sourceGraph.getNode(currentNodeId) {
                    labels.append(currentNode.label ?? .A)
                }
            }
        }
        
        return labels
    }
    
    /// Execute multiple explorations efficiently
    /// - Parameters:
    ///   - explorations: Array of tuples containing (NodeId, [paths to explore])
    ///   - sourceGraph: The graph to explore
    /// - Returns: Array of PathResult for all explorations
    public func batchExplore(explorations: [(nodeId: Int, paths: [String])], sourceGraph: Graph) -> [PathResult] {
        var allResults: [PathResult] = []
        
        for (nodeId, paths) in explorations {
            guard let node = sourceGraph.getNode(nodeId) else { continue }
            
            let results = explorePathsFromNode(node: node, paths: paths, sourceGraph: sourceGraph)
            allResults.append(contentsOf: results)
        }
        
        return allResults
    }
}