import Foundation

/// Represents the 2-bit room labels using letters for better visualization
public enum RoomLabel: String, CaseIterable {
    case A = "A"  // Represents 0 (00 in binary)
    case B = "B"  // Represents 1 (01 in binary)
    case C = "C"  // Represents 2 (10 in binary)
    case D = "D"  // Represents 3 (11 in binary)
    
    /// Initialize from integer value (0-3)
    public init?(fromInt value: Int) {
        switch value {
        case 0: self = .A
        case 1: self = .B
        case 2: self = .C
        case 3: self = .D
        default: return nil
        }
    }
    
    /// Convert to integer value (0-3)
    public var intValue: Int {
        switch self {
        case .A: return 0
        case .B: return 1
        case .C: return 2
        case .D: return 3
        }
    }
}

/// Represents a node (room) in the hexagonal graph
public struct Node {
    public let id: Int
    public var label: RoomLabel?
    /// Connections through each of the 6 doors
    /// Key is door number (0-5), value is nil for unexplored or the connected node ID and its door number
    public var doors: [Int: (nodeId: Int, doorNumber: Int)?]
    
    public init(id: Int, label: RoomLabel? = nil) {
        self.id = id
        self.label = label
        // Initialize all 6 doors as unexplored (we store the key with nil value explicitly)
        self.doors = [
            0: nil,
            1: nil,
            2: nil,
            3: nil,
            4: nil,
            5: nil
        ]
    }
}

/// Represents an edge (connection) between two rooms through specific doors
public struct Edge {
    public let fromNodeId: Int
    public let fromDoor: Int
    public let toNodeId: Int
    public let toDoor: Int
    
    public init(fromNodeId: Int, fromDoor: Int, toNodeId: Int, toDoor: Int) {
        self.fromNodeId = fromNodeId
        self.fromDoor = fromDoor
        self.toNodeId = toNodeId
        self.toDoor = toDoor
    }
}

/// Graph structure representing the hexagonal room map
public class Graph {
    private var nodes: [Int: Node] = [:]
    private var edges: [Edge] = []
    private var nextNodeId: Int = 0
    public let startingNodeId: Int
    
    public init(startingLabel: RoomLabel? = nil) {
        self.startingNodeId = nextNodeId
        let startingNode = Node(id: startingNodeId, label: startingLabel)
        nodes[startingNodeId] = startingNode
        nextNodeId += 1
    }
    
    /// Add a new node to the graph
    @discardableResult
    public func addNode(label: RoomLabel? = nil) -> Int {
        let nodeId = nextNodeId
        let node = Node(id: nodeId, label: label)
        nodes[nodeId] = node
        nextNodeId += 1
        return nodeId
    }
    
    /// Add a connection between two nodes through specific doors
    public func addEdge(fromNodeId: Int, fromDoor: Int, toNodeId: Int, toDoor: Int) {
        guard var fromNode = nodes[fromNodeId],
              nodes[toNodeId] != nil,
              fromDoor >= 0 && fromDoor < 6,
              toDoor >= 0 && toDoor < 6 else {
            return
        }
        
        // Update the from node's door connection
        fromNode.doors[fromDoor] = (nodeId: toNodeId, doorNumber: toDoor)
        nodes[fromNodeId] = fromNode
        
        // Create bidirectional connection
        if var toNode = nodes[toNodeId] {
            toNode.doors[toDoor] = (nodeId: fromNodeId, doorNumber: fromDoor)
            nodes[toNodeId] = toNode
        }
        
        // Store the edge
        let edge = Edge(fromNodeId: fromNodeId, fromDoor: fromDoor, toNodeId: toNodeId, toDoor: toDoor)
        edges.append(edge)
    }
    
    /// Get a node by its ID
    public func getNode(_ id: Int) -> Node? {
        return nodes[id]
    }
    
    /// Get all nodes in the graph
    public func getAllNodes() -> [Node] {
        return Array(nodes.values)
    }
    
    /// Get all edges in the graph
    public func getAllEdges() -> [Edge] {
        return edges
    }
    
    /// Update a node's label
    public func updateNodeLabel(nodeId: Int, label: RoomLabel) {
        guard var node = nodes[nodeId] else { return }
        node.label = label
        nodes[nodeId] = node
    }
    
    /// Add a one-way connection from a node through a door
    /// Used when we don't know the return path yet
    public func addOneWayConnection(fromNodeId: Int, fromDoor: Int, toNodeId: Int) {
        guard var fromNode = nodes[fromNodeId],
              nodes[toNodeId] != nil,
              fromDoor >= 0 && fromDoor < 6 else {
            return
        }
        
        // Only update the forward connection
        fromNode.doors[fromDoor] = (nodeId: toNodeId, doorNumber: -1)  // -1 means unknown return door
        nodes[fromNodeId] = fromNode
    }
}