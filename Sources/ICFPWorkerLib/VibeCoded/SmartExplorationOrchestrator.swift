import Foundation

/// Result of an exploration session
public struct ExplorationResult {
    public let success: Bool
    public let explorationCount: Int
    public let finalMap: MapDescription
    public let confidence: Double
}

/// Orchestrates exploration using smart pattern analysis
public class SmartExplorationOrchestrator {
    private let client: ExplorationClient
    private let smartBuilder = SmartGraphBuilder()
    private var explorationCount = 0
    private let maxExplorations: Int
    private let confidenceThreshold: Double
    
    public init(
        client: ExplorationClient,
        maxExplorations: Int = 10,
        confidenceThreshold: Double = 0.95
    ) {
        self.client = client
        self.maxExplorations = maxExplorations
        self.confidenceThreshold = confidenceThreshold
    }
    
    /// Run the smart exploration process
    public func explore() async throws -> ExplorationResult {
        // Phase 1: Initial single-door exploration (most informative)
        let initialPaths = (0..<6).map { String($0) }
        if let results = try? await client.explore(plans: initialPaths) {
            explorationCount += 1
            smartBuilder.processBatch(paths: initialPaths, results: results.results)
            
            // Check if we already have enough information
            if smartBuilder.getConfidence() >= confidenceThreshold {
                return await submitResult()
            }
        }
        
        // Phase 2: Targeted exploration to find return paths
        while explorationCount < maxExplorations {
            let confidence = smartBuilder.getConfidence()
            
            // Check if we're done
            if confidence >= confidenceThreshold || smartBuilder.isComplete() {
                break
            }
            
            // Get suggested paths
            let suggestedPaths = smartBuilder.getSuggestedPaths()
            if suggestedPaths.isEmpty {
                break
            }
            
            // Explore in small batches for efficiency
            let batchSize = min(10, suggestedPaths.count)
            let batch = Array(suggestedPaths.prefix(batchSize))
            
            if let results = try? await client.explore(plans: batch) {
                explorationCount += 1
                smartBuilder.processBatch(paths: batch, results: results.results)
            }
        }
        
        return await submitResult()
    }
    
    /// Submit the final result
    private func submitResult() async -> ExplorationResult {
        let finalMap = smartBuilder.toMapDescription()
        let confidence = smartBuilder.getConfidence()
        
        if let guessResult = try? await client.submitGuess(map: finalMap) {
            if guessResult.correct {
                print("\n🗺️ Successfully mapped the library!")
                print("📋 Final Map Description:")
                print("  Rooms: \(finalMap.rooms)")
                print("  Starting Room ID: \(finalMap.startingRoom)")
                print("  Number of Connections: \(finalMap.connections.count)")
                print("\n🔗 Connections:")
                for connection in finalMap.connections {
                    print("  Room \(connection.from.room) door \(connection.from.door) → Room \(connection.to.room) door \(connection.to.door)")
                }
            }
            
            return ExplorationResult(
                success: guessResult.correct,
                explorationCount: explorationCount,
                finalMap: finalMap,
                confidence: confidence
            )
        }
        
        return ExplorationResult(
            success: false,
            explorationCount: explorationCount,
            finalMap: finalMap,
            confidence: confidence
        )
    }
    
    /// Get current statistics
    public func getStats() -> (roomCount: Int, confidence: Double, explorations: Int) {
        return (
            roomCount: smartBuilder.getRoomCount(),
            confidence: smartBuilder.getConfidence(),
            explorations: explorationCount
        )
    }
}

/// Worker implementation using SmartExplorationOrchestrator
public class SmartVibeWorker: Worker {
    private let orchestrator: SmartExplorationOrchestrator
    
    public override init(problem: Problem, client: ExplorationClient) {
        self.orchestrator = SmartExplorationOrchestrator(
            client: client,
            maxExplorations: 10,
            confidenceThreshold: 0.95
        )
        super.init(problem: problem, client: client)
    }
    
    public static func forTesting(problem: Problem, layout: MockExplorationClient.RoomLayout) async throws -> SmartVibeWorker {
        let client = MockExplorationClient(layout: layout)
        return SmartVibeWorker(problem: problem, client: client)
    }
    
    override public func run() async throws {
        print("🚀 SmartVibeWorker starting with pattern-first analysis...")
        
        let result = try await orchestrator.explore()
        
        let stats = orchestrator.getStats()
        print("📊 Final stats: Rooms=\(stats.roomCount), Confidence=\(String(format: "%.2f", stats.confidence)), Explorations=\(stats.explorations)")
        
        if result.success {
            print("✅ Successfully mapped the library!")
        } else {
            print("❌ Mapping incomplete or incorrect")
        }
    }
}