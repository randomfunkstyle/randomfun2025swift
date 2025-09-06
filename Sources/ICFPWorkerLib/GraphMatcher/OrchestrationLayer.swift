import Foundation

/// Represents the current state of exploration
public struct ExplorationState {
    public let uniqueRooms: Int
    public let expectedRooms: Int
    public let explorationDepth: Int
    public let queryCount: Int
    public let maxQueries: Int
    public let maxDepth: Int
    
    public init(uniqueRooms: Int, expectedRooms: Int, explorationDepth: Int,
                queryCount: Int, maxQueries: Int = 100, maxDepth: Int = 3) {
        self.uniqueRooms = uniqueRooms
        self.expectedRooms = expectedRooms
        self.explorationDepth = explorationDepth
        self.queryCount = queryCount
        self.maxQueries = maxQueries
        self.maxDepth = maxDepth
    }
}

/// Decision about whether to continue exploration
public enum Decision {
    case `continue`(reason: String)
    case stop(reason: String)
    case error(String)
}

extension GraphMatcher {
    
    /// Decide whether to continue exploring based on current state
    /// - Parameter state: Current exploration state
    /// - Returns: Decision about whether to continue, stop, or error
    public func shouldContinueExploration(state: ExplorationState) -> Decision {
        // Check for invalid state
        if state.expectedRooms <= 0 {
            return .error("Invalid expected room count: \(state.expectedRooms)")
        }
        
        if state.uniqueRooms < 0 || state.queryCount < 0 || state.explorationDepth < 0 {
            return .error("Invalid state with negative values")
        }
        
        // Check if we've found EXACTLY the right number of rooms
        if state.uniqueRooms == state.expectedRooms {
            return .stop(reason: "Found exactly \(state.expectedRooms) expected rooms")
        }
        
        // If we have too many unique rooms, we need to continue exploring to merge them
        if state.uniqueRooms > state.expectedRooms {
            // Don't stop - we need more exploration to disambiguate
            let excessRooms = state.uniqueRooms - state.expectedRooms
            return .continue(reason: "Found \(state.uniqueRooms) signatures, need to merge \(excessRooms) duplicates")
        }
        
        // Check if we've hit query limit
        if state.queryCount >= state.maxQueries {
            return .stop(reason: "Reached maximum query limit of \(state.maxQueries)")
        }
        
        // Check if we've hit depth limit
        if state.explorationDepth >= state.maxDepth {
            return .stop(reason: "Reached maximum exploration depth of \(state.maxDepth)")
        }
        
        // Continue exploring with appropriate reason
        let roomsRemaining = state.expectedRooms - state.uniqueRooms
        let queriesRemaining = state.maxQueries - state.queryCount
        
        if roomsRemaining == 1 {
            return .continue(reason: "Need to find 1 more room, \(queriesRemaining) queries remaining")
        } else {
            return .continue(reason: "Need to find \(roomsRemaining) more rooms, \(queriesRemaining) queries remaining")
        }
    }
    
