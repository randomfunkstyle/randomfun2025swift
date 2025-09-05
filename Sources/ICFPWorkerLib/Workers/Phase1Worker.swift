import Foundation

/// Worker that implements comprehensive Phase 1 exploration strategy
/// Designed to handle graphs with up to 30 rooms efficiently
public class Phase1Worker: Worker {
    private let phase1Analyzer = Phase1Analyzer()
    private let graphBuilder = GraphConnectionBuilder()
    private var explorationCount = 0
    private let maxExplorations: Int
    
    public init(problem: Problem, client: ExplorationClient, maxExplorations: Int = 200) {
        self.maxExplorations = maxExplorations
        super.init(problem: problem, client: client)
    }
    
    public static func forTesting(problem: Problem, layout: MockExplorationClient.RoomLayout) async throws -> Phase1Worker {
        let client = MockExplorationClient(layout: layout)
        return Phase1Worker(problem: problem, client: client)
    }
    
    public static func forTestingTwoFull(problem: Problem) async throws -> Phase1Worker {
        let client = MockExplorationClient(layout: .twoRoomsFullyConnected)
        return Phase1Worker(problem: problem, client: client)
    }
    
    override public func run() async throws {
        print("🔬 Phase1Worker starting comprehensive initial discovery...")
        print("📊 Target: Handle up to 30 rooms with only 4 possible labels")
        
        // Phase 1A: Initial exploration
        try await executeInitialExploration()
        
        // Phase 1B: BFS exploration if needed
        if !phase1Analyzer.isPhase1Complete() && explorationCount < maxExplorations {
            try await executeBFSExploration()
        }
        
        // Phase 1C: Distinguishing sequences for ambiguous rooms
        if !phase1Analyzer.isPhase1Complete() && explorationCount < maxExplorations {
            try await executeDistinguishingExploration()
        }
        
        // Generate and submit final map
        try await submitFinalMap()
    }
    
    private func executeInitialExploration() async throws {
        print("\n📍 Phase 1A: Initial exploration (single & two-door paths)...")
        
        let initialPaths = phase1Analyzer.generateInitialPaths()
        let batches = createBatches(paths: initialPaths, batchSize: 50)
        
        for (index, batch) in batches.enumerated() {
            print("  Batch \(index + 1)/\(batches.count): Exploring \(batch.count) paths")
            print("    Paths: \(batch.prefix(10).joined(separator: ", "))\(batch.count > 10 ? ", ..." : "")")
            
            if let results = try? await client.explore(plans: batch) {
                explorationCount += 1
                phase1Analyzer.processExplorations(paths: batch, results: results.results)
                
                let hypothesis = phase1Analyzer.getCurrentHypothesis()
                print("    Room signatures found: \(hypothesis.roomSignatures.count)")
                print("    Room count estimate: \(hypothesis.roomCountEstimate)")
                print("    Confidence: \(String(format: "%.2f", hypothesis.connectionConfidence))")
            }
            
            if phase1Analyzer.isPhase1Complete() {
                print("  ✅ Phase 1 complete after initial exploration!")
                return
            }
        }
    }
    
    private func executeBFSExploration() async throws {
        print("\n📍 Phase 1B: BFS exploration to depth 2-3...")
        
        // Try depth 2 first
        var bfsPaths = phase1Analyzer.generateBFSPaths(depth: 2, maxPaths: 30)
        
        if !bfsPaths.isEmpty {
            print("  Exploring \(bfsPaths.count) depth-2 paths")
            if let results = try? await client.explore(plans: bfsPaths) {
                explorationCount += 1
                phase1Analyzer.processExplorations(paths: bfsPaths, results: results.results)
            }
        }
        
        // Try depth 3 if needed
        if !phase1Analyzer.isPhase1Complete() && explorationCount < maxExplorations - 10 {
            bfsPaths = phase1Analyzer.generateBFSPaths(depth: 3, maxPaths: 30)
            
            if !bfsPaths.isEmpty {
                print("  Exploring \(bfsPaths.count) depth-3 paths")
                if let results = try? await client.explore(plans: bfsPaths) {
                    explorationCount += 1
                    phase1Analyzer.processExplorations(paths: bfsPaths, results: results.results)
                }
            }
        }
        
        let hypothesis = phase1Analyzer.getCurrentHypothesis()
        print("  Current hypothesis: \(hypothesis.roomSignatures.count) signatures, confidence \(String(format: "%.2f", hypothesis.connectionConfidence))")
    }
    
