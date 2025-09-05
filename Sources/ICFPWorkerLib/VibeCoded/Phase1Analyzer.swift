import Foundation

/// Analyzer for Phase 1: Comprehensive Initial Discovery
/// Designed to handle graphs with up to 30 rooms and only 4 possible labels
public class Phase1Analyzer {
    
    /// Unique signature for identifying rooms beyond just their label
    public struct RoomSignature: Hashable {
        public let label: Int
        public let selfLoopDoors: Set<Int>
        public let transitionDoors: Set<Int>
        public let neighborLabelCounts: [Int: Int]  // label -> count of neighbors with that label
        
        /// Create a hash for room identification
        public var identifier: String {
            let selfLoops = selfLoopDoors.sorted().map(String.init).joined()
            let transitions = transitionDoors.sorted().map(String.init).joined()
            let neighbors = neighborLabelCounts.sorted(by: { $0.key < $1.key })
                .map { "\($0.key):\($0.value)" }.joined(separator: ",")
            return "\(label)|S:\(selfLoops)|T:\(transitions)|N:[\(neighbors)]"
        }
    }
    
    /// Hypothesis about the graph structure
    public struct GraphHypothesis {
        public var roomSignatures: Set<RoomSignature> = []
        public let expectedRoomCount: Int  // Known from the task
        public var labelDistribution: [Int: Int] = [:]
        public var exploredPaths: Set<String> = []
        public var connectionConfidence: Double = 0.0
        
        public init(expectedRoomCount: Int) {
            self.expectedRoomCount = expectedRoomCount
        }
    }
    
    /// Room state during exploration
    private struct ExplorationState {
        let path: String
        let labels: [Int]
    }
    
    private var allExplorations: [ExplorationState] = []
    private var currentHypothesis: GraphHypothesis
    private let stateAnalyzer = StateTransitionAnalyzer()
    private let expectedRoomCount: Int
    private let smartPathGenerator: SmartPathGenerator
    
    /// Initialize with known room count from the task
    public init(roomCount: Int) {
        self.expectedRoomCount = roomCount
        self.currentHypothesis = GraphHypothesis(expectedRoomCount: roomCount)
        self.smartPathGenerator = SmartPathGenerator(roomCount: roomCount)
    }
    
    /// Process a batch of exploration results
    public func processExplorations(paths: [String], results: [[Int]]) {
        for (path, labels) in zip(paths, results) {
            allExplorations.append(ExplorationState(path: path, labels: labels))
            currentHypothesis.exploredPaths.insert(path)
        }
        
        // Use state transition analyzer
        stateAnalyzer.processExplorations(paths: paths, results: results)
        updateHypothesisFromStates()
    }
    
    /// Generate a single long random path up to 18*roomCount length (legacy)
    public func generateSingleLongPath() -> String {
        let maxLength = 18 * expectedRoomCount
        var path = ""
        
        // Generate random path up to maxLength
        for _ in 0..<maxLength {
            path += String(Int.random(in: 0..<6))
        }
        
        return path
    }
    
    /// Generate entropy-optimal path using SmartPathGenerator
    public func generateSmartPath() -> String {
        let rooms = stateAnalyzer.identifyRooms()
        
        if currentHypothesis.exploredPaths.isEmpty {
            // First exploration: use entropy-optimal initial path
            return smartPathGenerator.generateInitialPath()
        } else {
            // Adaptive path based on current knowledge
            let mappedConnections = countMappedConnections(rooms)
            return smartPathGenerator.generateAdaptivePath(
                identifiedRooms: rooms.count,
                mappedConnections: mappedConnections
            )
        }
    }
    
