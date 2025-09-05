import Foundation

/// Analyzes state transitions to identify distinct rooms in the graph
/// Uses reachability analysis instead of partial signatures
public class StateTransitionAnalyzer {
    
    /// Represents a state in our exploration (a position in the graph)
    public struct State: Hashable {
        public let path: String  // Sequence of doors taken from start
        public let label: Int    // Label observed at this state
        
        public init(path: String, label: Int) {
            self.path = path
            self.label = label
        }
    }
    
    /// A transition from one state to another via a door
    public struct Transition: Hashable {
        public let fromState: String
        public let door: Int
        public let toState: String
        public let toLabel: Int
    }
    
    /// Represents a distinct room in the graph
    public struct Room {
        public let id: Int
        public let label: Int
        public let states: Set<String>  // All states (paths) that reach this room
        public var doors: [Int: (toRoomId: Int, toDoor: Int?)?] = [:]
        
        public init(id: Int, label: Int, states: Set<String> = []) {
            self.id = id
            self.label = label
            self.states = states
            // Initialize all 6 doors
            for door in 0..<6 {
                doors[door] = nil
            }
        }
    }
    
    private var stateLabels: [String: Int] = [:]
    private var transitions: [Transition] = []
    private var exploredPaths: Set<String> = []
    
    /// Process exploration results to build state transition table
    public func processExplorations(paths: [String], results: [[Int]]) {
        for (path, labels) in zip(paths, results) {
            exploredPaths.insert(path)
            
            // For special pattern analysis - detect if this is a return-pair pattern
            if path.hasPrefix("001122334455") {
                processReturnPairPattern(path: path, labels: labels)
            } else {
                processGeneralPath(path: path, labels: labels)
            }
        }
    }
    
    /// Process the return-pair pattern specially
    private func processReturnPairPattern(path: String, labels: [Int]) {
        // Process each pair separately since they return to start
        var pairStart = 0
        
        while pairStart < path.count - 1 {
            let doorIndex1 = path.index(path.startIndex, offsetBy: pairStart)
            let doorIndex2 = path.index(path.startIndex, offsetBy: pairStart + 1)
            
            if path[doorIndex1] == path[doorIndex2] && pairStart + 2 < labels.count {
                // This is a return pair like "00", "11", etc.
                if let door = Int(String(path[doorIndex1])) {
                    let startLabel = labels[pairStart]
                    let midLabel = labels[pairStart + 1]
                    let endLabel = labels[pairStart + 2]
                    
                    if startLabel == endLabel && startLabel != midLabel {
                        // This is a confirmed return - we're back at start
                        stateLabels[""] = startLabel
                        stateLabels[String(door)] = midLabel
                        
                        transitions.append(Transition(
                            fromState: "",
                            door: door,
                            toState: String(door),
                            toLabel: midLabel
                        ))
                        
                        // The return transition
                        transitions.append(Transition(
                            fromState: String(door),
                            door: door,
                            toState: "",  // Back to start!
                            toLabel: startLabel
                        ))
                    }
                }
                pairStart += 2
            } else {
                pairStart += 1
            }
        }
        
        // Also process it as a general path for additional information
        processGeneralPath(path: path, labels: labels)
    }
    
    /// Process a general path
    private func processGeneralPath(path: String, labels: [Int]) {
        var currentPath = ""
        for (index, label) in labels.enumerated() {
            stateLabels[currentPath] = label
            
            // Add transition if not at end
            if index < path.count && index + 1 < labels.count {
                let doorChar = path[path.index(path.startIndex, offsetBy: index)]
                if let door = Int(String(doorChar)) {
                    let nextPath = currentPath + String(door)
                    let nextLabel = labels[index + 1]
                    
                    transitions.append(Transition(
                        fromState: currentPath,
                        door: door,
                        toState: nextPath,
                        toLabel: nextLabel
                    ))
                    
                    currentPath = nextPath
                }
            }
        }
    }
    
