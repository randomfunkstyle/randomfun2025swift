import Foundation

/// Represents a group of nodes with priority for exploration
public struct PriorityGroup {
    public let priority: Int  // 1 = highest (multiple nodes, same label)
    public let label: RoomLabel
    public let nodeIds: [Int]
    public let reason: String  // Why this priority
    
    public init(priority: Int, label: RoomLabel, nodeIds: [Int], reason: String) {
        self.priority = priority
        self.label = label
        self.nodeIds = nodeIds
        self.reason = reason
    }
}

extension GraphMatcher {
    /// Group nodes by their observed label
    /// - Parameter nodes: Array of nodes to group
    /// - Returns: Dictionary mapping labels to node IDs
    public func groupNodesByLabel(nodes: [Node]) -> [RoomLabel: [Int]] {
        var groups: [RoomLabel: [Int]] = [:]
        
        for node in nodes {
            // Skip nodes without labels
            guard let label = node.label else { continue }
            
            if groups[label] == nil {
                groups[label] = []
            }
            groups[label]?.append(node.id)
        }
        
        // Sort node IDs within each group for consistency
        for label in groups.keys {
            groups[label]?.sort()
        }
        
        return groups
    }
    
    /// Order label groups by exploration priority
    /// - Parameter groups: Dictionary of labels to node IDs
    /// - Returns: Array of priority groups ordered by priority (1 = highest)
    public func prioritizeLabelGroups(groups: [RoomLabel: [Int]]) -> [PriorityGroup] {
        var priorityGroups: [PriorityGroup] = []
        
        for (label, nodeIds) in groups {
            let priority: Int
            let reason: String
            
            if nodeIds.count > 1 {
                // Multiple nodes with same label - high priority
                // These definitely contain duplicates that need disambiguation
                priority = 1
                reason = "Multiple nodes (\(nodeIds.count)) with same label - likely contains duplicates"
            } else if nodeIds.count == 1 {
                // Single node with this label - lower priority
                // Might be unique room, but still needs verification
                priority = 2
                reason = "Single node with this label - possibly unique room"
            } else {
                // Empty group (shouldn't happen but handle gracefully)
                continue
            }
            
            let group = PriorityGroup(
                priority: priority,
                label: label,
                nodeIds: nodeIds,
                reason: reason
            )
            priorityGroups.append(group)
        }
        
        // Sort by priority (ascending) then by label for stability
        priorityGroups.sort { (a, b) in
            if a.priority != b.priority {
                return a.priority < b.priority
            }
            return a.label.rawValue < b.label.rawValue
        }
        
        return priorityGroups
    }
}