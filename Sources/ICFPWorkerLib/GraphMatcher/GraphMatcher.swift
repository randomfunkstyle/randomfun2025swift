import Foundation

/// GraphMatcher is responsible for matching and comparing graph structures
public class GraphMatcher {
    
    public init() {
    }
    
    /// Simple hello world method for initial testing
    public func helloWorld() -> String {
        return "Hello, World!"
    }
    
    /// Convert a MapDescription (from the existing system) to our Graph structure
    public func convertMapDescriptionToGraph(_ mapDesc: MapDescription) -> Graph {
        // Create graph with starting room label
        let startingLabel = RoomLabel(fromInt: mapDesc.rooms[mapDesc.startingRoom])
        let graph = Graph(startingLabel: startingLabel)
        
        // Create a mapping from original room IDs to our graph node IDs
        var roomIdToNodeId: [Int: Int] = [:]
        roomIdToNodeId[mapDesc.startingRoom] = graph.startingNodeId
        
        // Add all other rooms as nodes
        for (index, labelInt) in mapDesc.rooms.enumerated() {
            if index != mapDesc.startingRoom {
                let label = RoomLabel(fromInt: labelInt)
                let nodeId = graph.addNode(label: label)
                roomIdToNodeId[index] = nodeId
            }
        }
        
        // Update the starting node's label if needed
        if let startingLabel = startingLabel {
            graph.updateNodeLabel(nodeId: graph.startingNodeId, label: startingLabel)
        }
        
        // Add all connections as edges
        // Track which connections we've already added to avoid duplicates
        var processedConnections = Set<String>()
        
        for connection in mapDesc.connections {
            let fromRoom = connection.from.room
            let fromDoor = connection.from.door
            let toRoom = connection.to.room
            let toDoor = connection.to.door
            
            // Create a unique key for this connection (considering bidirectional nature)
            let connectionKey = "\(min(fromRoom, toRoom))-\(fromRoom == min(fromRoom, toRoom) ? fromDoor : toDoor)-\(max(fromRoom, toRoom))-\(fromRoom == min(fromRoom, toRoom) ? toDoor : fromDoor)"
            
            if !processedConnections.contains(connectionKey) {
                processedConnections.insert(connectionKey)
                
                if let fromNodeId = roomIdToNodeId[fromRoom],
                   let toNodeId = roomIdToNodeId[toRoom] {
                    graph.addEdge(fromNodeId: fromNodeId, fromDoor: fromDoor,
                                  toNodeId: toNodeId, toDoor: toDoor)
                }
            }
        }
        
        return graph
    }
    
    /// Create a test graph with the hexagon layout from MockExplorationClient
    public func createHexagonTestGraph() -> Graph {
        let mockClient = MockExplorationClient(layout: .hexagon)
        guard let mapDesc = mockClient.correctMap else {
            // Fallback to empty graph if something goes wrong
            return Graph()
        }
        return convertMapDescriptionToGraph(mapDesc)
    }
    
    /// Create a test graph with the three rooms layout from MockExplorationClient
    public func createThreeRoomsTestGraph() -> Graph {
        let mockClient = MockExplorationClient(layout: .threeRooms)
        guard let mapDesc = mockClient.correctMap else {
            // Fallback to empty graph if something goes wrong
            return Graph()
        }
        return convertMapDescriptionToGraph(mapDesc)
    }
    
    /// Explore a path through a source graph and return the sequence of room labels observed
    /// - Parameters:
    ///   - sourceGraph: The graph to explore
    ///   - path: Sequence of door numbers to traverse (e.g., "012" means door 0, then 1, then 2)
    /// - Returns: Array of room labels observed at each step (including starting room)
    public func explorePath(sourceGraph: Graph, path: String) -> [RoomLabel] {
        var currentNodeId = sourceGraph.startingNodeId
        var labels: [RoomLabel] = []
        
        // Add starting room label
        if let startingNode = sourceGraph.getNode(currentNodeId) {
            labels.append(startingNode.label ?? .A)  // Default to A if no label
        }
        
        // Walk through each door in the path
        for doorChar in path {
            guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
            
            // Find where this door leads
            if let currentNode = sourceGraph.getNode(currentNodeId),
               let connection = currentNode.doors[door],
               let (nextNodeId, _) = connection {
                currentNodeId = nextNodeId
                
                // Add the label of the room we entered
                if let nextNode = sourceGraph.getNode(nextNodeId) {
                    labels.append(nextNode.label ?? .A)  // Default to A if no label
                }
            } else {
                // If door doesn't exist or leads nowhere, stay in current room
                if let currentNode = sourceGraph.getNode(currentNodeId) {
                    labels.append(currentNode.label ?? .A)
                }
            }
        }
        
        return labels
    }
    
    /// Build a new graph from exploration results
    /// - Parameter explorations: Array of tuples containing paths and their observed labels
    /// - Returns: A new graph constructed from the exploration data
    public func buildGraphFromExploration(explorations: [(path: String, labels: [RoomLabel])]) -> Graph {
        // Start with empty graph, using first label if available
        let startingLabel = explorations.first?.labels.first ?? .A
        let graph = Graph(startingLabel: startingLabel)
        
        // Track current position for each exploration
        for (path, labels) in explorations {
            var currentNodeId = graph.startingNodeId
            
            // Skip if labels don't match path length + 1 (starting room + each step)
            guard labels.count == path.count + 1 else { continue }
            
            // Process each door in the path
            for (index, doorChar) in path.enumerated() {
                guard let door = Int(String(doorChar)), door >= 0 && door < 6 else { continue }
                
                // Check if we already know where this door leads
                if let currentNode = graph.getNode(currentNodeId),
                   let connection = currentNode.doors[door],
                   let (nextNodeId, _) = connection {
                    // Door already explored, just move there
                    currentNodeId = nextNodeId
                } else {
                    // Create new node for this unexplored door
                    let nextLabel = labels[index + 1]  // Label for the room we're entering
                    let nextNodeId = graph.addNode(label: nextLabel)
                    
                    // Only add a one-way connection since we don't know the return door
                    graph.addOneWayConnection(fromNodeId: currentNodeId, fromDoor: door, toNodeId: nextNodeId)
                    
                    currentNodeId = nextNodeId
                }
            }
        }
        
        return graph
    }
}