import Foundation

/// Main coordinator for the exploration pipeline
/// Orchestrates path generation, exploration, evaluation, and prediction
public class ExplorationOrchestrator {
    /// Client for API communication
    private let client: ExplorationClient
    /// Generates exploration paths
    private let pathGenerator: PathGenerator
    /// Maintains the discovered graph
    private let graphBuilder: GraphBuilder
    /// Evaluates graph completeness
    private let evaluator: GraphEvaluator
    /// Predicts next best paths
    private let predictor: NextStepPredictor
    
    /// Number of exploration API calls made
    private var explorationCount: Int = 0
    /// Maximum allowed exploration attempts
    private let maxExplorations: Int
    /// Confidence level required to consider graph complete
    private let confidenceThreshold: Double
    
    /// Current iteration number (for Worker compatibility)
    private var currentIteration: Int = 0
    /// Current exploration phase
    private var explorationPhase: ExplorationPhase = .initialExploration
    /// Track the last generated plans to pair with results
    private var lastGeneratedPlans: [String] = []
    
    /// Exploration phases matching Worker lifecycle
    public enum ExplorationPhase {
        case initialExploration
        case iterativeRefinement
        case finalMapping
    }
    
    /// Final result of the exploration process
    public struct ExplorationResult {
        /// Whether the map was successfully discovered
        public let success: Bool
        /// Total number of exploration queries used
        public let explorationCount: Int
        /// The final map (may be partial if failed)
        public let finalMap: MapDescription?
        /// Confidence in the final map
        public let confidence: Double
    }
    
    public init(
        client: ExplorationClient,
        pathGenerator: PathGenerator? = nil,
        startingRoomLabel: Int? = nil,
        maxExplorations: Int = 100,
        confidenceThreshold: Double = 0.95
    ) {
        self.client = client
        self.pathGenerator = pathGenerator ?? PathGenerator(maxPathLength: 10, maxPaths: 20)
        self.graphBuilder = GraphBuilder(startingRoomLabel: startingRoomLabel)
        self.evaluator = GraphEvaluator()
        self.predictor = NextStepPredictor(maxPathLength: 10, maxSuggestions: 20)
        self.maxExplorations = maxExplorations
        self.confidenceThreshold = confidenceThreshold
    }
    
    /// Main exploration loop - explores until map is complete or limit reached
    /// - Returns: ExplorationResult with success status and final map
    public func exploreAndMap() async throws -> ExplorationResult {
        // Phase 1: Initial broad exploration
        let initialPaths = pathGenerator.generatePaths(strategy: .basic)
        
        let initialResults = try await explorePaths(initialPaths)
        processBatchResults(paths: initialPaths, results: initialResults)
        
        // Phase 2: Iterative refinement
        while explorationCount < maxExplorations {
            let evaluation = evaluator.evaluate(graph: graphBuilder)
            
            // Check if we're done
            if evaluation.isComplete || evaluation.confidence >= confidenceThreshold {
                let finalMap = graphBuilder.toMapDescription()
                
                // Try to submit the map
                if let guessResult = try? await client.submitGuess(map: finalMap), guessResult.correct {
                    return ExplorationResult(
                        success: true,
                        explorationCount: explorationCount,
                        finalMap: finalMap,
                        confidence: evaluation.confidence
                    )
                }
            }
            
            // Generate next exploration paths
            let nextPaths = predictor.predictNextPaths(graph: graphBuilder, evaluator: evaluator)
            
            if nextPaths.isEmpty {
                // Fallback to systematic exploration if predictor has no suggestions
                let fallbackPaths = pathGenerator.generatePaths(strategy: .systematic)
                if fallbackPaths.isEmpty {
                    break
                }
                
                let results = try await explorePaths(fallbackPaths)
                processBatchResults(paths: fallbackPaths, results: results)
            } else {
                // Explore predicted paths
                let results = try await explorePaths(nextPaths)
                processBatchResults(paths: nextPaths, results: results)
            }
            
            // Try to merge duplicate rooms if detected
            if shouldTryMergingRooms() {
                attemptRoomMerging()
            }
        }
        
        let finalEvaluation = evaluator.evaluate(graph: graphBuilder)
        let finalMap = graphBuilder.toMapDescription()
        
        if let guessResult = try? await client.submitGuess(map: finalMap) {
            return ExplorationResult(
                success: guessResult.correct,
                explorationCount: explorationCount,
                finalMap: finalMap,
                confidence: finalEvaluation.confidence
            )
        }
        
        return ExplorationResult(
            success: false,
            explorationCount: explorationCount,
            finalMap: finalMap,
            confidence: finalEvaluation.confidence
        )
    }
    
