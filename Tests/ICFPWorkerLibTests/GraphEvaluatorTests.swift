import XCTest
@testable import ICFPWorkerLib

final class GraphEvaluatorTests: XCTestCase {
    
    func testEmptyGraphEvaluation() {
        let builder = GraphBuilder()
        let evaluator = GraphEvaluator()
        
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertFalse(result.isComplete)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThan(result.confidence, 1.0)
    }
    
    func testIncompleteGraphWithUnlabeledRooms() {
        let builder = GraphBuilder(startingRoomLabel: nil)
        _ = builder.processExploration(path: "012", labels: [])
        
        let evaluator = GraphEvaluator()
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertFalse(result.isComplete)
        XCTAssertFalse(result.missingInfo.unlabeledRooms.isEmpty)
        XCTAssertLessThan(result.confidence, 0.5)
    }
    
    func testCompleteSmallGraph() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 0, door: 1, to: 0, door: 4)
        builder.setConnection(from: 0, door: 2, to: 0, door: 5)
        builder.setConnection(from: 0, door: 3, to: 1, door: 0)
        builder.setConnection(from: 0, door: 4, to: 0, door: 1)
        builder.setConnection(from: 0, door: 5, to: 0, door: 2)
        
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        builder.setConnection(from: 1, door: 0, to: 0, door: 3)
        builder.setConnection(from: 1, door: 1, to: 1, door: 4)
        builder.setConnection(from: 1, door: 2, to: 1, door: 5)
        builder.setConnection(from: 1, door: 3, to: 0, door: 0)
        builder.setConnection(from: 1, door: 4, to: 1, door: 1)
        builder.setConnection(from: 1, door: 5, to: 1, door: 2)
        
        let evaluator = GraphEvaluator()
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertTrue(result.isComplete)
        XCTAssertEqual(result.confidence, 1.0)
        XCTAssertTrue(result.missingInfo.unlabeledRooms.isEmpty)
        XCTAssertTrue(result.missingInfo.unknownDoors.isEmpty)
    }
    
    func testGraphWithUnknownDoors() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        builder.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder.setConnection(from: 1, door: 3, to: 0, door: 0)
        
        let evaluator = GraphEvaluator()
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertFalse(result.isComplete)
        XCTAssertFalse(result.missingInfo.unknownDoors.isEmpty)
        
        let unknownDoorsCount = result.missingInfo.unknownDoors.count
        XCTAssertEqual(unknownDoorsCount, 10)
    }
    
    func testAmbiguousConnections() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        _ = builder.processExploration(path: "01", labels: [0, 1, 2])
        
        let evaluator = GraphEvaluator()
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertFalse(result.isComplete)
        
        let hasAmbiguous = !result.missingInfo.ambiguousConnections.isEmpty
        XCTAssertTrue(hasAmbiguous)
    }
    
    func testConfidenceCalculation() {
        let evaluator = GraphEvaluator()
        
        let builder1 = GraphBuilder(startingRoomLabel: 0)
        let result1 = evaluator.evaluate(graph: builder1)
        
        _ = builder1.processExploration(path: "0", labels: [0, 1])
        let result2 = evaluator.evaluate(graph: builder1)
        
        builder1.setConnection(from: 0, door: 0, to: 1, door: 3)
        builder1.setConnection(from: 1, door: 3, to: 0, door: 0)
        let result3 = evaluator.evaluate(graph: builder1)
        
        XCTAssertLessThan(result1.confidence, result2.confidence)
        XCTAssertLessThan(result2.confidence, result3.confidence)
    }
    
    func testFindCriticalUnexploredPaths() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        _ = builder.processExploration(path: "0", labels: [0, 1])
        
        let evaluator = GraphEvaluator()
        let criticalPaths = evaluator.findCriticalUnexploredPaths(graph: builder)
        
        XCTAssertFalse(criticalPaths.isEmpty)
        
        for path in criticalPaths {
            XCTAssertFalse(path.isEmpty)
            for char in path {
                if let door = Int(String(char)) {
                    XCTAssertGreaterThanOrEqual(door, 0)
                    XCTAssertLessThan(door, 6)
                }
            }
        }
    }
    
    func testEvaluationWithMultipleRooms() {
        let builder = GraphBuilder(startingRoomLabel: 0)
        
        _ = builder.processExploration(path: "012345", labels: [0, 1, 2, 3, 0, 1, 2])
        
        for i in 0..<4 {
            for door in 0..<6 {
                let targetRoom = (i + door) % 4
                builder.setConnection(from: i, door: door, to: targetRoom, door: (door + 3) % 6)
            }
        }
        
        let evaluator = GraphEvaluator()
        let result = evaluator.evaluate(graph: builder)
        
        XCTAssertFalse(result.isComplete)
        XCTAssertGreaterThan(result.confidence, 0.5)
    }
}