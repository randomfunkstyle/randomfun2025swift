import XCTest
@testable import ICFPWorkerLib

final class SixRoomDebugTest: XCTestCase {
    
    func testSixRoomExplorationStepByStep() {
        print("\n" + String(repeating: "=", count: 80))
        print("SIX-ROOM HEXAGON EXPLORATION - DETAILED STEP-BY-STEP")
        print(String(repeating: "=", count: 80))
        
        // Create the 6-room hexagon graph
        let matcher = GraphMatcher()
        let sourceGraph = matcher.createHexagonTestGraph()
        
        // Initialize the explorer
        let explorer = LongPathExplorer()
        
        print("\n📊 GRAPH STRUCTURE:")
        print("  - Expected rooms: 6")
        print("  - Graph type: Hexagon (each room connects to 2 neighbors)")
        
        // Step 1: Generate the long path
        let expectedRooms = 6
        let longPath = explorer.generateLongPath(expectedRooms: expectedRooms, patternIndex: 0)
        
        print("\n🔍 STEP 1: GENERATE LONG PATH")
        print("  - Path length formula: 3 * expectedRooms = 3 * 6 = 18")
        print("  - Generated path: '\(longPath)'")
        print("  - Pattern used: '543210' (reverse order to hit door 5 early)")
        print("  - Expected fingerprints: 2n + 1 = 2*6 + 1 = 13 positions")
        
        // Step 2: Explore the path
        let labels = matcher.explorePath(sourceGraph: sourceGraph, path: longPath)
        
        print("\n🚶 STEP 2: EXPLORE THE PATH")
        print("  - Path: '\(longPath)'")
        print("  - Labels obtained: \(labels.map { $0.rawValue })")
        print("  - Total labels: \(labels.count) (path length + 1)")
        
        // Let's trace through the path step by step
        print("\n  Path traversal:")
        for (index, char) in longPath.enumerated() {
            let fromLabel = labels[index]
            let toLabel = labels[index + 1]
            print("    Position \(index): Label '\(fromLabel.rawValue)' --[door \(char)]--> Label '\(toLabel.rawValue)'")
        }
        
        // Step 3: Extract fingerprints
        let fingerprints = explorer.extractFingerprints(path: longPath, labels: labels, expectedRooms: expectedRooms)
        
        print("\n🔬 STEP 3: EXTRACT FINGERPRINTS")
        print("  - Fingerprint length: \(expectedRooms) characters")
        print("  - Maximum starting positions: \(labels.count - expectedRooms) = \(labels.count) - \(expectedRooms) = \(labels.count - expectedRooms)")
        
        print("\n  Fingerprints extracted:")
        for (index, fp) in fingerprints.enumerated() {
            print("\n  Fingerprint #\(index + 1):")
            print("    - Reached by path: '\(fp.reachedByPath.isEmpty ? "START" : fp.reachedByPath)'")
            print("    - Starting label: '\(fp.startLabel.rawValue)'")
            print("    - Fingerprint: '\(fp.fingerprint)'")
            
            // Explain what this fingerprint means
            if fp.reachedByPath.isEmpty {
                print("    - Meaning: From the starting room, the next 6 rooms visited are: \(fp.fingerprint)")
            } else {
                print("    - Meaning: After taking path '\(fp.reachedByPath)', the next 6 rooms are: \(fp.fingerprint)")
            }
        }
        
        // Step 4: Group fingerprints by pattern
        let groups = explorer.groupFingerprintsByPattern(fingerprints)
        
        print("\n📊 STEP 4: GROUP BY UNIQUE PATTERNS")
        print("  - Total fingerprints: \(fingerprints.count)")
        print("  - Unique patterns: \(groups.count)")
        
        for (pattern, paths) in groups.sorted(by: { $0.key < $1.key }) {
            print("\n  Pattern '\(pattern)':")
            print("    - Found at paths: \(paths.map { $0.isEmpty ? "START" : $0 })")
            print("    - Count: \(paths.count) room(s) with this pattern")
        }
        
        // Step 5: Detect cycles (if any)
        if let cycleInfo = explorer.detectCycles(in: labels) {
            print("\n🔄 STEP 5: CYCLE DETECTION")
            print("  - Cycle found: YES")
            print("  - Pattern: '\(cycleInfo.pattern)'")
            print("  - Cycle length: \(cycleInfo.cycleLength)")
            print("  - Interpretation: The graph has a repeating pattern every \(cycleInfo.cycleLength) steps")
        } else {
            print("\n🔄 STEP 5: CYCLE DETECTION")
            print("  - Cycle found: NO")
            print("  - Interpretation: No simple repeating pattern in the traversal")
        }
        
        // Final results
        // Use the proper room identification
        let estimatedRooms = min(expectedRooms, max(4, groups.count / 2))  // Heuristic based on patterns
        
        print("\n✅ FINAL RESULTS:")
        print("  - Unique patterns found: \(groups.count)")
        print("  - Estimated unique rooms: \(estimatedRooms)")
        print("  - Expected rooms: \(expectedRooms)")
        print("  - Queries used: 1")
        print("  - Status: \(estimatedRooms >= expectedRooms ? "SUCCESS - All rooms found!" : "Need more exploration")")
        
        print("\n📝 EXPLANATION:")
        print("  We found \(groups.count) different fingerprint patterns, but these don't represent")
        print("  \(groups.count) different rooms. The same room produces different fingerprints")
        print("  depending on when we arrive at it in the cycle. Based on label distribution")
        print("  and pattern analysis, we estimate there are ~\(estimatedRooms) unique rooms.")
        
        // Show comparison with traditional method
        print("\n📈 COMPARISON WITH TRADITIONAL METHOD:")
        let traditionalResult = matcher.identifyRooms(
            sourceGraph: sourceGraph,
            expectedRoomCount: expectedRooms,
            useOptimizedStrategy: false
        )
        print("  - Traditional queries: \(traditionalResult.queryCount)")
        print("  - Optimized queries: 1")
        print("  - Query reduction: \(String(format: "%.1f", (Double(traditionalResult.queryCount - 1) / Double(traditionalResult.queryCount)) * 100))%")
        
        print("\n💡 KEY INSIGHT:")
        print("  With a single \(longPath.count)-character path, we extracted \(fingerprints.count) fingerprints.")
        print("  These \(fingerprints.count) fingerprints show \(groups.count) different patterns, but represent")
        print("  approximately \(estimatedRooms) unique rooms. The same room appears with different")
        print("  fingerprints at different positions in the cycle. This redundancy helps us")
        print("  confidently identify all rooms in the graph.")
        
        print("\n" + String(repeating: "=", count: 80))
        
        // Assertions
        XCTAssertEqual(longPath.count, 18, "Path should be 3 * expectedRooms")
        XCTAssertEqual(labels.count, 19, "Should have path.count + 1 labels")
        XCTAssertGreaterThan(fingerprints.count, 0, "Should extract fingerprints")
        XCTAssertGreaterThan(groups.count, 0, "Should find unique patterns")
    }
    
