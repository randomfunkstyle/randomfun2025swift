import XCTest
@testable import ICFPWorkerLib

final class HashSignatureTests: XCTestCase {
    
    var matcher: GraphMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = GraphMatcher()
    }
    
    // Test 1: Identical signatures produce same hash
    func testIdenticalSignaturesSameHash() {
        let pathLabels1: [String: RoomLabel] = ["0": .A, "1": .B, "5": .C]
        let signature1 = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels1
        )
        
        let pathLabels2: [String: RoomLabel] = ["0": .A, "1": .B, "5": .C]
        let signature2 = NodeSignature(
            nodeId: 2, // Different node ID but same pattern
            pathLabels: pathLabels2
        )
        
        let hash1 = matcher.hashSignature(signature: signature1)
        let hash2 = matcher.hashSignature(signature: signature2)
        
        XCTAssertEqual(hash1, hash2, "Identical signatures should produce the same hash")
    }
    
    // Test 2: Different signatures produce different hashes
    func testDifferentSignaturesDifferentHash() {
        let pathLabels1: [String: RoomLabel] = ["0": .A, "1": .B]
        let signature1 = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels1
        )
        
        let pathLabels2: [String: RoomLabel] = ["0": .A, "1": .C] // Different label for path "1"
        let signature2 = NodeSignature(
            nodeId: 2,
            pathLabels: pathLabels2
        )
        
        let hash1 = matcher.hashSignature(signature: signature1)
        let hash2 = matcher.hashSignature(signature: signature2)
        
        XCTAssertNotEqual(hash1, hash2, "Different signatures should produce different hashes")
    }
    
    // Test 3: Hash is deterministic
    func testHashDeterministic() {
        let pathLabels: [String: RoomLabel] = ["0": .A, "1": .B, "2": .C, "3": .D]
        let signature = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels
        )
        
        // Compute hash multiple times
        let hash1 = matcher.hashSignature(signature: signature)
        let hash2 = matcher.hashSignature(signature: signature)
        let hash3 = matcher.hashSignature(signature: signature)
        
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash2, hash3)
    }
    
    // Test 4: Handles empty signature
    func testHashHandlesEmptySignature() {
        let signature = NodeSignature(
            nodeId: 1,
            pathLabels: [:]
        )
        
        let hash = matcher.hashSignature(signature: signature)
        
        XCTAssertEqual(hash, "", "Empty signature should produce empty hash")
    }
    
    // Test 5: Hash performance is O(paths)
    func testHashPerformance() {
        // Create signature with many paths
        var pathLabels: [String: RoomLabel] = [:]
        for i in 0..<100 {
            pathLabels[String(i)] = RoomLabel.allCases.randomElement()!
        }
        
        let signature = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels
        )
        
        // Measure time
        let startTime = Date()
        _ = matcher.hashSignature(signature: signature)
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 0.01, "Hash computation should be fast")
    }
    
    // Test 6: Hash collision rate should be near zero
    func testHashCollisionRate() {
        var hashes = Set<String>()
        
        // Generate many different signatures
        for i in 0..<100 {
            var pathLabels: [String: RoomLabel] = [:]
            
            // Create unique patterns by varying combinations
            pathLabels["0"] = RoomLabel(fromInt: i % 4)!
            pathLabels["1"] = RoomLabel(fromInt: (i / 4) % 4)!
            pathLabels["2"] = RoomLabel(fromInt: (i / 16) % 4)!
            
            // Add additional variation for larger numbers
            if i >= 64 {
                pathLabels["3"] = RoomLabel(fromInt: (i / 64) % 4)!
            }
            
            let signature = NodeSignature(
                nodeId: i,
                pathLabels: pathLabels
            )
            
            let hash = matcher.hashSignature(signature: signature)
            hashes.insert(hash)
        }
        
        // All hashes should be unique for different signatures
        XCTAssertEqual(hashes.count, 100, "Should have no collisions for different signatures")
    }
    
    // Test 7: Order of paths in hash is consistent
    func testHashPathOrderConsistent() {
        let pathLabels: [String: RoomLabel] = ["0": .A, "1": .B, "5": .C, "00": .A, "55": .D]
        let signature = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels
        )
        
        let hash = matcher.hashSignature(signature: signature)
        
        // Should be sorted: "0", "00", "1", "5", "55"
        XCTAssertEqual(hash, "0:A|00:A|1:B|5:C|55:D")
    }
    
    // Test 8: Hash ignores node ID (only cares about pattern)
    func testHashIgnoresNodeId() {
        let pathLabels: [String: RoomLabel] = ["0": .A, "1": .B]
        
        let signature1 = NodeSignature(
            nodeId: 100,
            pathLabels: pathLabels
        )
        
        let signature2 = NodeSignature(
            nodeId: 999,
            pathLabels: pathLabels
        )
        
        let hash1 = matcher.hashSignature(signature: signature1)
        let hash2 = matcher.hashSignature(signature: signature2)
        
        XCTAssertEqual(hash1, hash2, "Node ID should not affect hash")
    }
    
    // Test 9: Hash handles all label types
    func testHashHandlesAllLabels() {
        let pathLabels: [String: RoomLabel] = [
            "0": .A,
            "1": .B,
            "2": .C,
            "3": .D
        ]
        
        let signature = NodeSignature(
            nodeId: 1,
            pathLabels: pathLabels
        )
        
        let hash = matcher.hashSignature(signature: signature)
        
        XCTAssertTrue(hash.contains("0:A"))
        XCTAssertTrue(hash.contains("1:B"))
        XCTAssertTrue(hash.contains("2:C"))
        XCTAssertTrue(hash.contains("3:D"))
    }
    
    // Test 10: Real-world signature from three rooms graph
    func testHashWithThreeRoomsGraph() {
        let graph = matcher.createThreeRoomsTestGraph()
        let startNode = graph.getNode(graph.startingNodeId)!
        
        let paths = ["0", "1", "5", "55"]
        let signature = matcher.computeNodeSignature(node: startNode, paths: paths, graph: graph)
        
        let hash = matcher.hashSignature(signature: signature)
        
        // Hash should be non-empty and contain the path:label pairs
        XCTAssertFalse(hash.isEmpty)
        XCTAssertTrue(hash.contains(":"))
        XCTAssertTrue(hash.contains("|"))
    }
}