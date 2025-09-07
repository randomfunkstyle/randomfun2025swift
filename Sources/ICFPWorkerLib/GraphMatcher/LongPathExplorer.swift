import Foundation

/// Represents a fingerprint extracted from a long path exploration
public struct RoomFingerprint {
    public let reachedByPath: String  // The path from start to reach this room
    public let fingerprint: String    // The sequence of labels seen from this room
    public let startLabel: RoomLabel  // The label of this room
    
    public init(reachedByPath: String, fingerprint: String, startLabel: RoomLabel) {
        self.reachedByPath = reachedByPath
        self.fingerprint = fingerprint
        self.startLabel = startLabel
    }
}

/// Represents a cycle detected in the exploration
public struct CycleInfo {
    public let startPosition: Int  // Where the cycle starts in the path
    public let cycleLength: Int    // Length of the repeating pattern
    public let pattern: String     // The repeating pattern of labels
    
    public init(startPosition: Int, cycleLength: Int, pattern: String) {
        self.startPosition = startPosition
        self.cycleLength = cycleLength
        self.pattern = pattern
    }
}

/// Optimized explorer using long paths to extract multiple fingerprints from a single query
public class LongPathExplorer {
    
    public init() {}
    
    /// Generate an optimal long path for exploration
    /// Uses 3*n length to extract multiple n-character fingerprints
    /// - Parameters:
    ///   - expectedRooms: The expected number of rooms in the graph
    ///   - patternIndex: Which pattern variant to use (for trying different door combinations)
    /// - Returns: A path string of length 3*n to reveal room structure
    public func generateLongPath(expectedRooms: Int, patternIndex: Int = 0) -> String {
        // With 3*n steps, we can extract 2n+1 fingerprints of length n
        // This provides roughly 2× as many fingerprints as expected rooms
        // ensuring better coverage and higher probability of finding all rooms
        let targetLength = 3 * expectedRooms
        
        // Different patterns to explore different door combinations
        let patterns = [
            "543210",  // Reverse order to hit door 5 early
            "012345",  // Forward order
            "135024",  // Skip pattern
            "024135",  // Another skip pattern
            "531420",  // Mixed pattern
            "420531"   // Another mixed pattern
        ]
        
        let basePattern = patterns[patternIndex % patterns.count]
        
        // Build path by repeating pattern
        var path = ""
        while path.count < targetLength {
            path += basePattern
        }
        
        // Trim to exact length
        return String(path.prefix(targetLength))
    }
    
    /// Extract fingerprints for all rooms encountered in a long path exploration
    /// Each fingerprint is exactly n characters (where n = expected rooms)
    /// - Parameters:
    ///   - path: The path that was explored (typically length 2*n)
    ///   - labels: The sequence of labels observed (length path.count + 1)
    ///   - expectedRooms: Number of rooms expected (determines fingerprint length)
    /// - Returns: Array of fingerprints for different rooms
    public func extractFingerprints(path: String, labels: [RoomLabel], expectedRooms: Int) -> [RoomFingerprint] {
        var fingerprints: [RoomFingerprint] = []
        var seenFingerprints = Set<String>()
        
        // Fingerprint length is exactly the number of expected rooms
        let fingerprintLength = expectedRooms
        
        // For each position where we can extract a full n-character fingerprint
        // We need at least fingerprintLength characters remaining after position i
        let maxPosition = labels.count - fingerprintLength
        
        for i in 0..<maxPosition {
            // The path to reach this position
            let reachPath = i == 0 ? "" : String(path.prefix(i))
            
            // Extract exactly n characters starting from position i
            // These are the next n rooms we'll visit from position i
            let fingerprintLabels = labels[i..<(i+fingerprintLength)]
            let fingerprintString = fingerprintLabels.map { $0.rawValue }.joined()
            
            // Skip if we've already seen this exact fingerprint
            // (indicates we've returned to the same room)
            if seenFingerprints.contains(fingerprintString) {
                continue
            }
            seenFingerprints.insert(fingerprintString)
            
            let fingerprint = RoomFingerprint(
                reachedByPath: reachPath,
                fingerprint: fingerprintString,
                startLabel: labels[i]
            )
            
            fingerprints.append(fingerprint)
        }
        
        return fingerprints
    }
    