    /// Count how many connections we've mapped
    private func countMappedConnections(_ rooms: [StateTransitionAnalyzer.Room]) -> Int {
        var count = 0
        for room in rooms {
            for door in 0..<6 {
                if room.doors[door] != nil {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Generate next path based on current knowledge
    public func generateNextPath() -> String? {
        // Check if we're confident enough to stop
        let rooms = stateAnalyzer.identifyRooms()
        let isComplete = stateAnalyzer.isComplete()
        
        if isComplete && rooms.count == expectedRoomCount {
            return nil  // We're done
        }
        
        // Use smart path generation for better information gain
        return generateSmartPath()
    }
    
    /// Generate initial exploration paths for Phase 1 (legacy batch method)
    public func generateInitialPaths() -> [String] {
        var paths: [String] = []
        
        // Step 1A: All single-door explorations
        for door in 0..<6 {
            paths.append(String(door))
        }
        
        // Step 1B: ALL two-door paths (including repeated doors)
        for door1 in 0..<6 {
            for door2 in 0..<6 {
                let path = "\(door1)\(door2)"
                if !currentHypothesis.exploredPaths.contains(path) {
                    paths.append(path)
                }
            }
        }
        
        // Step 1C: Important 3-door paths (especially repeated doors like "555")
        let important3Paths = [
            "000", "111", "222", "333", "444", "555",  // Triple same door
            "055", "155", "255", "355", "455",  // Paths to reach third room via door 5
            "500", "511", "522", "533", "544",  // Return paths
            "540", "541", "542", "543", "545",  // Explore room C's doors (reached via 54)
            "450", "451", "452", "453", "455"   // Explore room C's doors (reached via 45)
        ]
        for path in important3Paths {
            if !currentHypothesis.exploredPaths.contains(path) {
                paths.append(path)
            }
        }
        
        return paths
    }
    
    /// Generate paths for systematic BFS exploration
    public func generateBFSPaths(depth: Int, maxPaths: Int = 50) -> [String] {
        var paths: [String] = []
        var queue: [String] = [""]
        var visited = currentHypothesis.exploredPaths
        
        while !queue.isEmpty && paths.count < maxPaths {
            let current = queue.removeFirst()
            
            if current.count == depth {
                if !visited.contains(current) {
                    paths.append(current)
                    visited.insert(current)
                }
                continue
            }
            
            for door in 0..<6 {
                let newPath = current + String(door)
                if !visited.contains(newPath) {
                    queue.append(newPath)
                }
            }
        }
        
        return paths
    }
    
    /// Update hypothesis using state transition analysis
    private func updateHypothesisFromStates() {
        let rooms = stateAnalyzer.identifyRooms()
        
        // Convert rooms to signatures for compatibility
        var signatures: Set<RoomSignature> = []
        var labelCounts: [Int: Int] = [:]
        
        for room in rooms {
            var selfLoops: Set<Int> = []
            var transitions: Set<Int> = []
            var neighborLabels: [Int: Int] = [:]
            
            for (door, connection) in room.doors {
                if let connection = connection {
                    let toRoomId = connection.toRoomId
                    if toRoomId == room.id {
                        selfLoops.insert(door)
                    } else {
                        transitions.insert(door)
                        // Find label of target room
                        if let targetRoom = rooms.first(where: { $0.id == toRoomId }) {
                            neighborLabels[targetRoom.label, default: 0] += 1
                        }
                    }
                }
            }
            
            let signature = RoomSignature(
                label: room.label,
                selfLoopDoors: selfLoops,
                transitionDoors: transitions,
                neighborLabelCounts: neighborLabels
            )
            signatures.insert(signature)
            labelCounts[room.label, default: 0] += 1
        }
        
        // Update hypothesis
        currentHypothesis.roomSignatures = signatures
        currentHypothesis.labelDistribution = labelCounts
        currentHypothesis.connectionConfidence = calculateConfidence()
    }
    
    /// Legacy update method (not used)
    private func updateHypothesisLegacy() {
        // Build room signatures from single-door explorations
        var signatures: Set<RoomSignature> = []
        var labelCounts: [Int: Int] = [:]
        
        // Analyze single-door explorations
        let singleDoorExplorations = allExplorations.filter { $0.path.count == 1 }
        
        // Find the starting room label
        let startingLabel = singleDoorExplorations.first?.labels.first ?? 0
        
        // Build signature for starting room
        var startingSelfLoops: Set<Int> = []
        var startingTransitions: Set<Int> = []
        var startingNeighborLabels: [Int: Int] = [:]
        
        for exploration in singleDoorExplorations {
            guard let door = Int(exploration.path) else { continue }
            
            if exploration.labels.count >= 2 {
                let fromLabel = exploration.labels[0]
                let toLabel = exploration.labels[1]
                
                if fromLabel == toLabel {
                    startingSelfLoops.insert(door)
                } else {
                    startingTransitions.insert(door)
                    startingNeighborLabels[toLabel, default: 0] += 1
                }
                
                // Count all labels seen
                for label in exploration.labels {
                    labelCounts[label, default: 0] += 1
                }
            }
        }
        
        let startingSignature = RoomSignature(
            label: startingLabel,
            selfLoopDoors: startingSelfLoops,
            transitionDoors: startingTransitions,
            neighborLabelCounts: startingNeighborLabels
        )
        signatures.insert(startingSignature)
        
        // Analyze two-door explorations for more signatures
        let twoDoorExplorations = allExplorations.filter { $0.path.count == 2 }
        
        for exploration in twoDoorExplorations {
            if exploration.labels.count >= 3 {
                // Middle room analysis
                let middleLabel = exploration.labels[1]
                
                // Check if this reveals a new room signature
                if exploration.labels[0] != middleLabel || exploration.labels[2] != middleLabel {
                    // This middle room has transitions, analyze it
                    var middleSelfLoops: Set<Int> = []
                    var middleTransitions: Set<Int> = []
                    var middleNeighborLabels: [Int: Int] = [:]
                    
                    // We know at least one transition exists
                    if let firstDoor = Int(String(exploration.path.first!)) {
                        if exploration.labels[0] != middleLabel {
                            middleTransitions.insert(firstDoor)
                            middleNeighborLabels[exploration.labels[0], default: 0] += 1
                        }
                    }
                    
                    if let secondDoor = Int(String(exploration.path.last!)) {
                        if exploration.labels[2] != middleLabel {
                            middleTransitions.insert(secondDoor)
                            middleNeighborLabels[exploration.labels[2], default: 0] += 1
                        }
                    }
                    
                    // Create partial signature (we don't know all doors yet)
                    if !middleTransitions.isEmpty {
                        let middleSignature = RoomSignature(
                            label: middleLabel,
                            selfLoopDoors: middleSelfLoops,
                            transitionDoors: middleTransitions,
                            neighborLabelCounts: middleNeighborLabels
                        )
                        signatures.insert(middleSignature)
                    }
                }
            }
        }
        
        // This is legacy code, not used anymore
    }
    
    /// Calculate confidence in current hypothesis
    private func calculateConfidence() -> Double {
        let rooms = stateAnalyzer.identifyRooms()
        if rooms.isEmpty { return 0.0 }
        
        // Check if we have the expected number of rooms
        let roomCountMatch = rooms.count == expectedRoomCount ? 1.0 : 0.5
        
        // Check completeness of room mapping
        var totalDoors = 0
        var mappedDoors = 0
        
        for room in rooms {
            for door in 0..<6 {
                totalDoors += 1
                if room.doors[door] != nil {
                    mappedDoors += 1
                }
            }
        }
        
        let mappingCompleteness = totalDoors > 0 ? Double(mappedDoors) / Double(totalDoors) : 0.0
        
        let explorationCount = Double(currentHypothesis.exploredPaths.count)
        let explorationConfidence = min(1.0, explorationCount / 100.0)
        
        // Weight room count match heavily (40%), mapping completeness (40%), exploration (20%)
        return (roomCountMatch * 0.4 + mappingCompleteness * 0.4 + explorationConfidence * 0.2)
    }
    
    /// Get current hypothesis
    public func getCurrentHypothesis() -> GraphHypothesis {
        return currentHypothesis
    }
    
    /// Get the internal state analyzer for complete graph building
    public func getStateAnalyzer() -> StateTransitionAnalyzer {
        return stateAnalyzer
    }
    
    /// Identify clusters of rooms with similar signatures
    public func identifyRoomClusters() -> [[RoomSignature]] {
        var clusters: [Int: [RoomSignature]] = [:]
        
        for signature in currentHypothesis.roomSignatures {
            clusters[signature.label, default: []].append(signature)
        }
        
        return Array(clusters.values)
    }
    
    /// Generate paths to distinguish between rooms with same label
    public func generateDistinguishingPaths() -> [String] {
        var paths: [String] = []
        let clusters = identifyRoomClusters()
        
        for cluster in clusters where cluster.count > 1 {
            // For each cluster with multiple signatures, generate paths to differentiate
            for signature in cluster {
                // Try paths through transition doors to see different patterns
                for transitionDoor in signature.transitionDoors {
                    for returnDoor in 0..<6 {
                        let path = "\(transitionDoor)\(returnDoor)"
                        if !currentHypothesis.exploredPaths.contains(path) && paths.count < 20 {
                            paths.append(path)
                        }
                    }
                }
            }
        }
        
        return paths
    }
    
    /// Check if Phase 1 is complete
    public func isPhase1Complete() -> Bool {
        // Consider Phase 1 complete when:
        // 1. We have the expected number of rooms
        // 2. All rooms are fully mapped
        // 3. High confidence score
        
        let rooms = stateAnalyzer.identifyRooms()
        let hasExpectedRooms = rooms.count == expectedRoomCount
        let isComplete = stateAnalyzer.isComplete()
        
        return hasExpectedRooms && 
               isComplete && 
               currentHypothesis.connectionConfidence > 0.8
    }
}