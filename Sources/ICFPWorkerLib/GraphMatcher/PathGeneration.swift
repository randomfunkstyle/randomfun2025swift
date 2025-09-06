import Foundation

/// Strategy for selecting paths
public enum PathSelectionStrategy {
    case hammingLike  // Select ~30% using base-6 patterns
    case exhaustive   // Return all paths
    case minimal      // Return smallest distinguishing set
}

extension GraphMatcher {
    /// Generate all base-6 paths for a given depth
    /// - Parameter depth: The depth of paths to generate (0-3)
    /// - Returns: Array of path strings
    /// - Note: For depth=1 returns ["0","1","2","3","4","5"]
    ///         For depth=2 returns strategic subset (not all 36)
    public func generatePaths(depth: Int) -> [String] {
        guard depth > 0 else { return [] }
        guard depth <= 3 else { return [] } // Limit depth for performance
        
        if depth == 1 {
            // All single-door paths
            return (0..<6).map { String($0) }
        }
        
        if depth == 2 {
            // Strategic selection for depth 2
            var paths: [String] = []
            
            // Identity patterns (same door twice)
            for i in 0..<6 {
                paths.append("\(i)\(i)")
            }
            
            // Adjacent pairs (circular)
            for i in 0..<6 {
                let next = (i + 1) % 6
                paths.append("\(i)\(next)")
            }
            
            // Skip patterns (jump by 2)
            for i in 0..<6 {
                let skip = (i + 2) % 6
                paths.append("\(i)\(skip)")
            }
            
            return paths
        }
        
        if depth == 3 {
            // For depth 3, generate a strategic subset
            var paths: [String] = []
            
            // Triple same door
            for i in 0..<6 {
                paths.append("\(i)\(i)\(i)")
            }
            
            // Pattern: door, same, different
            for i in 0..<6 {
                let next = (i + 1) % 6
                paths.append("\(i)\(i)\(next)")
            }
            
            // Pattern: door, different, same
            for i in 0..<6 {
                let next = (i + 1) % 6
                paths.append("\(i)\(next)\(next)")
            }
            
            // Pattern: three different sequential
            for i in 0..<6 {
                let next1 = (i + 1) % 6
                let next2 = (i + 2) % 6
                paths.append("\(i)\(next1)\(next2)")
            }
            
            return paths
        }
        
        return []
    }
    
    /// Filter paths based on selection strategy
    /// - Parameters:
    ///   - allPaths: The complete set of paths to filter
    ///   - strategy: The strategy to use for filtering
    /// - Returns: Filtered subset of paths
    public func selectStrategicPaths(allPaths: [String], strategy: PathSelectionStrategy) -> [String] {
        switch strategy {
        case .exhaustive:
            // Return all paths unchanged
            return allPaths
            
        case .minimal:
            // Return smallest distinguishing set
            // For now, just take first third of paths
            let count = max(1, allPaths.count / 3)
            return Array(allPaths.prefix(count))
            
        case .hammingLike:
            // Select approximately 30% of paths using Hamming-like distribution
            // This ensures good coverage while minimizing redundancy
            
            if allPaths.isEmpty { return [] }
            
            // Group paths by length
            var pathsByLength: [Int: [String]] = [:]
            for path in allPaths {
                let length = path.count
                if pathsByLength[length] == nil {
                    pathsByLength[length] = []
                }
                pathsByLength[length]?.append(path)
            }
            
            var selectedPaths: [String] = []
            
            // For each length group, select strategically
            for (length, paths) in pathsByLength {
                if length == 0 {
                    // Always include empty path if present
                    selectedPaths.append(contentsOf: paths)
                } else if length == 1 {
                    // Include all single-door paths
                    selectedPaths.append(contentsOf: paths)
                } else if length == 2 {
                    // For depth 2, include patterns that maximize information
                    for path in paths {
                        let chars = Array(path)
                        if chars[0] == chars[1] {
                            // Identity patterns (same door twice)
                            selectedPaths.append(path)
                        } else if let first = Int(String(chars[0])),
                                  let second = Int(String(chars[1])) {
                            // Include if they form specific patterns
                            let diff = (second - first + 6) % 6
                            if diff == 1 || diff == 2 || diff == 3 {
                                // Adjacent, skip-1, or skip-2 patterns
                                selectedPaths.append(path)
                            }
                        }
                    }
                } else {
                    // For longer paths, take approximately 30%
                    let targetCount = max(1, paths.count * 3 / 10)
                    let step = max(1, paths.count / targetCount)
                    for (index, path) in paths.enumerated() {
                        if index % step == 0 {
                            selectedPaths.append(path)
                        }
                    }
                }
            }
            
            return selectedPaths
        }
    }
}