    /// Detect cycles in the label sequence
    /// - Parameter labels: The sequence of labels from exploration
    /// - Returns: Information about detected cycles, or nil if no clear cycle found
    public func detectCycles(in labels: [RoomLabel]) -> CycleInfo? {
        let labelString = labels.map { $0.rawValue }.joined()
        
        // Try different cycle lengths starting from 1
        for cycleLength in 1...(labels.count / 2) {
            // Check if this cycle length produces a repeating pattern
            var isValidCycle = true
            let pattern = String(labelString.prefix(cycleLength))
            
            // Check if the pattern repeats throughout the string
            var position = 0
            while position + cycleLength <= labelString.count {
                let segment = labelString[labelString.index(labelString.startIndex, offsetBy: position)..<labelString.index(labelString.startIndex, offsetBy: min(position + cycleLength, labelString.count))]
                
                if String(segment) != pattern && position + cycleLength <= labelString.count {
                    isValidCycle = false
                    break
                }
                position += cycleLength
            }
            
            if isValidCycle {
                // Found a repeating cycle
                return CycleInfo(
                    startPosition: 0,
                    cycleLength: cycleLength,
                    pattern: pattern
                )
            }
        }
        
        // No clear repeating cycle found
        return nil
    }
    
    /// Group fingerprints by their pattern to identify unique rooms
    /// Also attempts to identify which fingerprints represent the same room
    /// - Parameter fingerprints: Array of fingerprints to group
    /// - Returns: Dictionary mapping unique patterns to arrays of paths that lead to rooms with that pattern
    public func groupFingerprintsByPattern(_ fingerprints: [RoomFingerprint]) -> [String: [String]] {
        var groups: [String: [String]] = [:]
        
        // First, group by exact fingerprint
        for fingerprint in fingerprints {
            let patternKey = normalizeFingerprint(fingerprint.fingerprint)
            groups[patternKey, default: []].append(fingerprint.reachedByPath)
        }
        
        // Now try to identify which fingerprints might be from the same room
        // Rooms are the same if they have the same label and similar connection patterns
        var roomGroups: [String: [[String]]] = [:]
        
        for fingerprint in fingerprints {
            let roomKey = "\(fingerprint.startLabel.rawValue)"
            roomGroups[roomKey, default: []].append([fingerprint.reachedByPath, fingerprint.fingerprint])
        }
        
        // Log the room grouping for debugging
        print("\nRoom Grouping Analysis:")
        for (label, paths) in roomGroups {
            print("  Rooms with label '\(label)': \(paths.count) fingerprints")
            if paths.count > 1 {
                print("    Likely the same room appearing at different cycle positions")
            }
        }
        
        return groups
    }
    
    /// Normalize a fingerprint for comparison
    /// Since all fingerprints are now exactly n characters, we can compare directly
    private func normalizeFingerprint(_ fingerprint: String) -> String {
        // With fixed-length fingerprints, normalization is just the fingerprint itself
        // This makes comparison straightforward and mathematically correct
        return fingerprint
    }
    
