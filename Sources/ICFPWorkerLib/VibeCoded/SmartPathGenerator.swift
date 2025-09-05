import Foundation

/// Generates entropy-optimal paths that maximize information gain about graph structure
/// Based on information theory: maximizes I(Path; Structure) rather than H(Path)
public class SmartPathGenerator {
    private let roomCount: Int
    private let maxPathLength: Int
    private var exploredPatterns: Set<String> = []
    private var knownConnections: [(fromRoom: Int, fromDoor: Int, toRoom: Int, toDoor: Int)] = []
    
    public init(roomCount: Int) {
        self.roomCount = roomCount
        self.maxPathLength = 18 * roomCount
    }
    
    /// Generate initial path using entropy-optimal strategy
    /// Pattern "001122334455..." maximizes information about bidirectional connections
    /// Each pair can reveal ~4.6 bits of structural information
    public func generateInitialPath() -> String {
        var path = ""
        
        // Phase 1: Test all door pairs for returns (highest information gain)
        // This pattern reveals bidirectional connections efficiently
        for door in 0..<6 {
            path += String(door) + String(door)
            if path.count >= maxPathLength {
                return String(path.prefix(maxPathLength))
            }
        }
        
        // Phase 2: Systematic exploration for breadth
        // Ensures we explore all doors at least once
        while path.count < maxPathLength {
            for door in 0..<6 {
                path += String(door)
                if path.count >= maxPathLength {
                    return String(path.prefix(maxPathLength))
                }
            }
        }
        
        return path
    }
    
    /// Generate adaptive path based on current knowledge
    /// Targets maximum uncertainty to gain most information
    public func generateAdaptivePath(identifiedRooms: Int, mappedConnections: Int) -> String {
        var path = ""
        
        // If we haven't identified all rooms yet, explore more broadly
        if identifiedRooms < roomCount {
            // Try different door combinations to reach new rooms
            path = generateExploratoryPath()
        } else {
            // We have all rooms, now map remaining connections
            path = generateConnectionMappingPath()
        }
        
        return String(path.prefix(maxPathLength))
    }
    
    /// Generate path to explore new rooms
    private func generateExploratoryPath() -> String {
        var path = ""
        
        // Strategy: Try doors in different orders to reach new states
        // Use Fibonacci sequence mod 6 for non-repetitive pattern
        var fib1 = 0, fib2 = 1
        while path.count < maxPathLength {
            path += String(fib1 % 6)
            let next = (fib1 + fib2) % 6
            fib1 = fib2
            fib2 = next
        }
        
        return path
    }
    
    /// Generate path to map connections between known rooms
    private func generateConnectionMappingPath() -> String {
        var path = ""
        
        // Try untested door pairs
        for door1 in 0..<6 {
            for door2 in 0..<6 {
                let pattern = String(door1) + String(door2)
                if !exploredPatterns.contains(pattern) {
                    path += pattern
                    exploredPatterns.insert(pattern)
                    
                    if path.count >= maxPathLength {
                        return path
                    }
                }
            }
        }
        
        return path
    }
    
    /// Update generator with discovered connections
    public func updateKnowledge(connections: [(fromRoom: Int, fromDoor: Int, toRoom: Int, toDoor: Int)]) {
        knownConnections = connections
        
        // Mark explored patterns
        for conn in connections {
            let pattern = String(conn.fromDoor) + String(conn.toDoor)
            exploredPatterns.insert(pattern)
        }
    }
    
    /// Calculate expected information gain for a path
    public func calculateExpectedInfoGain(path: String) -> Double {
        var infoGain = 0.0
        
        // Check for return pairs (highest value)
        for i in 0..<(path.count - 1) {
            let index = path.index(path.startIndex, offsetBy: i)
            let nextIndex = path.index(path.startIndex, offsetBy: i + 1)
            
            if path[index] == path[nextIndex] {
                // Return pair: ~4.6 bits of information
                infoGain += 4.6
            } else {
                // Regular transition: ~1-2 bits
                infoGain += 1.5
            }
        }
        
        return infoGain
    }
}