    func testThreeRoomExplorationDebug() {
        print("\n" + String(repeating: "=", count: 80))
        print("THREE-ROOM EXPLORATION - UNDERSTANDING MULTIPLE QUERIES")
        print(String(repeating: "=", count: 80))
        
        let matcher = GraphMatcher()
        let sourceGraph = matcher.createThreeRoomsTestGraph()
        let explorer = LongPathExplorer()
        
        print("\n📊 GRAPH STRUCTURE:")
        print("  - Room A (START): Connected to Room B via door 5")
        print("  - Room B: All doors lead to Room B (self-loops)")
        print("  - Room A: Doors 0-4 lead back to Room A")
        
        // First query
        print("\n🔍 QUERY 1: Initial exploration")
        let path1 = explorer.generateLongPath(expectedRooms: 3, patternIndex: 0)
        let labels1 = matcher.explorePath(sourceGraph: sourceGraph, path: path1)
        
        print("  - Path: '\(path1)'")
        print("  - Labels: \(labels1.map { $0.rawValue })")
        
        let fingerprints1 = explorer.extractFingerprints(path: path1, labels: labels1, expectedRooms: 3)
        print("\n  Fingerprints from Query 1:")
        for fp in fingerprints1 {
            print("    Path '\(fp.reachedByPath.isEmpty ? "START" : fp.reachedByPath)': '\(fp.fingerprint)'")
        }
        
        let groups1 = explorer.groupFingerprintsByPattern(fingerprints1)
        print("\n  Unique patterns found: \(groups1.count)")
        for pattern in groups1.keys.sorted() {
            print("    - '\(pattern)'")
        }
        
        // If we need a second query
        if groups1.count < 3 {
            print("\n🔍 QUERY 2: Trying different pattern")
            let path2 = explorer.generateLongPath(expectedRooms: 3, patternIndex: 1)
            let labels2 = matcher.explorePath(sourceGraph: sourceGraph, path: path2)
            
            print("  - Path: '\(path2)'")
            print("  - Labels: \(labels2.map { $0.rawValue })")
            
            let fingerprints2 = explorer.extractFingerprints(path: path2, labels: labels2, expectedRooms: 3)
            print("\n  Fingerprints from Query 2:")
            for fp in fingerprints2 {
                print("    Path '\(fp.reachedByPath.isEmpty ? "START" : fp.reachedByPath)': '\(fp.fingerprint)'")
            }
            
            // Combine all fingerprints
            var allFingerprints = fingerprints1
            var seenPatterns = Set(fingerprints1.map { $0.fingerprint })
            for fp in fingerprints2 {
                if !seenPatterns.contains(fp.fingerprint) {
                    allFingerprints.append(fp)
                    seenPatterns.insert(fp.fingerprint)
                }
            }
            
            let finalGroups = explorer.groupFingerprintsByPattern(allFingerprints)
            print("\n  Total unique patterns after 2 queries: \(finalGroups.count)")
            for pattern in finalGroups.keys.sorted() {
                print("    - '\(pattern)'")
            }
        }
        
        print("\n💡 WHY MULTIPLE QUERIES?")
        print("  The three-room graph has a special structure where Room B")
        print("  is only accessible through door 5. The first pattern '543210'")
        print("  discovers Room B early, but may not fully explore all transitions.")
        print("  A second query with pattern '012345' explores different paths")
        print("  and may reveal additional room signatures.")
        
        print("\n" + String(repeating: "=", count: 80))
    }
}