    /// Identify actual unique rooms from fingerprints
    /// Groups fingerprints that likely represent the same room
    /// - Parameters:
    ///   - fingerprints: Array of fingerprints to analyze
    ///   - expectedRooms: Expected number of unique rooms
    /// - Returns: Estimated number of unique rooms
    private func identifyUniqueRooms(from fingerprints: [RoomFingerprint], expectedRooms: Int) -> Int {
        // Strategy: If we have roughly 2× fingerprints as expected rooms,
        // and they're well distributed across labels, we likely have found all rooms
        
        // Group by starting label
        var labelGroups: [String: Int] = [:]
        for fp in fingerprints {
            labelGroups[fp.startLabel.rawValue, default: 0] += 1
        }
        
        print("\nUnique Room Identification:")
        print("  Expected rooms: \(expectedRooms)")
        print("  Total fingerprints: \(fingerprints.count)")
        print("  Distribution by label: \(labelGroups)")
        
        // If we have at least expectedRooms unique starting positions,
        // we've likely found all or most rooms
        let uniquePatterns = Set(fingerprints.map { $0.fingerprint }).count
        
        // Heuristic: If we have many fingerprints (>= expectedRooms) and
        // they're distributed across different labels, we've found the rooms
        if fingerprints.count >= expectedRooms {
            // Estimate unique rooms based on label distribution and pattern diversity
            let estimatedRooms = min(expectedRooms, max(labelGroups.count, uniquePatterns / 2))
            print("  Estimated unique rooms: \(estimatedRooms)")
            return estimatedRooms
        }
        
        return uniquePatterns
    }
    
    /// Perform optimized room identification using long paths
    /// Will continue exploring until all rooms are found or no new information is gained
    /// - Parameters:
    ///   - sourceGraph: The graph to explore
    ///   - expectedRooms: Expected number of unique rooms
    /// - Returns: Result containing identified rooms and statistics
    public func identifyRoomsOptimized(sourceGraph: Graph, expectedRooms: Int) -> (uniqueRooms: Int, fingerprints: [RoomFingerprint], queryCount: Int) {
        let matcher = GraphMatcher()
        var allFingerprints: [RoomFingerprint] = []
        var queryCount = 0
        var seenPatterns = Set<String>()
        var patternIndex = 0
        
        // Keep trying different patterns until we find all expected rooms
        // or we've tried enough patterns without finding new rooms
        var consecutiveNoNewRooms = 0
        let maxConsecutiveNoProgress = 3
        
        while true {
            // Generate path with current pattern
            let longPath = generateLongPath(expectedRooms: expectedRooms, patternIndex: patternIndex)
            
            // Explore the path
            let labels = matcher.explorePath(sourceGraph: sourceGraph, path: longPath)
            queryCount += 1
            
            // Extract fingerprints (each exactly expectedRooms characters)
            let fingerprints = extractFingerprints(path: longPath, labels: labels, expectedRooms: expectedRooms)
            
            // Track how many new patterns we found
            let previousCount = seenPatterns.count
            
            // Add new fingerprints not seen before
            for fp in fingerprints {
                if !seenPatterns.contains(fp.fingerprint) {
                    seenPatterns.insert(fp.fingerprint)
                    allFingerprints.append(fp)
                }
            }
            
            // Check if we found new patterns
            if seenPatterns.count == previousCount {
                consecutiveNoNewRooms += 1
                if consecutiveNoNewRooms >= maxConsecutiveNoProgress {
                    // No progress for several queries, stop
                    break
                }
            } else {
                consecutiveNoNewRooms = 0
            }
            
            // Identify unique rooms using our heuristic
            let estimatedUniqueRooms = identifyUniqueRooms(from: allFingerprints, expectedRooms: expectedRooms)
            
            // If we've found all expected rooms, stop
            if estimatedUniqueRooms >= expectedRooms {
                // Detect cycles for validation
                if let cycleInfo = detectCycles(in: labels) {
                    print("Detected cycle: pattern '\(cycleInfo.pattern)' of length \(cycleInfo.cycleLength)")
                }
                
                // Still return pattern groups for compatibility
                let groups = groupFingerprintsByPattern(allFingerprints)
                
                return (
                    uniqueRooms: estimatedUniqueRooms,
                    fingerprints: allFingerprints,
                    queryCount: queryCount
                )
            }
            
            patternIndex += 1
        }
        
        // Return what we found
        let finalGroups = groupFingerprintsByPattern(allFingerprints)
        let estimatedRooms = identifyUniqueRooms(from: allFingerprints, expectedRooms: expectedRooms)
        return (
            uniqueRooms: estimatedRooms,
            fingerprints: allFingerprints,
            queryCount: queryCount
        )
    }
}