    /// Identify distinct rooms using simple label-based approach
    public func identifyRooms() -> [Room] {
        guard let startLabel = stateLabels[""] else { return [] }
        
        // Map unique labels to room IDs
        let uniqueLabels = Set(stateLabels.values).sorted()
        var labelToRoomId: [Int: Int] = [:]
        var rooms: [Room] = []
        
        // Create one room per unique label
        for label in uniqueLabels {
            labelToRoomId[label] = label  // Use label as room ID
            let states = stateLabels.compactMap { (state, stateLabel) in
                stateLabel == label ? state : nil
            }
            let room = Room(id: label, label: label, states: Set(states))
            rooms.append(room)
        }
        
        // Step 1: Map ALL transitions to room connections
        for transition in transitions {
            let fromLabel = stateLabels[transition.fromState] ?? startLabel
            let toLabel = transition.toLabel
            
            guard let fromRoomId = labelToRoomId[fromLabel],
                  let toRoomId = labelToRoomId[toLabel] else { continue }
            
            // Store this connection (may override previous)
            if transition.fromState == "" || rooms[fromRoomId].doors[transition.door] == nil {
                rooms[fromRoomId].doors[transition.door] = (toRoomId: toRoomId, toDoor: nil)
            }
        }
        
        // Step 2: Identify self-loops from single-door explorations
        for path in exploredPaths where path.count == 1 {
            let labels = getLabelsForPath(path)
            if labels.count == 2 && labels[0] == labels[1] {
                // Self-loop detected
                if let door = Int(path),
                   let roomId = labelToRoomId[labels[0]] {
                    rooms[roomId].doors[door] = (toRoomId: roomId, toDoor: door)
                }
            }
        }
        
        // Step 3: Find ALL bidirectional connections from transitions
        // Look for transitions that form cycles back to start
        for trans in transitions {
            if trans.toState == "" && trans.fromState.count == 1 {
                // This is a return to start from a single-door state
                if let door1 = Int(trans.fromState), // The door we took to get to this state
                   let room0Id = labelToRoomId[startLabel],
                   let room1Label = stateLabels[trans.fromState],
                   let room1Id = labelToRoomId[room1Label] {
                    let door2 = trans.door  // The door that returns us
                    // We found: start --door1--> state --door2--> start
                    // This means room0:door1 connects to room1:door2
                    rooms[room0Id].doors[door1] = (toRoomId: room1Id, toDoor: door2)
                    rooms[room1Id].doors[door2] = (toRoomId: room0Id, toDoor: door1)
                }
            }
        }
        
        // Also check exploredPaths for 2-char return paths
        for path in exploredPaths where path.count == 2 {
            let labels = getLabelsForPath(path)
            if labels.count == 3 && labels[0] == labels[2] && labels[0] != labels[1] {
                // This is a return path: A -> B -> A
                let door1Char = path[path.index(path.startIndex, offsetBy: 0)]
                let door2Char = path[path.index(path.startIndex, offsetBy: 1)]
                
                if let door1 = Int(String(door1Char)),
                   let door2 = Int(String(door2Char)),
                   let room0Id = labelToRoomId[labels[0]],
                   let room1Id = labelToRoomId[labels[1]] {
                    // Door1 from room0 goes to room1, door2 returns
                    rooms[room0Id].doors[door1] = (toRoomId: room1Id, toDoor: door2)
                    rooms[room1Id].doors[door2] = (toRoomId: room0Id, toDoor: door1)
                }
            }
        }
        
        // Step 4: Process 3-door paths for additional connections
        for path in exploredPaths where path.count == 3 {
            let labels = getLabelsForPath(path)
            if labels.count == 4 {
                for i in 0..<3 {
                    let doorChar = path[path.index(path.startIndex, offsetBy: i)]
                    if let door = Int(String(doorChar)),
                       let fromRoomId = labelToRoomId[labels[i]],
                       let toRoomId = labelToRoomId[labels[i+1]] {
                        // Add connection if not already mapped
                        if rooms[fromRoomId].doors[door] == nil {
                            rooms[fromRoomId].doors[door] = (toRoomId: toRoomId, toDoor: nil)
                        }
                    }
                }
            }
        }
        
        // Step 5: Infer bidirectional door mappings
        // If A:x -> B and B:y -> A, then A:x <-> B:y
        for (roomId, room) in rooms.enumerated() {
            for (door, connection) in room.doors {
                if let conn = connection, conn.toDoor == nil {
                    // We know A:door -> B but not which door on B
                    let targetRoomId = conn.toRoomId
                    
                    // Check if B has a connection back to A
                    for (targetDoor, targetConn) in rooms[targetRoomId].doors {
                        if let tConn = targetConn, 
                           tConn.toRoomId == roomId && 
                           (tConn.toDoor == nil || tConn.toDoor == door) {
                            // Found bidirectional connection
                            rooms[roomId].doors[door] = (toRoomId: targetRoomId, toDoor: targetDoor)
                            rooms[targetRoomId].doors[targetDoor] = (toRoomId: roomId, toDoor: door)
                        }
                    }
                }
            }
        }
        
        return rooms
    }
    
