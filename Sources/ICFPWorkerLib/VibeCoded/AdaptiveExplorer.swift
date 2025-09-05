import Foundation

/// Adaptive explorer that generates paths based on accumulated knowledge
/// Uses multiple explorations efficiently to disambiguate connections
public class AdaptiveExplorer {
    private let roomCount: Int
    private let maxPathLength: Int
    private var explorationCount = 0
    private let stateAnalyzer = StateTransitionAnalyzer()
    
    // Track what we've learned
    private var knownStates: Set<String> = [""]  // Starting state
    private var uncertainTransitions: [(state: String, door: Int)] = []
    private var connectionHypotheses: [ConnectionHypothesis] = []
    
    public struct ConnectionHypothesis {
        let fromRoom: Int
        let fromDoor: Int
        let toRoom: Int
        let toDoor: Int?  // Unknown initially
        var confidence: Double
    }
    
    public init(roomCount: Int) {
        self.roomCount = roomCount
        self.maxPathLength = 18 * roomCount
    }
    
    /// Generate first exploration path using entropy-optimal pattern
    public func generateFirstPath() -> String {
        explorationCount = 0
        
        // Pattern "001122334455..." tests return pairs efficiently
        var path = ""
        
        // Test all door pairs for returns
        for door in 0..<6 {
            path += String(door) + String(door)
            if path.count >= maxPathLength {
                return String(path.prefix(maxPathLength))
            }
        }
        
        // Then systematic exploration
        while path.count < maxPathLength {
            for door in 0..<6 {
                path += String(door)
                if path.count >= maxPathLength {
                    return String(path.prefix(maxPathLength))
                }
            }
        }
        
        return path
    }
    
    /// Generate next path based on what we've learned
    public func generateAdaptivePath() -> String {
        explorationCount += 1
        
        // Strategy depends on what we need to learn
        if explorationCount == 1 {
            // Second exploration: Test unmapped connections specifically
            return generateTargetedTestPath()
        } else if !uncertainTransitions.isEmpty {
            // Target uncertain transitions
            return generateDisambiguationPath()
        } else {
            // Explore unreached states
            return generateExplorationPath()
        }
    }
    