    private func explorePaths(_ paths: [String]) async throws -> [[Int]] {
        guard !paths.isEmpty else { return [] }
        
        let response = try await client.explore(plans: paths)
        explorationCount += 1
        
        return response.results
    }
    
    private func processBatchResults(paths: [String], results: [[Int]]) {
        // First, detect connection patterns from single-door explorations
        graphBuilder.detectConnectionPatterns(paths: paths, results: results)
        
        // Then process each path individually
        for (index, path) in paths.enumerated() {
            if index < results.count {
                let labels = results[index]
                _ = graphBuilder.processExploration(path: path, labels: labels)
                
                inferConnectionsFromPath(path: path, labels: labels)
            }
        }
    }
    
    /// Infer additional information from exploration results
    /// Tries to deduce room labels and return connections
    private func inferConnectionsFromPath(path: String, labels: [Int]) {
        guard !path.isEmpty, !labels.isEmpty else { return }
        
        // Trace the path to build room sequence
        var currentRoom = graphBuilder.getStartingRoom()
        var roomSequence: [Int] = [currentRoom]
        
        for (_, doorChar) in path.enumerated() {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            if let room = graphBuilder.getRoom(currentRoom),
               let connection = room.doors[door],
               let (nextRoom, _) = connection {
                currentRoom = nextRoom
                roomSequence.append(currentRoom)
            }
        }
        
        if roomSequence.count == labels.count {
            for (i, roomId) in roomSequence.enumerated() {
                if var room = graphBuilder.getRoom(roomId), room.label == nil {
                    room.label = labels[i]
                }
            }
        }
        
        for i in 0..<(roomSequence.count - 1) {
            let fromRoom = roomSequence[i]
            let toRoom = roomSequence[i + 1]
            
            if i < path.count, let door = Int(String(path[path.index(path.startIndex, offsetBy: i)])) {
                tryInferReturnConnection(from: fromRoom, door: door, to: toRoom)
            }
        }
    }
    
    private func tryInferReturnConnection(from fromRoom: Int, door fromDoor: Int, to toRoom: Int) {
        guard let targetRoom = graphBuilder.getRoom(toRoom) else { return }
        
        for (toDoor, connection) in targetRoom.doors {
            if let (returnRoom, _) = connection, returnRoom == fromRoom {
                graphBuilder.setConnection(from: fromRoom, door: fromDoor, to: toRoom, door: toDoor)
                graphBuilder.setConnection(from: toRoom, door: toDoor, to: fromRoom, door: fromDoor)
                break
            }
        }
    }
    
    /// Check if we should attempt to merge duplicate rooms
    /// Looks for rooms with same labels that might be the same room
    private func shouldTryMergingRooms() -> Bool {
        let allRooms = graphBuilder.getAllRooms()
        
        // Check for merging even with few rooms (removed the > 10 restriction)
        guard allRooms.count > 1 else { return false }
        
        // Look for potential duplicates
        for room1 in allRooms {
            for room2 in allRooms where room1.id < room2.id {
                // Same label is a strong indicator
                if room1.label == room2.label && room1.label != nil {
                    // Don't require exact connection count match
                    return true
                }
            }
        }
        
        return false
    }
    