    /// Get labels for a given path
    private func getLabelsForPath(_ path: String) -> [Int] {
        var labels: [Int] = []
        var currentPath = ""
        
        // Starting label
        if let startLabel = stateLabels[""] {
            labels.append(startLabel)
        }
        
        // Label at each step
        for char in path {
            currentPath += String(char)
            if let label = stateLabels[currentPath] {
                labels.append(label)
            }
        }
        
        return labels
    }
    
    /// Helper to get all exploration results
    private func allExplorationResults() -> [[Int]] {
        var results: [[Int]] = []
        for path in exploredPaths {
            var labels: [Int] = []
            var currentPath = ""
            
            // Add starting label
            if let startLabel = stateLabels[""] {
                labels.append(startLabel)
            }
            
            // Add labels for each step
            for char in path {
                currentPath += String(char)
                if let label = stateLabels[currentPath] {
                    labels.append(label)
                }
            }
            
            results.append(labels)
        }
        return results
    }
    
    /// Find connected components using DFS
    private func findConnectedComponents(stateGraph: [String: [(door: Int, toState: String)]]) -> [Set<String>] {
        var visited: Set<String> = []
        var components: [Set<String>] = []
        
        for state in stateLabels.keys {
            if !visited.contains(state) {
                var component: Set<String> = []
                dfs(state: state, graph: stateGraph, visited: &visited, component: &component)
                if !component.isEmpty {
                    components.append(component)
                }
            }
        }
        
        // Merge components that are connected
        var merged = true
        while merged {
            merged = false
            for i in 0..<components.count {
                for j in (i+1)..<components.count {
                    // Check if these components are connected
                    var connected = false
                    for state1 in components[i] {
                        for state2 in components[j] {
                            if areStatesConnected(state1, state2) {
                                connected = true
                                break
                            }
                        }
                        if connected { break }
                    }
                    
                    if connected {
                        // Merge components
                        components[i].formUnion(components[j])
                        components.remove(at: j)
                        merged = true
                        break
                    }
                }
                if merged { break }
            }
        }
        
        return components
    }
    
    /// Check if two states are connected (same room)
    private func areStatesConnected(_ state1: String, _ state2: String) -> Bool {
        // Two states are the same room if:
        // 1. They have the same label
        // 2. One can transition to the other
        
        guard let label1 = stateLabels[state1],
              let label2 = stateLabels[state2] else { return false }
        
        if label1 != label2 { return false }
        
        // Check if there's a transition between them
        for transition in transitions {
            if (transition.fromState == state1 && transition.toState == state2) ||
               (transition.fromState == state2 && transition.toState == state1) {
                return true
            }
        }
        
        // Check if they're reachable through same-label states
        // This is simplified - in practice we'd do full reachability
        return false
    }
    
    /// DFS helper for finding connected components
    private func dfs(state: String, graph: [String: [(door: Int, toState: String)]], visited: inout Set<String>, component: inout Set<String>) {
        visited.insert(state)
        component.insert(state)
        
        if let neighbors = graph[state] {
            for (_, nextState) in neighbors {
                if !visited.contains(nextState) {
                    // Only add to component if same label
                    if let currentLabel = stateLabels[state],
                       let nextLabel = stateLabels[nextState],
                       currentLabel == nextLabel {
                        dfs(state: nextState, graph: graph, visited: &visited, component: &component)
                    }
                }
            }
        }
    }
    
    /// Get room count estimate
    public func getRoomCount() -> Int {
        let rooms = identifyRooms()
        return rooms.count
    }
    
