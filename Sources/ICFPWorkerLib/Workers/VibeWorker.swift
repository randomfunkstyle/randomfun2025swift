import Foundation

/// Advanced Worker implementation using the sophisticated VibeCoded exploration system
/// Leverages ExplorationOrchestrator's intelligent path generation, graph building, and prediction
public final class VibeWorker: Worker {
    
    /// The sophisticated exploration orchestrator from VibeCoded system
    private let orchestrator: ExplorationOrchestrator
    
    /// Configuration for VibeWorker behavior
    public struct VibeConfig {
        public let maxExplorations: Int
        public let confidenceThreshold: Double
        public let maxPathLength: Int
        public let maxPathsPerBatch: Int
        public let maxSuggestions: Int
        
        public init(
            maxExplorations: Int = 100,
            confidenceThreshold: Double = 0.95,
            maxPathLength: Int = 10,
            maxPathsPerBatch: Int = 20,
            maxSuggestions: Int = 20
        ) {
            self.maxExplorations = maxExplorations
            self.confidenceThreshold = confidenceThreshold
            self.maxPathLength = maxPathLength
            self.maxPathsPerBatch = maxPathsPerBatch
            self.maxSuggestions = maxSuggestions
        }
        
        public static let `default` = VibeConfig()
    }
    
    /// Initialize VibeWorker with problem, client, and optional configuration
    /// - Parameters:
    ///   - problem: Contest problem to solve
    ///   - client: Exploration client (HTTP or Mock)
    ///   - config: Configuration parameters for exploration behavior
    ///   - startingRoomLabel: Optional label for the starting room if known
    public init(
        problem: Problem, 
        client: ExplorationClient, 
        config: VibeConfig = .default,
        startingRoomLabel: Int? = nil
    ) {
        // Create path generator with config parameters
        let pathGenerator = PathGenerator(
            maxPathLength: config.maxPathLength,
            maxPaths: config.maxPathsPerBatch
        )
        
        // Initialize the sophisticated exploration orchestrator
        self.orchestrator = ExplorationOrchestrator(
            client: client,
            pathGenerator: pathGenerator,
            startingRoomLabel: startingRoomLabel,
            maxExplorations: config.maxExplorations,
            confidenceThreshold: config.confidenceThreshold
        )
        
        // Call parent initializer
        super.init(problem: problem, client: client)
    }
    
    // MARK: - Worker Method Overrides
    // All Worker methods are delegated to the ExplorationOrchestrator
    
    /// Generate exploration plans based on current exploration phase
    /// Delegates to orchestrator's intelligent path generation system
    public override func generatePlans() -> [String] {
        let plans = orchestrator.generatePlans()
        
        // Log current phase for debugging
        let phase = orchestrator.getCurrentPhase()
        print("📍 VibeWorker Phase: \(phase), Generated \(plans.count) plans")
        
        return plans
    }
    
    /// Process exploration results and update internal graph representation
    /// Uses sophisticated graph building and inference algorithms
    public override func processExplored(explored: ExploreResponse) {
        orchestrator.processExplored(explored: explored)
        
        // Log exploration progress
        let count = orchestrator.getExplorationCount()
        let confidence = orchestrator.getCurrentConfidence()
        print("🔍 Exploration #\(count): Confidence = \(String(format: "%.2f", confidence))")
        
        // Call parent for additional logging
        super.processExplored(explored: explored)
    }
    
    /// Determine if exploration should continue based on intelligent criteria
    /// Considers exploration limits, confidence thresholds, and graph completeness
    public override func shouldContinue(iterations: Int) -> Bool {
        let shouldContinue = orchestrator.shouldContinue(iterations: iterations)
        
        if !shouldContinue {
            let confidence = orchestrator.getCurrentConfidence()
            let explorationCount = orchestrator.getExplorationCount()
            print("🎯 VibeWorker stopping: Confidence=\(String(format: "%.2f", confidence)), Explorations=\(explorationCount)")
        }
        
        return shouldContinue
    }
    
    /// Generate final map guess using complete graph representation
    /// Produces optimized MapDescription from discovered graph structure
    public override func generateGuess() -> MapDescription {
        let guess = orchestrator.generateGuess()
        
        // Log final statistics
        let confidence = orchestrator.getCurrentConfidence()
        let explorationCount = orchestrator.getExplorationCount()
        print("🗺️ Final map: \(guess.rooms.count) rooms, \(guess.connections.count) connections")
        print("📊 Final stats: Confidence=\(String(format: "%.2f", confidence)), Explorations=\(explorationCount)")
        
        return guess
    }
    
    // MARK: - Additional Utility Methods
    
    /// Get current exploration statistics for monitoring
    public func getExplorationStats() -> ExplorationStats {
        return ExplorationStats(
            explorationCount: orchestrator.getExplorationCount(),
            confidence: orchestrator.getCurrentConfidence(),
            phase: orchestrator.getCurrentPhase()
        )
    }
    
    /// Statistics about current exploration progress
    public struct ExplorationStats {
        public let explorationCount: Int
        public let confidence: Double
        public let phase: ExplorationOrchestrator.ExplorationPhase
        
        public var description: String {
            return "Explorations: \(explorationCount), Confidence: \(String(format: "%.2f", confidence)), Phase: \(phase)"
        }
    }
}

// MARK: - VibeWorker Extensions for Debugging

extension VibeWorker {
    /// Create a VibeWorker optimized for testing with mock client
    public static func forTesting(
        problem: Problem = .probatio,
        layout: MockExplorationClient.RoomLayout = .threeRooms,
        config: VibeConfig = .default
    ) -> VibeWorker {
        let mockClient = MockExplorationClient(layout: layout)
        return VibeWorker(problem: problem, client: mockClient, config: config)
    }
    
    /// Create a VibeWorker for real contest with HTTP client
    public static func forContest(
        problem: Problem,
        config: VibeConfig = .default
    ) -> VibeWorker {
        let httpClient = HTTPExplorationClient()
        return VibeWorker(problem: problem, client: httpClient, config: config)
    }
}