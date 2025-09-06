import Foundation

extension GraphMatcher {
    /// Build graph from all exploration results at once
    /// This ensures all connections are properly added
    public func buildCompleteGraph(from results: [PathResult]) -> Graph {
        // Start with a graph with the starting node
        guard let firstResult = results.first,
              let startingLabel = firstResult.observedLabels.first else {
            return Graph(startingLabel: .A)
        }
        
        let graph = Graph(startingLabel: startingLabel)
        
        // Track which node ID corresponds to each path
        var pathToNodeId: [String: Int] = ["": graph.startingNodeId]
        
        
        // First pass: Create all nodes
        for result in results {
            var currentPath = ""
            var currentNodeId = graph.startingNodeId
            
            // Skip if labels don't match expected count
            guard result.observedLabels.count == result.path.count + 1 else { continue }
            
            for (index, doorChar) in result.path.enumerated() {
                guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
                
                currentPath.append(doorChar)
                
                // Check if we already created a node for this path
                if let existingNodeId = pathToNodeId[currentPath] {
                    currentNodeId = existingNodeId
                } else {
                    // Create new node
                    let nextLabel = result.observedLabels[index + 1]
                    let nextNodeId = graph.addNode(label: nextLabel)
                    pathToNodeId[currentPath] = nextNodeId
                    currentNodeId = nextNodeId
                    
                    if pathToNodeId.count <= 10 {
                        print("  Created node \(nextNodeId) at path '\(currentPath)' with label \(nextLabel)")
                    }
                }
            }
        }
        
        // Second pass: Add all connections
        // This ensures nodes at depth 1 get all their doors defined
        var connectionCount = 0
        for result in results {
            if result.path.isEmpty { continue }
            
            // For each position in the path, ensure the connection exists
            var currentPath = ""
            
            for (index, doorChar) in result.path.enumerated() {
                guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
                
                let fromPath = currentPath
                currentPath.append(doorChar)
                let toPath = currentPath
                
                if let fromNodeId = pathToNodeId[fromPath],
                   let toNodeId = pathToNodeId[toPath] {
                    
                    // Add connection - always add since we're building from scratch
                    graph.addOneWayConnection(
                        fromNodeId: fromNodeId,
                        fromDoor: door,
                        toNodeId: toNodeId
                    )
                    connectionCount += 1
                    if connectionCount <= 10 {
                        print("  Added connection: Node \(fromNodeId) --\(door)--> Node \(toNodeId) (path '\(fromPath)' --\(door)--> '\(toPath)')")
                    }
                } else {
                    if connectionCount == 0 && index == 0 {
                        print("  Could not find nodes for paths: '\(fromPath)' -> '\(toPath)'")
                    }
                }
            }
        }
        
        print("BuildCompleteGraph: Created \(pathToNodeId.count) nodes and \(connectionCount) connections from \(results.count) explorations")
        
        return graph
    }
    
    /// Improved merge that builds complete graph from all results
    public func mergeAllExplorations(existingResults: [PathResult], newResults: [PathResult]) -> Graph {
        // Combine all results and build complete graph
        let allResults = existingResults + newResults
        return buildCompleteGraph(from: allResults)
    }
}