    /// Check if we have enough information
    public func isComplete() -> Bool {
        let rooms = identifyRooms()
        
        // Check if all doors are mapped
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] == nil {
                    return false
                }
            }
        }
        
        return !rooms.isEmpty
    }
    
    /// Find return pairs in path - patterns like "XY" where we return to original room
    /// These reveal bidirectional connections with high information gain
    public func findReturnPairs(in path: String, with labels: [Int]) -> [(door1: Int, door2: Int, startLabel: Int)] {
        var returnPairs: [(door1: Int, door2: Int, startLabel: Int)] = []
        
        // Look for 2-door sequences that return to start
        if path.count >= 2 && labels.count >= 3 {
            for i in 0..<(path.count - 1) {
                // Check if we have enough labels
                if i + 2 < labels.count {
                    let startLabel = labels[i]
                    let middleLabel = labels[i + 1]
                    let endLabel = labels[i + 2]
                    
                    // Check if this is a return path
                    if startLabel == endLabel && startLabel != middleLabel {
                        let door1Index = path.index(path.startIndex, offsetBy: i)
                        let door2Index = path.index(path.startIndex, offsetBy: i + 1)
                        
                        if let door1 = Int(String(path[door1Index])),
                           let door2 = Int(String(path[door2Index])) {
                            returnPairs.append((door1: door1, door2: door2, startLabel: startLabel))
                        }
                    }
                }
            }
        }
        
        return returnPairs
    }
    
    /// Extract maximum structural information from a single path
    public func extractStructuralInformation(from path: String, labels: [Int]) -> StructuralInfo {
        var info = StructuralInfo()
        
        // Find all return pairs (highest information value)
        let returnPairs = findReturnPairs(in: path, with: labels)
        info.bidirectionalConnections = returnPairs
        
        // Find cycles (sequences that return to same state)
        info.cycles = findCycles(in: path, with: labels)
        
        // Extract transition patterns
        info.transitionPatterns = extractTransitionPatterns(from: path, with: labels)
        
        // Calculate information gain
        info.informationBits = calculateInformationGain(returnPairs: returnPairs, cycles: info.cycles)
        
        return info
    }
    
    /// Find cycles in the path (subsequences that return to same label)
    private func findCycles(in path: String, with labels: [Int]) -> [(sequence: String, fromLabel: Int, length: Int)] {
        var cycles: [(sequence: String, fromLabel: Int, length: Int)] = []
        
        for startIdx in 0..<path.count {
            let startLabel = labels[startIdx]
            
            // Look for returns to same label
            for endIdx in (startIdx + 1)..<min(path.count, labels.count - 1) {
                if labels[endIdx + 1] == startLabel {
                    let startIndex = path.index(path.startIndex, offsetBy: startIdx)
                    let endIndex = path.index(path.startIndex, offsetBy: endIdx + 1)
                    let sequence = String(path[startIndex..<endIndex])
                    
                    cycles.append((sequence: sequence, fromLabel: startLabel, length: sequence.count))
                    
                    // Limit cycles to avoid too many overlapping ones
                    if cycles.count > 20 { break }
                }
            }
            if cycles.count > 20 { break }
        }
        
        return cycles
    }
    
    /// Extract transition patterns from the path
    private func extractTransitionPatterns(from path: String, with labels: [Int]) -> [String: Int] {
        var patterns: [String: Int] = [:]
        
        // Count 2-door and 3-door patterns
        for len in 2...3 {
            if path.count >= len {
                for i in 0...(path.count - len) {
                    let startIndex = path.index(path.startIndex, offsetBy: i)
                    let endIndex = path.index(path.startIndex, offsetBy: i + len)
                    let pattern = String(path[startIndex..<endIndex])
                    patterns[pattern, default: 0] += 1
                }
            }
        }
        
        return patterns
    }
    
    /// Calculate information gain in bits
    private func calculateInformationGain(returnPairs: [(door1: Int, door2: Int, startLabel: Int)], 
                                         cycles: [(sequence: String, fromLabel: Int, length: Int)]) -> Double {
        // Each return pair reveals ~4.6 bits about bidirectional connections
        let returnPairBits = Double(returnPairs.count) * 4.6
        
        // Each unique cycle reveals ~2 bits about structure
        let uniqueCycles = Set(cycles.map { $0.sequence })
        let cycleBits = Double(uniqueCycles.count) * 2.0
        
        return returnPairBits + cycleBits
    }
}

/// Structural information extracted from a path
public struct StructuralInfo {
    public var bidirectionalConnections: [(door1: Int, door2: Int, startLabel: Int)] = []
    public var cycles: [(sequence: String, fromLabel: Int, length: Int)] = []
    public var transitionPatterns: [String: Int] = [:]
    public var informationBits: Double = 0.0
    
    public init() {}
}

// Extension continues with existing methods  
extension StateTransitionAnalyzer {
    /// Generate suggested paths to explore
    public func getSuggestedPaths() -> [String] {
        var suggestions: [String] = []
        
        // Try all single-door paths first
        for door in 0..<6 {
            let path = String(door)
            if !exploredPaths.contains(path) {
                suggestions.append(path)
            }
        }
        
        // Try two-door return paths
        for door1 in 0..<6 {
            for door2 in 0..<6 {
                let path = "\(door1)\(door2)"
                if !exploredPaths.contains(path) && suggestions.count < 20 {
                    suggestions.append(path)
                }
            }
        }
        
        return suggestions
    }
}