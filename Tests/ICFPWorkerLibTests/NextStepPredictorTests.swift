import XCTest
@testable import ICFPWorkerLib

final class NextStepPredictorTests: XCTestCase {
    
    func testPredictorWithCompleteGraph() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        for door in 0..<6 {
            builder.setConnection(from: 0, door: door, to: 0, door: (door + 3) % 6)
        }
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertTrue(paths.isEmpty, "Complete graph should not generate new paths")
    }
    
    func testPredictorWithUnknownDoors() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertFalse(paths.isEmpty)
        
        let hasUnexploredDoorPaths = paths.contains { path in
            path == "1" || path == "2" || path == "3" || path == "4" || path == "5"
        }
        XCTAssertTrue(hasUnexploredDoorPaths)
    }
    
    func testPredictorWithAmbiguousConnections() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        _ = builder.processExploration(path: "01", labels: [0, 1, 2])
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertFalse(paths.isEmpty)
        
        let hasReturnPaths = paths.contains { path in
            path.starts(with: "0") && path.count == 2
        }
        XCTAssertTrue(hasReturnPaths)
    }
    
    func testPredictorWithUnlabeledRooms() {
        let builder = GraphBuilder(startingRoomLabel: nil)
        
        _ = builder.processExploration(path: "012", labels: [])
        
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 1, door: 0, to: 2, door: 3)
        builder.setConnection(from: 2, door: 0, to: 3, door: 3)
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertFalse(paths.isEmpty)
    }
    
    func testScorePathByInformationGain() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        let predictor = NextStepPredictor()
        
        let knownPath = "0"
        let unknownPath = "1"
        
        let knownScore = predictor.scorePathByInformationGain(path: knownPath, graph: builder)
        let unknownScore = predictor.scorePathByInformationGain(path: unknownPath, graph: builder)
        
        XCTAssertGreaterThan(unknownScore, knownScore, "Unknown door should have higher information gain")
    }
    
    func testMaxSuggestionsLimit() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor(maxPathLength: 5, maxSuggestions: 5)
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertLessThanOrEqual(paths.count, 5)
    }
    
    func testPathLengthLimit() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        for i in 0..<10 {
            _ = builder.processExploration(path: String(i % 6), labels: [0, i])
        }
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor(maxPathLength: 3, maxSuggestions: 20)
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        for path in paths {
            XCTAssertLessThanOrEqual(path.count, 3, "Path \(path) exceeds max length")
        }
    }
    
    func testExploratoryPathGeneration() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        // Set only partial connections to ensure graph is not complete
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 0, door: 1, to: 0, door: 4)
        builder.setConnection(from: 0, door: 3, to: 1, door: 0)
        
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertFalse(paths.isEmpty)
        
        let uniquePaths = Set(paths)
        XCTAssertEqual(uniquePaths.count, paths.count, "Paths should be unique")
    }
    
    func testMultiRoomExploration() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        _ = builder.processExploration(path: "012", labels: [0, 1, 2, 3])
        
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 1, door: 1, to: 2, door: 4)
        builder.setConnection(from: 2, door: 2, to: 3, door: 5)
        
        let evaluator = GraphEvaluator()
        let predictor = NextStepPredictor()
        
        let paths = predictor.predictNextPaths(graph: builder, evaluator: evaluator)
        
        XCTAssertFalse(paths.isEmpty)
        
        let hasMultiStepPaths = paths.contains { $0.count > 1 }
        XCTAssertTrue(hasMultiStepPaths, "Should generate multi-step paths to reach distant rooms")
    }
}