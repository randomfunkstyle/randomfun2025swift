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
            
            // Process each state in the path
            var currentPath = ""
            for (index, label) in labels.enumerated() {
                stateLabels[currentPath] = label
                
                // Add transition if not at end
                if index < path.count {
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
        
        // Step 3: Find ALL bidirectional connections from return paths
        for path in exploredPaths where path.count == 2 {
            let labels = getLabelsForPath(path)
            if labels.count == 3 && labels[0] == labels[2] {
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