    /// Select next explorations based on current state and priority groups
    /// - Parameters:
    ///   - state: Current exploration state
    ///   - graph: Current built graph
    ///   - labelGroups: Priority groups of nodes by label
    ///   - exploredPaths: Set of paths already explored from start
    /// - Returns: Array of paths to explore next (all from starting node)
    public func selectNextExplorations(
        state: ExplorationState,
        graph: Graph,
        labelGroups: [PriorityGroup],
        exploredPaths: Set<String> = [],
        duplicateGroups: [[Int]] = []
    ) -> [String] {
        
        var nextPaths: [String] = []
        
        // If we've found exactly the right number of rooms, no more exploration needed
        if state.uniqueRooms == state.expectedRooms {
            return []
        }
        
        // Calculate how many queries we can afford
        let queriesRemaining = state.maxQueries - state.queryCount
        if queriesRemaining <= 0 {
            return []
        }
        
        // Special handling when we have too many signatures (need to merge duplicates)
        if state.uniqueRooms > state.expectedRooms && !duplicateGroups.isEmpty {
            // We have duplicate signatures that need to be disambiguated
            // Focus on exploring deeper from positions that lead to ambiguous nodes
            
            // Find which paths lead to nodes with duplicate signatures
            var ambiguousPositions = Set<String>()
            
            for group in duplicateGroups where group.count > 1 {
                // These nodes have the same signature and need disambiguation
                // Find paths that lead to these nodes from the starting position
                for nodeId in group {
                    // Find the shortest path from start to this node
                    for path in exploredPaths {
                        // Check if this path leads to the node
                        var currentId = graph.startingNodeId
                        var pathToNode = ""
                        
                        for char in path {
                            guard let door = Int(String(char)) else { break }
                            if let node = graph.getNode(currentId),
                               let connection = node.doors[door],
                               let (nextId, _) = connection {
                                pathToNode.append(char)
                                currentId = nextId
                                
                                if currentId == nodeId {
                                    // Found a path to this ambiguous node
                                    ambiguousPositions.insert(pathToNode)
                                    break
                                }
                            } else {
                                break
                            }
                        }
                    }
                }
            }
            
            // If we found ambiguous positions, explore deeper from them
            if !ambiguousPositions.isEmpty {
                print("Found \(ambiguousPositions.count) ambiguous positions: \(Array(ambiguousPositions).prefix(5))")
                
                // Generate deeper paths from ambiguous positions
                for position in ambiguousPositions.prefix(6) { // Limit to avoid explosion
                    for door in 0..<6 {
                        let deeperPath = position + String(door)
                        if !exploredPaths.contains(deeperPath) {
                            nextPaths.append(deeperPath)
                            if nextPaths.count >= 12 {
                                return nextPaths
                            }
                        }
                    }
                }
            } else {
                // No ambiguous positions found, try exploring at next depth level
                print("No ambiguous positions found, trying depth \(state.explorationDepth + 1)")
                let nextDepth = state.explorationDepth + 1
                let deeperPaths = generatePaths(depth: nextDepth)
                    .filter { !exploredPaths.contains($0) }
                    .prefix(12)
                return Array(deeperPaths)
            }
            
            if !nextPaths.isEmpty {
                return nextPaths
            }
        }
        
        // Fall back to standard depth-based exploration
        let nextDepth = determineNextDepth(state: state)
        let candidatePaths = generatePaths(depth: nextDepth)
        let newPaths = candidatePaths.filter { !exploredPaths.contains($0) }
        
        // Prioritize paths based on label groups
        let prioritizedPaths = prioritizePaths(
            paths: newPaths,
            labelGroups: labelGroups,
            graph: graph
        )
        
        // Select paths within query budget
        let maxQueriesToUse = min(queriesRemaining, 12)
        nextPaths = Array(prioritizedPaths.prefix(maxQueriesToUse))
        
        return nextPaths
    }
    
    /// Determine the appropriate depth for next exploration
    private func determineNextDepth(state: ExplorationState) -> Int {
        // If we're making good progress, stay at current depth
        let progressRatio = Double(state.uniqueRooms) / Double(state.expectedRooms)
        
        // CRITICAL: If we have MORE unique rooms than expected, we need deeper exploration to merge them
        if state.uniqueRooms > state.expectedRooms {
            // We have too many signatures - need to explore deeper to find connections
            return min(state.explorationDepth + 1, state.maxDepth)
        }
        
        if progressRatio < 0.5 && state.explorationDepth == 1 {
            // Not much progress with depth 1, try depth 2
            return 2
        } else if progressRatio < 0.8 && state.explorationDepth == 2 {
            // Still need more distinction, try depth 3
            return min(3, state.maxDepth)
        } else if state.explorationDepth == 0 {
            // Start with depth 1
            return 1
        }
        
        // Otherwise, incrementally increase depth if not at max
        return min(state.explorationDepth + 1, state.maxDepth)
    }
    
    /// Prioritize paths based on label groups and graph structure
    private func prioritizePaths(
        paths: [String],
        labelGroups: [PriorityGroup],
        graph: Graph
    ) -> [String] {
        
        // If no priority groups, return paths as-is
        if labelGroups.isEmpty {
            return paths
        }
        
        // Score each path based on potential information gain
        var scoredPaths: [(path: String, score: Int)] = []
        
        for path in paths {
            var score = 0
            
            // Prefer shorter paths initially (less costly)
            score += (4 - path.count) * 10
            
            // Prefer paths that explore high-priority doors
            if let firstDoor = path.first {
                // Paths starting with door 5 often lead to different rooms
                if firstDoor == "5" {
                    score += 20
                }
                // Identity patterns (00, 11, etc.) can reveal structure
                if path.count == 2 && path.first == path.last {
                    score += 15
                }
            }
            
            // Add variety - prefer different starting doors
            let startingDoors = Set(paths.compactMap { $0.first })
            if startingDoors.count < 6 {
                // Encourage exploration of unused doors
                if let firstDoor = path.first, !paths.contains(where: { $0.first == firstDoor }) {
                    score += 25
                }
            }
            
            scoredPaths.append((path: path, score: score))
        }
        
        // Sort by score (highest first) and return paths
        scoredPaths.sort { $0.score > $1.score }
        return scoredPaths.map { $0.path }
    }
}