    private func attemptRoomMerging() {
        let allRooms = graphBuilder.getAllRooms()
        
        for room1 in allRooms {
            for room2 in allRooms where room1.id < room2.id {
                if room1.label == room2.label && room1.label != nil {
                    let shouldMerge = analyzeRoomsForMerging(room1: room1, room2: room2)
                    if shouldMerge {
                        graphBuilder.mergeRooms(room1.id, room2.id)
                        return
                    }
                }
            }
        }
    }
    
    private func analyzeRoomsForMerging(room1: GraphBuilder.Room, room2: GraphBuilder.Room) -> Bool {
        // If they have the same label, they're likely the same room
        guard room1.label == room2.label, room1.label != nil else { return false }
        
        // Check if one room has very few connections (likely a duplicate created early)
        let connections1 = room1.doors.values.compactMap { $0 }
        let connections2 = room2.doors.values.compactMap { $0 }
        
        // If one room has no or very few connections, it's likely a duplicate
        if connections1.count <= 1 || connections2.count <= 1 {
            return true
        }
        
        // If they have similar connection patterns, merge them
        if abs(connections1.count - connections2.count) <= 3 {
            return true
        }
        
        return false
    }
    
    // MARK: - Worker-Compatible Methods
    
    /// Generate exploration plans based on current phase
    /// Compatible with Worker.generatePlans()
    public func generatePlans() -> [String] {
        let plans: [String]
        
        switch explorationPhase {
        case .initialExploration:
            // Phase 1: Basic exploration
            plans = pathGenerator.generatePaths(strategy: .basic)
            
        case .iterativeRefinement:
            // Phase 2: Intelligent prediction
            let nextPaths = predictor.predictNextPaths(graph: graphBuilder, evaluator: evaluator)
            if nextPaths.isEmpty {
                plans = pathGenerator.generatePaths(strategy: .systematic)
            } else {
                plans = nextPaths
            }
            
        case .finalMapping:
            // No more exploration needed
            plans = []
        }
        
        // Track the generated plans for later processing
        lastGeneratedPlans = plans
        return plans
    }
    
    /// Process exploration results and update graph
    /// Compatible with Worker.processExplored()
    public func processExplored(explored: ExploreResponse) {
        // Track exploration count
        explorationCount += 1
        
        // Process each path-result pair using the last generated plans
        for (index, path) in lastGeneratedPlans.enumerated() {
            if index < explored.results.count {
                let labels = explored.results[index]
                _ = graphBuilder.processExploration(path: path, labels: labels)
                inferConnectionsFromPath(path: path, labels: labels)
            }
        }
        
        // Try room merging if conditions are met
        if shouldTryMergingRooms() {
            attemptRoomMerging()
        }
    }
    
    /// Determine if exploration should continue
    /// Compatible with Worker.shouldContinue()
    public func shouldContinue(iterations: Int) -> Bool {
        currentIteration = iterations
        
        // Check limits
        if explorationCount >= maxExplorations {
            explorationPhase = .finalMapping
            return false
        }
        
        // Evaluate current graph state
        let evaluation = evaluator.evaluate(graph: graphBuilder)
        
        // Check if we're confident enough
        if evaluation.isComplete || evaluation.confidence >= confidenceThreshold {
            explorationPhase = .finalMapping
            return false
        }
        
        // Transition from initial to iterative phase after first iteration
        if explorationPhase == .initialExploration && iterations > 1 {
            explorationPhase = .iterativeRefinement
        }
        
        return true
    }
    
    /// Generate final map guess
    /// Compatible with Worker.generateGuess()
    public func generateGuess() -> MapDescription {
        return graphBuilder.toMapDescription()
    }
    
    // MARK: - Public Accessors for VibeWorker
    
    /// Get current exploration count
    public func getExplorationCount() -> Int {
        return explorationCount
    }
    
    /// Get current confidence level
    public func getCurrentConfidence() -> Double {
        let evaluation = evaluator.evaluate(graph: graphBuilder)
        return evaluation.confidence
    }
    
    /// Get current exploration phase
    public func getCurrentPhase() -> ExplorationPhase {
        return explorationPhase
    }
}