    /// Generate targeted test path for unmapped connections
    private func generateTargetedTestPath() -> String {
        var path = ""
        let rooms = stateAnalyzer.identifyRooms()
        
        // Find completely unmapped doors (no connection at all)
        var unmappedDoors: [(roomId: Int, door: Int)] = []
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] == nil {
                    unmappedDoors.append((room.id, door))
                }
            }
        }
        
        // If we have unmapped doors, focus on those
        if !unmappedDoors.isEmpty {
            // Try to reach each unmapped door and test it
            for (roomId, door) in unmappedDoors {
                if roomId == 0 {
                    // Start room - just test the door
                    path += String(door)
                    // Then try all doors to find connections
                    for testDoor in 0..<6 {
                        path += String(testDoor)
                        if path.count >= maxPathLength {
                            return String(path.prefix(maxPathLength))
                        }
                    }
                } else {
                    // Need to reach this room first
                    // Find shortest known path to this room
                    if let pathToRoom = findShortestPathToRoom(targetRoomId: roomId, rooms: rooms) {
                        path += pathToRoom
                        // Test the unmapped door
                        path += String(door)
                        // Try all return doors
                        for testDoor in 0..<6 {
                            path += String(testDoor)
                            if path.count >= maxPathLength {
                                return String(path.prefix(maxPathLength))
                            }
                        }
                    }
                }
            }
        }
        
        // Otherwise look for doors with unknown return paths
        var partiallyMappedDoors: [(roomId: Int, door: Int)] = []
        for room in rooms {
            for door in 0..<6 {
                if let conn = room.doors[door], conn?.toDoor == nil {
                    partiallyMappedDoors.append((room.id, door))
                }
            }
        }
        
        // Test partially mapped connections
        for (roomId, door) in partiallyMappedDoors {
            if roomId == 0 {
                path += String(door)
                for testDoor in 0..<6 {
                    path += String(testDoor)
                    if path.count >= maxPathLength {
                        return String(path.prefix(maxPathLength))
                    }
                }
            }
        }
        
        // Fill rest with exploration
        while path.count < maxPathLength {
            path += String(Int.random(in: 0..<6))
        }
        
        return String(path.prefix(maxPathLength))
    }
    
    /// Find shortest path to a target room
    private func findShortestPathToRoom(targetRoomId: Int, rooms: [StateTransitionAnalyzer.Room]) -> String? {
        // Simple BFS to find shortest path
        if targetRoomId == 0 { return "" }
        
        // Check direct connections from start
        if let startRoom = rooms.first(where: { $0.id == 0 }) {
            for (door, conn) in startRoom.doors {
                if let c = conn, c.toRoomId == targetRoomId {
                    return String(door)
                }
            }
        }
        
        // For now, return nil if not directly connected
        // In a full implementation, we'd do proper BFS
        return nil
    }
    
    /// Test asymmetric door combinations
    private func generateAsymmetricTestPath() -> String {
        var path = ""
        
        // Pattern "0102030405..." tests which door from state "0" returns
        for firstDoor in 0..<6 {
            for secondDoor in 0..<6 {
                if firstDoor != secondDoor {
                    path += String(firstDoor) + String(secondDoor)
                    if path.count >= maxPathLength {
                        return String(path.prefix(maxPathLength))
                    }
                }
            }
        }
        
        return path
    }
    
    /// Generate path to disambiguate uncertain transitions
    private func generateDisambiguationPath() -> String {
        var path = ""
        
        // Try to reach uncertain states and test their transitions
        for (state, door) in uncertainTransitions.prefix(10) {
            // First, try to reach this state
            if let pathToState = findPathToState(state) {
                path += pathToState
                // Then test the uncertain door
                path += String(door)
                
                if path.count >= maxPathLength {
                    return String(path.prefix(maxPathLength))
                }
            }
        }
        
        // Fill remaining with exploration
        while path.count < maxPathLength {
            path += String(Int.random(in: 0..<6))
        }
        
        return String(path.prefix(maxPathLength))
    }
    
    /// Generate path to explore new areas
    private func generateExplorationPath() -> String {
        var path = ""
        
        // Use different patterns to reach new states
        // Fibonacci sequence for non-repetitive exploration
        var fib1 = 1, fib2 = 1
        while path.count < maxPathLength {
            let door = (fib1 + fib2) % 6
            path += String(door)
            let next = fib1 + fib2
            fib1 = fib2
            fib2 = next
        }
        
        return String(path.prefix(maxPathLength))
    }
    
    /// Find a path from start to a given state
    private func findPathToState(_ targetState: String) -> String? {
        // For now, just return the state itself if it's a path from start
        // In a full implementation, we'd do BFS through known states
        if targetState.allSatisfy({ "012345".contains($0) }) {
            return targetState
        }
        return nil
    }
    
    /// Process exploration results and update knowledge
    public func processExploration(path: String, labels: [Int]) {
        stateAnalyzer.processExplorations(paths: [path], results: [labels])
        
        // Update known states
        var currentState = ""
        for char in path {
            knownStates.insert(currentState)
            currentState += String(char)
        }
        
        // Find uncertain transitions
        updateUncertainTransitions()
        
        // Generate/update hypotheses
        updateConnectionHypotheses(path: path, labels: labels)
    }
    
    /// Identify transitions we're uncertain about
    private func updateUncertainTransitions() {
        uncertainTransitions.removeAll()
        
        let rooms = stateAnalyzer.identifyRooms()
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] == nil {
                    // Find states that lead to this room
                    for state in knownStates {
                        // This is simplified - would need proper state tracking
                        uncertainTransitions.append((state: state, door: door))
                    }
                }
            }
        }
    }
    
    /// Update connection hypotheses based on observations
    private func updateConnectionHypotheses(path: String, labels: [Int]) {
        // Look for return patterns
        let returnPairs = stateAnalyzer.findReturnPairs(in: path, with: labels)
        
        for pair in returnPairs {
            // Generate hypothesis: these doors might be connected
            let hypothesis = ConnectionHypothesis(
                fromRoom: pair.startLabel,
                fromDoor: pair.door1,
                toRoom: pair.startLabel == 0 ? 1 : 0,  // Assumes 2 rooms for now
                toDoor: pair.door2,
                confidence: 0.5  // Initial confidence
            )
            connectionHypotheses.append(hypothesis)
        }
        
        // Increase confidence for consistent hypotheses
        consolidateHypotheses()
    }
    
    /// Consolidate and increase confidence in consistent hypotheses
    private func consolidateHypotheses() {
        // Group similar hypotheses and increase confidence
        var consolidatedMap: [String: [ConnectionHypothesis]] = [:]
        
        for hyp in connectionHypotheses {
            let key = "\(hyp.fromRoom):\(hyp.fromDoor)->\(hyp.toRoom)"
            consolidatedMap[key, default: []].append(hyp)
        }
        
        // If we see the same hypothesis multiple times, increase confidence
        connectionHypotheses.removeAll()
        for (_, group) in consolidatedMap {
            if group.count > 1 {
                // Multiple observations support this hypothesis
                var bestHyp = group[0]
                bestHyp.confidence = min(1.0, 0.3 * Double(group.count))
                connectionHypotheses.append(bestHyp)
            } else {
                connectionHypotheses.append(group[0])
            }
        }
    }
    
    /// Check if we have enough information to map the graph
    public func isComplete() -> Bool {
        let rooms = stateAnalyzer.identifyRooms()
        
        // Check if we have the expected number of rooms
        guard rooms.count == roomCount else {
            return false
        }
        
        // Check if all connections are mapped
        return stateAnalyzer.isComplete()
    }
    
    /// Get the current state analyzer
    public func getStateAnalyzer() -> StateTransitionAnalyzer {
        return stateAnalyzer
    }
    
    /// Get current hypotheses
    public func getHypotheses() -> [ConnectionHypothesis] {
        return connectionHypotheses.sorted { $0.confidence > $1.confidence }
    }
    
    /// Get statistics about current knowledge
    public func getStatistics() -> (rooms: Int, mappedConnections: Int, hypotheses: Int) {
        let rooms = stateAnalyzer.identifyRooms()
        var mappedConnections = 0
        
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] != nil {
                    mappedConnections += 1
                }
            }
        }
        
        return (rooms: rooms.count, mappedConnections: mappedConnections, hypotheses: connectionHypotheses.count)
    }
}