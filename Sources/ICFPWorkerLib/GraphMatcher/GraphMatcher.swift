import Foundation

/// Represents the result of room identification
public struct RoomIdentificationResult {
    public let uniqueRooms: Int
    public let roomGroups: [[Int]]  // Groups of node IDs that are the same room
    public let queryCount: Int
    public let graph: Graph
    
    public init(uniqueRooms: Int, roomGroups: [[Int]], queryCount: Int, graph: Graph) {
        self.uniqueRooms = uniqueRooms
        self.roomGroups = roomGroups
        self.queryCount = queryCount
        self.graph = graph
    }
}

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
    
    /// Main entry point for room identification algorithm
    /// - Parameters:
    ///   - sourceGraph: The actual graph to explore (typically via API)
    ///   - expectedRoomCount: Number of unique rooms expected
    ///   - maxQueries: Maximum number of exploration queries allowed
    ///   - maxDepth: Maximum exploration depth for paths
    /// - Returns: Result containing unique rooms, node groupings, and statistics
    public func identifyRooms(
        sourceGraph: Graph,
        expectedRoomCount: Int,
        maxQueries: Int = 100,
        maxDepth: Int = 3
    ) -> RoomIdentificationResult {
        
        var queryCount = 0
        var exploredPaths = Set<String>()
        var allResults: [PathResult] = []  // Track all exploration results
        var roomCollection = SimpleRoomCollection()
        var currentDepth = 1
        
        // Main exploration loop - continue until all rooms are fully characterized
        while queryCount < maxQueries {  // Respect the query limit
            
            // We don't need to check depth limit in the loop condition
            // The algorithm should explore as deep as needed
            
            // Phase 2: Adaptive exploration based on current signature state
            var pathsToExplore: [String] = []
            
            if queryCount == 0 {
                // Initial exploration: discover immediate neighbors
                pathsToExplore = ["0", "1", "2", "3", "4", "5"]
                print("Initial exploration: discovering immediate neighbors")
            } else {
                // After initial exploration, systematically explore deeper until all rooms are complete
                roomCollection = buildSimpleRooms(from: allResults)
                let incompleteRooms = roomCollection.getAllRooms().filter { !$0.isComplete }
                
                print("After \(queryCount) queries: \(roomCollection.getAllRooms().count) rooms discovered, \(incompleteRooms.count) incomplete, depth=\(currentDepth)")
                
                // Show some details about incomplete rooms
                if incompleteRooms.count <= 5 {
                    for room in incompleteRooms.prefix(3) {
                        let signature = room.getSignature(depth: 1, roomCollection: roomCollection)
                        print("  Incomplete: \(signature)")
                    }
                }
                
                // Check if we have enough unique signatures among complete rooms
                let uniqueSignatures = roomCollection.countUniqueSignatures()
                if uniqueSignatures == expectedRoomCount {
                    print("SUCCESS: Found \(uniqueSignatures) unique room signatures!")
                    break
                }
                
                if incompleteRooms.isEmpty {
                    // All discovered rooms are complete but we don't have enough unique signatures
                    print("All rooms complete but only have \(uniqueSignatures), need \(expectedRoomCount) - exploring deeper")
                    currentDepth += 1
                    pathsToExplore = generateAllPathsAtDepth(depth: currentDepth, exploredPaths: exploredPaths)
                    if pathsToExplore.count > 500 {
                        pathsToExplore = Array(pathsToExplore.prefix(500))
                        print("LIMITED to 500 paths to avoid excessive exploration")
                    }
                } else {
                    // Some rooms are incomplete - continue expanding but only if we need more unique signatures
                    if uniqueSignatures < expectedRoomCount {
                        currentDepth += 1
                        pathsToExplore = generateAllPathsAtDepth(depth: currentDepth, exploredPaths: exploredPaths)
                        print("Have \(uniqueSignatures) unique signatures, need \(expectedRoomCount) - expanding to depth \(currentDepth): \(pathsToExplore.count) new paths")
                    
                        // Safety limit to prevent exponential explosion
                        if pathsToExplore.count > 500 {
                            pathsToExplore = Array(pathsToExplore.prefix(500))
                            print("LIMITED to 500 paths to avoid excessive exploration")
                        }
                        
                        // Safety check - if depth gets too high, something is wrong
                        if currentDepth > 6 {
                            print("ERROR: Reached depth \(currentDepth) - something may be wrong with exploration")
                            break
                        }
                    } else {
                        // We have enough unique signatures, even though some rooms are incomplete
                        print("Have \(uniqueSignatures) unique signatures (target: \(expectedRoomCount)) - stopping even with \(incompleteRooms.count) incomplete rooms")
                        break
                    }
                }
            }
            
            if pathsToExplore.isEmpty {
                print("No paths available to explore, stopping")
                break
            }
            
            print("Exploring \(pathsToExplore.count) paths: \(pathsToExplore.prefix(5))...")
            
            // Phase 3: Execute exploration
            // We always explore from the starting node
            // Respect the query limit
            let remainingQueries = maxQueries - queryCount
            let pathsToProcess = Array(pathsToExplore.prefix(remainingQueries))
            if pathsToProcess.count < pathsToExplore.count {
                print("Query limit reached: processing \(pathsToProcess.count) of \(pathsToExplore.count) paths")
            }
            let explorations = [(nodeId: sourceGraph.startingNodeId, paths: pathsToProcess)]
            let batchResults = batchExplore(
                explorations: explorations,
                sourceGraph: sourceGraph
            )
            
            // Update tracking
            for result in batchResults {
                exploredPaths.insert(result.path)
                allResults.append(result)  // Keep all results
            }
            queryCount += batchResults.count
            
            // Phase 4: Update room collection from all results
            roomCollection = buildSimpleRooms(from: allResults)
            
            // Phase 5: Check if we've found all rooms
            let uniqueRooms = roomCollection.countUniqueSignatures()
            
            // Check if we've found EXACTLY the right number of unique rooms
            if uniqueRooms == expectedRoomCount {
                // Success! Return a simplified result
                // For compatibility, create groups where each unique room is its own group
                var roomGroups: [[Int]] = []
                for i in 0..<uniqueRooms {
                    roomGroups.append([i])
                }
                
                // Create a dummy graph for backward compatibility
                let dummyGraph = Graph(startingLabel: sourceGraph.getNode(sourceGraph.startingNodeId)?.label ?? .A)
                
                return RoomIdentificationResult(
                    uniqueRooms: uniqueRooms,
                    roomGroups: roomGroups,
                    queryCount: queryCount,
                    graph: dummyGraph
                )
            }
            
            // Continue exploring if we don't have enough rooms yet
            if uniqueRooms < expectedRoomCount {
                print("Need to continue exploring: have \(uniqueRooms), need \(expectedRoomCount)")
            }
        }
        
        // Final room computation
        roomCollection = buildSimpleRooms(from: allResults)
        let finalUniqueRooms = roomCollection.countUniqueSignatures()
        
        // For compatibility, create groups where each unique room is its own group
        var finalRoomGroups: [[Int]] = []
        for i in 0..<finalUniqueRooms {
            finalRoomGroups.append([i])
        }
        
        // Create a dummy graph for backward compatibility
        let dummyGraph = Graph(startingLabel: sourceGraph.getNode(sourceGraph.startingNodeId)?.label ?? .A)
        
        return RoomIdentificationResult(
            uniqueRooms: finalUniqueRooms,
            roomGroups: finalRoomGroups,
            queryCount: queryCount,
            graph: dummyGraph
        )
    }
    
    /// Select paths to complete room exploration - expand all 6 doors from each discovered room
    private func selectPathsForSimpleRooms(
        roomCollection: SimpleRoomCollection,
        exploredPaths: Set<String>,
        currentDepth: Int,
        maxPathsToExplore: Int
    ) -> [String] {
        var pathsToExplore: [String] = []
        
        // Strategy: For every incomplete room, find a path to it and expand all 6 doors from there
        let incompleteRooms = roomCollection.getAllRooms().filter { !$0.isComplete }
        
        print("Found \(incompleteRooms.count) incomplete rooms that need door expansion")
        
        if !incompleteRooms.isEmpty {
            // Find paths that lead to each incomplete room and expand from there
            pathsToExplore = generatePathsToCompleteRooms(
                incompleteRooms: incompleteRooms,
                exploredPaths: exploredPaths,
                maxPaths: maxPathsToExplore
            )
            
            if !pathsToExplore.isEmpty {
                print("Generated \(pathsToExplore.count) paths to complete room doors: \(pathsToExplore.prefix(6))")
                return pathsToExplore
            }
        }
        
        // If no incomplete rooms or no paths to complete them, explore deeper to find new rooms
        let deeperDepth = max(currentDepth + 1, 2)
        let deeperPaths = generatePaths(depth: deeperDepth)
            .filter { !exploredPaths.contains($0) }
            .prefix(maxPathsToExplore)
        
        pathsToExplore = Array(deeperPaths)
        print("Need to discover new rooms - exploring depth \(deeperDepth) with \(pathsToExplore.count) paths")
        return pathsToExplore
    }
    
    /// Generate paths to complete the doors of incomplete rooms
    private func generatePathsToCompleteRooms(
        incompleteRooms: [SimpleRoom],
        exploredPaths: Set<String>,
        maxPaths: Int
    ) -> [String] {
        var pathsToExplore: [String] = []
        
        // For each incomplete room, we need to find paths that reach it
        // and then explore all 6 doors from that position
        
        // Start with simple approach: if we found rooms at depth 1, expand them to depth 2
        // Room A is at "", Room B is at "5", Room C is at "55", etc.
        
        // First, generate all unexplored paths that could complete room information
        // Focus on depth 2 first (most rooms are discovered at depth 1-2)
        for firstDoor in 0..<6 {
            for secondDoor in 0..<6 {
                let path = "\(firstDoor)\(secondDoor)"
                if !exploredPaths.contains(path) && pathsToExplore.count < maxPaths {
                    pathsToExplore.append(path)
                }
            }
        }
        
        // If we still need more paths and have room, try depth 3
        if pathsToExplore.count < maxPaths {
            for firstDoor in 0..<6 {
                for secondDoor in 0..<6 {
                    for thirdDoor in 0..<6 {
                        let path = "\(firstDoor)\(secondDoor)\(thirdDoor)"
                        if !exploredPaths.contains(path) && pathsToExplore.count < maxPaths {
                            pathsToExplore.append(path)
                        }
                        
                        if pathsToExplore.count >= maxPaths {
                            break
                        }
                    }
                    if pathsToExplore.count >= maxPaths {
                        break
                    }
                }
                if pathsToExplore.count >= maxPaths {
                    break
                }
            }
        }
        
        return pathsToExplore
    }
    
    /// Generate all possible paths at a specific depth that haven't been explored yet
    private func generateAllPathsAtDepth(depth: Int, exploredPaths: Set<String>) -> [String] {
        var paths: [String] = []
        
        func generateRecursive(currentPath: String, remainingDepth: Int) {
            if remainingDepth == 0 {
                if !exploredPaths.contains(currentPath) {
                    paths.append(currentPath)
                }
                return
            }
            
            for door in 0..<6 {
                generateRecursive(currentPath: currentPath + String(door), remainingDepth: remainingDepth - 1)
            }
        }
        
        generateRecursive(currentPath: "", remainingDepth: depth)
        return paths
    }
    
}