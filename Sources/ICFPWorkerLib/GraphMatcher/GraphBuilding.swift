import Foundation

extension GraphMatcher {
    /// Add single exploration result to graph
    /// - Parameters:
    ///   - pathResult: The exploration result to add
    ///   - currentGraph: The current graph to update
    /// - Returns: New graph with the exploration result added (original unchanged)
    public func createNodeFromExploration(pathResult: PathResult, currentGraph: Graph) -> Graph {
        // For simplicity, we'll directly use the existing buildGraphFromExploration method
        // by converting the PathResult to the expected format
        
        // First, gather all existing explorations from the current graph
        // This is a simplified approach - in production we'd maintain exploration history
        var explorations: [(path: String, labels: [RoomLabel])] = []
        
        // Add the new exploration
        explorations.append((path: pathResult.path, labels: pathResult.observedLabels))
        
        // Build a new graph from scratch with all explorations
        // Note: This is inefficient but correct for our current implementation
        return buildGraphFromExploration(explorations: explorations, startingGraph: currentGraph)
    }
    
    /// Helper to build graph from explorations with existing graph as base
    private func buildGraphFromExploration(explorations: [(path: String, labels: [RoomLabel])], 
                                          startingGraph: Graph) -> Graph {
        // Start with a copy of the existing graph structure
        let startingLabel = startingGraph.getNode(startingGraph.startingNodeId)?.label ?? .A
        let graph = Graph(startingLabel: startingLabel)
        
        // Create a mapping from old node IDs to new ones
        var nodeIdMap: [Int: Int] = [:]
        nodeIdMap[startingGraph.startingNodeId] = graph.startingNodeId
        
        // Copy all existing nodes
        for node in startingGraph.getAllNodes() {
            if node.id != startingGraph.startingNodeId {
                let newNodeId = graph.addNode(label: node.label)
                nodeIdMap[node.id] = newNodeId
            }
        }
        
        // Copy all existing connections
        for node in startingGraph.getAllNodes() {
            for (door, connection) in node.doors {
                if let (toNodeId, _) = connection {
                    if let fromId = nodeIdMap[node.id],
                       let toId = nodeIdMap[toNodeId] {
                        graph.addOneWayConnection(fromNodeId: fromId, fromDoor: door, toNodeId: toId)
                    }
                }
            }
        }
        
        // Now add new explorations
        for (path, labels) in explorations {
            var currentNodeId = graph.startingNodeId
            
            // Skip if labels don't match path length + 1
            guard labels.count == path.count + 1 else { continue }
            
            // Process each door in the path
            for (index, doorChar) in path.enumerated() {
                guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
                
                // Check if we already know where this door leads
                if let currentNode = graph.getNode(currentNodeId),
                   let connection = currentNode.doors[door],
                   let (nextNodeId, _) = connection {
                    // Door already explored, just move there
                    currentNodeId = nextNodeId
                } else {
                    // Create new node for this unexplored door
                    let nextLabel = labels[index + 1]
                    let nextNodeId = graph.addNode(label: nextLabel)
                    
                    // Only add a one-way connection
                    graph.addOneWayConnection(fromNodeId: currentNodeId, fromDoor: door, toNodeId: nextNodeId)
                    
                    currentNodeId = nextNodeId
                }
            }
        }
        
        return graph
    }
    
    /// Merge multiple exploration results into graph
    /// - Parameters:
    ///   - results: Array of exploration results to merge
    ///   - graph: The current graph
    /// - Returns: New graph with all results merged (original unchanged)
    public func mergeExplorationResults(results: [PathResult], graph: Graph) -> Graph {
        var currentGraph = graph
        
        for result in results {
            currentGraph = createNodeFromExploration(pathResult: result, currentGraph: currentGraph)
        }
        
        return currentGraph
    }
}