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
}