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
    /// Execute exploration from the starting node for multiple paths
    /// This reflects the reality that we can only explore from the start in the API
    /// - Parameters:
    ///   - paths: Array of paths to explore from the starting node
    ///   - sourceGraph: The graph to explore
    /// - Returns: Array of PathResult for each exploration
    public func exploreFromStart(paths: [String], sourceGraph: Graph) -> [PathResult] {
        var results: [PathResult] = []
        let startNodeId = sourceGraph.startingNodeId
        
        for path in paths {
            // Use existing explorePath method to get labels
            let labels = explorePath(sourceGraph: sourceGraph, path: path)
            
            let result = PathResult(
                startNodeId: startNodeId,
                path: path,
                observedLabels: labels
            )
            results.append(result)
        }
        
        return results
    }
    
    /// Legacy method - kept for compatibility but should be phased out
    /// In reality, we can only explore from the starting node
    /// - Parameters:
    ///   - node: The node to explore from (must be the starting node)
    ///   - paths: Array of paths to explore
    ///   - sourceGraph: The graph to explore
    /// - Returns: Array of PathResult for each exploration
    public func explorePathsFromNode(node: Node, paths: [String], sourceGraph: Graph) -> [PathResult] {
        // In reality, we can only explore from the starting node
        // This method is kept for compatibility but just delegates to exploreFromStart
        if node.id != sourceGraph.startingNodeId {
            // In a real scenario, we can't explore from arbitrary nodes
            // Return empty results for non-starting nodes
            return []
        }
        
        return exploreFromStart(paths: paths, sourceGraph: sourceGraph)
    }
    
    /// Execute multiple explorations efficiently
    /// Note: All explorations must be from the starting node
    /// - Parameters:
    ///   - explorations: Array of tuples containing (NodeId, [paths to explore])
    ///   - sourceGraph: The graph to explore
    /// - Returns: Array of PathResult for all explorations
    public func batchExplore(explorations: [(nodeId: Int, paths: [String])], sourceGraph: Graph) -> [PathResult] {
        var allResults: [PathResult] = []
        
        for (nodeId, paths) in explorations {
            // We can only explore from the starting node
            if nodeId == sourceGraph.startingNodeId {
                let results = exploreFromStart(paths: paths, sourceGraph: sourceGraph)
                allResults.append(contentsOf: results)
            }
            // Ignore requests to explore from other nodes
        }
        
        return allResults
    }
}