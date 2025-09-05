import XCTest
@testable import ICFPWorkerLib

final class ExplorationOrchestratorTests: XCTestCase {
    
    func testOrchestratorWithSimpleHexagon() async throws {
        let mockClient = MockExplorationClient(simpleHexagon: true)
        let orchestrator = ExplorationOrchestrator(
            client: mockClient,
            maxExplorations: 50,
            confidenceThreshold: 0.8
        )
        
        let result = try await orchestrator.exploreAndMap()
        
        XCTAssertTrue(result.explorationCount > 0)
        XCTAssertNotNil(result.finalMap)
    }
    
    func testOrchestratorWithFailingClient() async {
        let failingClient = MockFailingClient()
        let orchestrator = ExplorationOrchestrator(
            client: failingClient,
            maxExplorations: 10
        )
        
        do {
            _ = try await orchestrator.exploreAndMap()
            XCTFail("Should throw error with failing client")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testOrchestratorWithEmptyResponses() async throws {
        let emptyClient = MockEmptyClient()
        let orchestrator = ExplorationOrchestrator(
            client: emptyClient,
            maxExplorations: 5
        )
        
        let result = try await orchestrator.exploreAndMap()
        
        XCTAssertFalse(result.success)
        XCTAssertLessThanOrEqual(result.explorationCount, 5)
    }
    
    func testOrchestratorConfidenceThreshold() async throws {
        let mockClient = MockExplorationClient()
        
        let lowConfidenceOrchestrator = ExplorationOrchestrator(
            client: mockClient,
            maxExplorations: 100,
            confidenceThreshold: 0.3
        )
        
        let highConfidenceOrchestrator = ExplorationOrchestrator(
            client: mockClient,
            maxExplorations: 100,
            confidenceThreshold: 0.99
        )
        
        let lowResult = try await lowConfidenceOrchestrator.exploreAndMap()
        let highResult = try await highConfidenceOrchestrator.exploreAndMap()
        
        XCTAssertLessThanOrEqual(lowResult.explorationCount, highResult.explorationCount)
    }
    
    func testOrchestratorMaxExplorationsLimit() async throws {
        let mockClient = MockExplorationClient()
        let maxExplorations = 3
        
        let orchestrator = ExplorationOrchestrator(
            client: mockClient,
            maxExplorations: maxExplorations,
            confidenceThreshold: 0.999
        )
        
        let result = try await orchestrator.exploreAndMap()
        
        XCTAssertLessThanOrEqual(result.explorationCount, maxExplorations)
    }
    
    func testOrchestratorWithCustomPathGenerator() async throws {
        let mockClient = MockExplorationClient()
        let customGenerator = PathGenerator(maxPathLength: 3, maxPaths: 5)
        
        let orchestrator = ExplorationOrchestrator(
            client: mockClient,
            pathGenerator: customGenerator,
            maxExplorations: 10
        )
        
        let result = try await orchestrator.exploreAndMap()
        
        XCTAssertNotNil(result.finalMap)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    func testOrchestratorStartingRoomLabel() async throws {
        let mockClient = MockExplorationClient()
        
        let orchestrator = ExplorationOrchestrator(
            client: mockClient,
            startingRoomLabel: 42,
            maxExplorations: 20
        )
        
        let result = try await orchestrator.exploreAndMap()
        
        XCTAssertNotNil(result.finalMap)
    }
}