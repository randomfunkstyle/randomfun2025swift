import XCTest
@testable import ICFPWorkerLib

final class GeneratePathsTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Generates all single digit paths for depth=1
    func testGeneratesAllSingleDigitPaths() {
        let paths = matcher.generatePaths(depth: 1)
        
        XCTAssertEqual(paths.count, 6)
        XCTAssertEqual(paths, ["0", "1", "2", "3", "4", "5"])
    }
    
    // Test 2: Generates correct depth-2 count (strategic subset, not all 36)
    func testGeneratesCorrectDepth2Count() {
        let paths = matcher.generatePaths(depth: 2)
        
        // Should be 18 paths: 6 identity + 6 adjacent + 6 skip
        XCTAssertEqual(paths.count, 18)
        
        // Check for identity patterns
        XCTAssertTrue(paths.contains("00"))
        XCTAssertTrue(paths.contains("11"))
        XCTAssertTrue(paths.contains("22"))
        XCTAssertTrue(paths.contains("33"))
        XCTAssertTrue(paths.contains("44"))
        XCTAssertTrue(paths.contains("55"))
        
        // Check for some adjacent patterns
        XCTAssertTrue(paths.contains("01"))
        XCTAssertTrue(paths.contains("12"))
        
        // Check for some skip patterns
        XCTAssertTrue(paths.contains("02"))
        XCTAssertTrue(paths.contains("13"))
    }
    
    // Test 3: Generates no empty paths
    func testGeneratesNoEmptyPaths() {
        for depth in 1...3 {
            let paths = matcher.generatePaths(depth: depth)
            for path in paths {
                XCTAssertFalse(path.isEmpty, "No empty paths should be generated")
            }
        }
    }
    
    // Test 4: Paths are unique (no duplicates)
    func testPathsAreUnique() {
        for depth in 1...3 {
            let paths = matcher.generatePaths(depth: depth)
            let uniquePaths = Set(paths)
            XCTAssertEqual(paths.count, uniquePaths.count, "All paths should be unique at depth \(depth)")
        }
    }
    
    // Test 5: Depth 0 returns empty array
    func testDepth0ReturnsEmptyArray() {
        let paths = matcher.generatePaths(depth: 0)
        XCTAssertEqual(paths.count, 0)
        XCTAssertEqual(paths, [])
    }
    
    // Test 6: Negative depth returns empty (error handling)
    func testNegativeDepthReturnsEmpty() {
        let paths = matcher.generatePaths(depth: -1)
        XCTAssertEqual(paths.count, 0)
    }
    
    // Test 7: Depth beyond limit returns empty
    func testDepthBeyondLimitReturnsEmpty() {
        let paths = matcher.generatePaths(depth: 4)
        XCTAssertEqual(paths.count, 0, "Depth beyond 3 should return empty")
        
        let paths5 = matcher.generatePaths(depth: 5)
        XCTAssertEqual(paths5.count, 0)
    }
    
    // Test 8: All paths have correct length
    func testAllPathsHaveCorrectLength() {
        for depth in 1...3 {
            let paths = matcher.generatePaths(depth: depth)
            for path in paths {
                XCTAssertEqual(path.count, depth, "All paths at depth \(depth) should have length \(depth)")
            }
        }
    }
    
    // Test 9: All paths use valid door numbers (0-5)
    func testAllPathsUseValidDoorNumbers() {
        for depth in 1...3 {
            let paths = matcher.generatePaths(depth: depth)
            for path in paths {
                for char in path {
                    if let door = Int(String(char)) {
                        XCTAssertTrue(door >= 0 && door < 6, "Door number should be 0-5")
                    } else {
                        XCTFail("Invalid character in path: \(char)")
                    }
                }
            }
        }
    }
    
    // Test 10: Depth 3 generates expected patterns
    func testDepth3GeneratesExpectedPatterns() {
        let paths = matcher.generatePaths(depth: 3)
        
        // Should have 24 paths: 6 triple + 6 pattern1 + 6 pattern2 + 6 sequential
        XCTAssertEqual(paths.count, 24)
        
        // Check for triple same door
        XCTAssertTrue(paths.contains("000"))
        XCTAssertTrue(paths.contains("111"))
        XCTAssertTrue(paths.contains("555"))
        
        // Check for pattern: door, same, different
        XCTAssertTrue(paths.contains("001"))
        XCTAssertTrue(paths.contains("112"))
        
        // Check for pattern: door, different, same
        XCTAssertTrue(paths.contains("011"))
        XCTAssertTrue(paths.contains("122"))
        
        // Check for sequential patterns
        XCTAssertTrue(paths.contains("012"))
        XCTAssertTrue(paths.contains("123"))
    }
    
    // Test 11: Performance - should generate quickly
    func testGenerationPerformance() {
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = matcher.generatePaths(depth: 3)
        }
        
        let endTime = Date()
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(timeInterval, 0.1, "Should generate paths quickly")
    }
    
    // Test 12: Consistency - same depth always produces same paths
    func testConsistentGeneration() {
        for depth in 1...3 {
            let paths1 = matcher.generatePaths(depth: depth)
            let paths2 = matcher.generatePaths(depth: depth)
            let paths3 = matcher.generatePaths(depth: depth)
            
            XCTAssertEqual(paths1, paths2, "Same depth should produce same paths")
            XCTAssertEqual(paths2, paths3, "Generation should be consistent")
        }
    }
}