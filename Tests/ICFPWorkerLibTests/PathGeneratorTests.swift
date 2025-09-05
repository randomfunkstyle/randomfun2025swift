import XCTest
@testable import ICFPWorkerLib

final class PathGeneratorTests: XCTestCase {
    
    func testBasicPathGeneration() {
        let generator = PathGenerator(maxPathLength: 5, maxPaths: 50)
        let paths = generator.generatePaths(strategy: .basic)
        
        XCTAssertFalse(paths.isEmpty)
        XCTAssertLessThanOrEqual(paths.count, 50)
        
        for path in paths {
            for char in path {
                if let door = Int(String(char)) {
                    XCTAssertGreaterThanOrEqual(door, 0)
                    XCTAssertLessThan(door, 6)
                } else {
                    XCTFail("Invalid door character: \(char)")
                }
            }
        }
        
        XCTAssertTrue(paths.contains("0"))
        XCTAssertTrue(paths.contains("1"))
        XCTAssertTrue(paths.contains("2"))
        XCTAssertTrue(paths.contains("3"))
        XCTAssertTrue(paths.contains("4"))
        XCTAssertTrue(paths.contains("5"))
    }
    
    func testSystematicPathGeneration() {
        let generator = PathGenerator(maxPathLength: 3, maxPaths: 100)
        let paths = generator.generatePaths(strategy: .systematic)
        
        XCTAssertFalse(paths.isEmpty)
        
        XCTAssertTrue(paths.contains("0"))
        XCTAssertTrue(paths.contains("5"))
        
        let hasLengthTwo = paths.contains { $0.count == 2 }
        XCTAssertTrue(hasLengthTwo)
        
        for path in paths {
            XCTAssertLessThanOrEqual(path.count, 3)
        }
    }
    
    func testTargetedPathGeneration() {
        let unexploredDoors = [(room: 0, door: 2), (room: 1, door: 4)]
        let generator = PathGenerator(maxPathLength: 5, maxPaths: 20)
        let paths = generator.generatePaths(strategy: .targeted(unexploredDoors: unexploredDoors))
        
        XCTAssertFalse(paths.isEmpty)
        
        let hasTargetedPath = paths.contains { path in
            path.starts(with: "2") || path.starts(with: "4")
        }
        XCTAssertTrue(hasTargetedPath)
        
        XCTAssertLessThanOrEqual(paths.count, 20)
    }
    
    func testBreadthFirstPaths() {
        let generator = PathGenerator(maxPathLength: 10, maxPaths: 50)
        let paths = generator.generateBreadthFirstPaths(depth: 2)
        
        XCTAssertFalse(paths.isEmpty)
        
        let singleDoorPaths = paths.filter { $0.count == 1 }
        XCTAssertEqual(singleDoorPaths.count, 6)
        
        let twoDoorPaths = paths.filter { $0.count == 2 }
        XCTAssertEqual(twoDoorPaths.count, 36)
        
        for path in paths {
            XCTAssertLessThanOrEqual(path.count, 2)
        }
    }
    
    func testDepthFirstPaths() {
        let generator = PathGenerator(maxPathLength: 10, maxPaths: 30)
        let paths = generator.generateDepthFirstPaths(maxDepth: 3, branchingFactor: 2)
        
        XCTAssertFalse(paths.isEmpty)
        XCTAssertLessThanOrEqual(paths.count, 30)
        
        for path in paths {
            XCTAssertGreaterThan(path.count, 0)
            XCTAssertLessThanOrEqual(path.count, 3)
        }
        
        let depthThreePaths = paths.filter { $0.count == 3 }
        XCTAssertFalse(depthThreePaths.isEmpty)
    }
    
    func testMaxPathsLimit() {
        let generator = PathGenerator(maxPathLength: 10, maxPaths: 5)
        
        let basicPaths = generator.generatePaths(strategy: .basic)
        XCTAssertLessThanOrEqual(basicPaths.count, 5)
        
        let systematicPaths = generator.generatePaths(strategy: .systematic)
        XCTAssertLessThanOrEqual(systematicPaths.count, 5)
        
        let bfsPaths = generator.generateBreadthFirstPaths(depth: 5)
        XCTAssertLessThanOrEqual(bfsPaths.count, 5)
    }
    
    func testPathUniqueness() {
        let generator = PathGenerator(maxPathLength: 3, maxPaths: 100)
        let paths = generator.generatePaths(strategy: .systematic)
        
        let uniquePaths = Set(paths)
        XCTAssertEqual(uniquePaths.count, paths.count, "Paths should be unique")
    }
    
    func testEmptyUnexploredDoors() {
        let generator = PathGenerator(maxPathLength: 5, maxPaths: 10)
        let paths = generator.generatePaths(strategy: .targeted(unexploredDoors: []))
        
        XCTAssertFalse(paths.isEmpty)
        XCTAssertEqual(paths.count, 10)
    }
}