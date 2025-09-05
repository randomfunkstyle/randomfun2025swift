import Foundation

/// Generates exploration paths using various strategies
/// Paths are sequences of door numbers (0-5) to traverse
public class PathGenerator {
    /// Strategy for generating exploration paths
    public enum Strategy {
        /// Simple paths: single doors, pairs, and some random
        case basic
        /// Breadth-first systematic exploration
        case systematic
        /// Focus on specific unexplored areas
        case targeted(unexploredDoors: [(room: Int, door: Int)])
    }
    
    /// Maximum number of doors in a single path
    private let maxPathLength: Int
    /// Maximum number of paths to generate in one batch
    private let maxPaths: Int
    
    /// Initialize with path generation constraints
    public init(maxPathLength: Int = 10, maxPaths: Int = 100) {
        self.maxPathLength = maxPathLength
        self.maxPaths = maxPaths
    }
    
    public func generatePaths(strategy: Strategy) -> [String] {
        switch strategy {
        case .basic:
            return generateBasicPaths()
        case .systematic:
            return generateSystematicPaths()
        case .targeted(let unexploredDoors):
            return generateTargetedPaths(unexploredDoors: unexploredDoors)
        }
    }
    
    /// Generate basic exploration paths
    /// Includes all single doors, all door pairs, and some random paths
    private func generateBasicPaths() -> [String] {
        var paths: [String] = []
        
        // All single door explorations (0-5)
        for door in 0..<6 {
            paths.append(String(door))
        }
        
        // All two-door combinations (00-55)
        for door1 in 0..<6 {
            for door2 in 0..<6 {
                paths.append("\(door1)\(door2)")
            }
        }
        
        // Add some random longer paths for discovery
        for _ in 0..<10 {
            let randomPath = (0..<5).map { _ in String(Int.random(in: 0..<6)) }.joined()
            paths.append(randomPath)
        }
        
        return Array(paths.prefix(maxPaths))
    }
    
    /// Generate paths systematically using breadth-first approach
    /// Ensures complete coverage at each depth level
    private func generateSystematicPaths() -> [String] {
        var paths: [String] = []
        var queue: [(path: String, depth: Int)] = []
        
        // Start with all single doors
        for door in 0..<6 {
            queue.append((String(door), 1))
        }
        
        // BFS expansion
        while !queue.isEmpty && paths.count < maxPaths {
            let (currentPath, depth) = queue.removeFirst()
            paths.append(currentPath)
            
            // Expand to next level if not at max depth
            if depth < maxPathLength {
                for door in 0..<6 {
                    queue.append((currentPath + String(door), depth + 1))
                }
            }
        }
        
        return Array(paths.prefix(maxPaths))
    }
    
    /// Generate paths targeting specific unexplored areas
    /// Focuses on doors we haven't explored yet
    private func generateTargetedPaths(unexploredDoors: [(room: Int, door: Int)]) -> [String] {
        var paths: [String] = []
        
        // For each unexplored door, generate focused paths
        for (_, door) in unexploredDoors.prefix(10) {
            // Direct exploration
            paths.append(String(door))
            
            // Explore what's beyond that door
            for nextDoor in 0..<6 {
                paths.append("\(door)\(nextDoor)")
            }
            
            // Extended exploration from that door
            let extendedPath = "\(door)" + (0..<3).map { _ in String(Int.random(in: 0..<6)) }.joined()
            paths.append(extendedPath)
        }
        
        // Fill remaining slots with random paths
        while paths.count < maxPaths {
            let length = min(Int.random(in: 1...maxPathLength), maxPathLength)
            let randomPath = (0..<length).map { _ in String(Int.random(in: 0..<6)) }.joined()
            paths.append(randomPath)
        }
        
        return Array(paths.prefix(maxPaths))
    }
    
    /// Generate all paths up to a certain depth using BFS
    /// Useful for exhaustive exploration of nearby rooms
    public func generateBreadthFirstPaths(depth: Int) -> [String] {
        guard depth > 0 else { return [] }
        
        var paths: [String] = []
        var currentLevel: [String] = [""]
        
        // Generate each level of the BFS tree
        for _ in 0..<depth {
            var nextLevel: [String] = []
            
            // Expand each path at current level
            for path in currentLevel {
                for door in 0..<6 {
                    let newPath = path + String(door)
                    nextLevel.append(newPath)
                    paths.append(newPath)
                }
            }
            
            currentLevel = nextLevel
            
            // Stop if we've generated enough paths
            if paths.count >= maxPaths {
                break
            }
        }
        
        return Array(paths.prefix(maxPaths))
    }
    
    /// Generate paths using depth-first search with limited branching
    /// Good for exploring deep into the graph quickly
    public func generateDepthFirstPaths(maxDepth: Int, branchingFactor: Int = 2) -> [String] {
        var paths: [String] = []
        
        /// Recursive DFS helper
        func dfs(currentPath: String, depth: Int) {
            // Stop if we have enough paths
            if paths.count >= maxPaths {
                return
            }
            
            // Add non-empty paths
            if depth > 0 && !currentPath.isEmpty {
                paths.append(currentPath)
            }
            
            // Continue deeper if not at max depth
            if depth < maxDepth {
                // Randomly select doors to explore (limited branching)
                let doors = (0..<6).shuffled().prefix(branchingFactor)
                for door in doors {
                    dfs(currentPath: currentPath + String(door), depth: depth + 1)
                }
            }
        }
        
        dfs(currentPath: "", depth: 0)
        
        return Array(paths.prefix(maxPaths))
    }
}