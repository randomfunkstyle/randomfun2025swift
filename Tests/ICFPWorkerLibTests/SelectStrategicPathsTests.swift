import XCTest
@testable import ICFPWorkerLib

final class SelectStrategicPathsTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Hamming strategy selects correct subset
    func testHammingStrategySelectsCorrectSubset() {
        let allPaths = ["0", "1", "2", "3", "4", "5", "00", "01", "02", "10", "11", "12", "20", "21", "22"]
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .hammingLike)
        
        // Should include all single-door paths
        XCTAssertTrue(selected.contains("0"))
        XCTAssertTrue(selected.contains("1"))
        XCTAssertTrue(selected.contains("5"))
        
        // Should include identity patterns
        XCTAssertTrue(selected.contains("00"))
        XCTAssertTrue(selected.contains("11"))
        XCTAssertTrue(selected.contains("22"))
        
        // Should include some but not all other patterns
        XCTAssertLessThan(selected.count, allPaths.count)
        XCTAssertGreaterThan(selected.count, 6) // More than just single doors
    }
    
    // Test 2: Exhaustive strategy returns all paths
    func testExhaustiveStrategyReturnsAll() {
        let allPaths = ["0", "1", "2", "00", "01", "02", "11", "12", "22"]
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .exhaustive)
        
        XCTAssertEqual(selected.count, allPaths.count)
        XCTAssertEqual(Set(selected), Set(allPaths))
    }
    
    // Test 3: Minimal strategy returns smallest set
    func testMinimalStrategyReturnsSmallestSet() {
        let allPaths = (0..<30).map { String($0) }
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .minimal)
        
        // Should return approximately 1/3 of paths
        XCTAssertEqual(selected.count, 10) // 30 / 3
        XCTAssertEqual(selected, Array(allPaths.prefix(10)))
    }
    
    // Test 4: Empty input returns empty
    func testEmptyInputReturnsEmpty() {
        let selected = matcher.selectStrategicPaths(allPaths: [], strategy: .hammingLike)
        XCTAssertEqual(selected.count, 0)
        
        let selectedExhaustive = matcher.selectStrategicPaths(allPaths: [], strategy: .exhaustive)
        XCTAssertEqual(selectedExhaustive.count, 0)
        
        let selectedMinimal = matcher.selectStrategicPaths(allPaths: [], strategy: .minimal)
        XCTAssertEqual(selectedMinimal.count, 0)
    }
    
    // Test 5: Single path handling
    func testSinglePathHandling() {
        let allPaths = ["0"]
        
        let hammingSelected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .hammingLike)
        XCTAssertEqual(hammingSelected, ["0"])
        
        let exhaustiveSelected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .exhaustive)
        XCTAssertEqual(exhaustiveSelected, ["0"])
        
        let minimalSelected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .minimal)
        XCTAssertEqual(minimalSelected, ["0"])
    }
    
    // Test 6: Hamming preserves all single-door paths
    func testHammingPreservesSingleDoorPaths() {
        let allPaths = ["0", "1", "2", "3", "4", "5", "000", "111", "222"]
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .hammingLike)
        
        // All single-door paths should be included
        for i in 0..<6 {
            XCTAssertTrue(selected.contains(String(i)), "Should include single door path \(i)")
        }
    }
    
    // Test 7: Hamming includes identity patterns for depth 2
    func testHammingIncludesIdentityPatterns() {
        var allPaths: [String] = []
        // Add identity patterns
        for i in 0..<6 {
            allPaths.append("\(i)\(i)")
        }
        // Add non-identity patterns
        for i in 0..<6 {
            let next = (i + 1) % 6
            allPaths.append("\(i)\(next)")
        }
        
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .hammingLike)
        
        // All identity patterns should be selected
        for i in 0..<6 {
            XCTAssertTrue(selected.contains("\(i)\(i)"), "Should include identity pattern \(i)\(i)")
        }
    }
    
    // Test 8: Performance with large input
    func testPerformanceWithLargeInput() {
        // Generate many paths
        var allPaths: [String] = []
        for i in 0..<1000 {
            allPaths.append(String(i))
        }
        
        let startTime = Date()
        _ = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .hammingLike)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.1, "Should process large input quickly")
    }
    
    // Test 9: Maintains order for exhaustive strategy
    func testMaintainsOrderForExhaustive() {
        let allPaths = ["5", "3", "1", "4", "2", "0"]
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .exhaustive)
        
        XCTAssertEqual(selected, allPaths, "Exhaustive should maintain input order")
    }
    
    // Test 10: Minimal strategy with small input
    func testMinimalStrategyWithSmallInput() {
        let allPaths = ["0", "1"]
        let selected = matcher.selectStrategicPaths(allPaths: allPaths, strategy: .minimal)
        
        // With only 2 paths, should return at least 1
        XCTAssertEqual(selected.count, 1)
        XCTAssertEqual(selected, ["0"])
    }
}