    private func executeDistinguishingExploration() async throws {
        print("\n📍 Phase 1C: Distinguishing sequences for ambiguous rooms...")
        
        let distinguishingPaths = phase1Analyzer.generateDistinguishingPaths()
        
        if !distinguishingPaths.isEmpty {
            print("  Generated \(distinguishingPaths.count) distinguishing paths")
            if let results = try? await client.explore(plans: distinguishingPaths) {
                explorationCount += 1
                phase1Analyzer.processExplorations(paths: distinguishingPaths, results: results.results)
            }
        }
        
        // Show room clusters
        let clusters = phase1Analyzer.identifyRoomClusters()
        print("\n  Room clusters by label:")
        for cluster in clusters {
            if let first = cluster.first {
                print("    Label \(first.label): \(cluster.count) distinct signature(s)")
                for signature in cluster.prefix(3) {
                    print("      - \(signature.identifier)")
                }
                if cluster.count > 3 {
                    print("      ... and \(cluster.count - 3) more")
                }
            }
        }
    }
    
    private func submitFinalMap() async throws {
        print("\n🗺️ Generating complete map from Phase 1 analysis...")
        
        // Get the complete room graph from internal state analyzer
        let stateAnalyzer = phase1Analyzer.getStateAnalyzer()
        let rooms = stateAnalyzer.identifyRooms()
        
        // Build complete MapDescription
        let map = graphBuilder.buildCompleteGraph(rooms: rooms)
        
        // Debug: Print room details
        print("\n🔍 Room Details:")
        for room in rooms.sorted(by: { $0.id < $1.id }) {
            print("  Room \(room.id) (label \(room.label)):")
            for door in 0..<6 {
                if let conn = room.doors[door] {
                    if let c = conn {
                        print("    Door \(door) → Room \(c.toRoomId) door \(c.toDoor ?? -1)")
                    }
                }
            }
        }
        
        // Print statistics
        print(graphBuilder.getGraphStatistics(rooms: rooms))
        
        // Validate the graph
        let validation = graphBuilder.validateGraph(rooms: rooms)
        if !validation.isComplete {
            print("\n⚠️ Graph validation issues:")
            for issue in validation.issues.prefix(5) {
                print("  - \(issue)")
            }
            if validation.issues.count > 5 {
                print("  ... and \(validation.issues.count - 5) more issues")
            }
        }
        
        print("\n📊 Final map details:")
        print("  Rooms: \(map.rooms)")
        print("  Starting room: \(map.startingRoom)")
        print("  Total connections: \(map.connections.count)")
        print("  Total explorations: \(explorationCount)")
        
        // Submit the complete map
        if let guessResult = try? await client.submitGuess(map: map) {
            if guessResult.correct {
                print("\n✅ Successfully mapped the complete library!")
                print("🎉 Total explorations used: \(explorationCount)")
            } else {
                print("\n❌ Phase 1 mapping incomplete or incorrect")
                print("📝 Would proceed to Phase 2 for refinement...")
            }
        }
    }
    
    private func createBatches(paths: [String], batchSize: Int) -> [[String]] {
        var batches: [[String]] = []
        var currentBatch: [String] = []
        
        for path in paths {
            currentBatch.append(path)
            if currentBatch.count >= batchSize {
                batches.append(currentBatch)
                currentBatch = []
            }
        }
        
        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }
        
        return batches
    }
}