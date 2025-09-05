import Foundation

public class TestSixRoomsFullyConnected {
    public static func run() async {
        print("\n🔮 Testing 6-Room Fully Connected Map")
        print(String(repeating: "=", count: 60))
        
        do {
            // Load the map
            let config = try MapFileLoader.loadMap(from: "six_rooms_fully_connected.config")
            print("✅ Loaded map with \(config.roomIds.count) rooms")
            print("   Room IDs: \(config.roomIds)")
            print("   Labels: \(config.roomLabels)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig("six_rooms_fully_connected.config"))
            
            // Create incremental room builder
            let builder = IncrementalRoomBuilder(maxPathLength: 18 * config.roomIds.count)
            
            print("\n🚀 Starting Incremental Room Discovery:")
            print("   Note: This is a fully connected graph - every room connects to every other room!")
            
            var allPaths: [String] = []
            
            // Systematic exploration by depth
            print("\n📍 Systematic exploration phase:")
            
            // For fully connected graphs, we need even more extensive exploration
            for depth in 0...10 {
                print("  Exploring depth \(depth):")
                
                // Generate all paths of this depth
                var pathsAtDepth: [String] = []
                if depth == 0 {
                    pathsAtDepth = [""]
                } else {
                    generatePathsOfLength(depth, current: "", paths: &pathsAtDepth)
                }
                
                // Test more paths for fully connected graphs
                let limit = depth <= 3 ? pathsAtDepth.count : min(300, pathsAtDepth.count)
                let selectedPaths = Array(pathsAtDepth.prefix(limit))
                
                var newPaths = 0
                for path in selectedPaths {
                    if !allPaths.contains(path) {
                        let response = try await client.explore(plans: [path])
                        allPaths.append(path)
                        builder.processExplorations(paths: [path], results: response.results)
                        newPaths += 1
                    }
                }
                
                let stats = builder.getStatistics()
                print("    Explored \(newPaths) new paths. Current: \(stats.rooms) rooms, \(stats.states) states, \(stats.connections) connections")
                
                // Stop if we found all rooms
                if stats.rooms == config.roomIds.count {
                    print("\n✅ Found expected number of rooms!")
                    break
                }
            }
            
            // Show final mapping
            let rooms = builder.getFinalRooms()
            
            print("\n📊 FINAL MAPPING:")
            print("   Found \(rooms.count) rooms (expected \(config.roomIds.count))")
            
            // Analyze connectivity
            var selfLoopCount = 0
            var connectionCount = 0
            
            for room in rooms.sorted(by: { $0.id < $1.id }) {
                print("\n  Room \(room.id) (label \(room.label)):")
                print("    States: \(room.states.count)")
                
                // Count unique connected room labels
                var connectedLabels = Set<Int>()
                
                for door in 0..<6 {
                    if let conn = room.doors[door], let c = conn {
                        if c.toRoomId == room.label {
                            print("    Door \(door) → self-loop")
                            selfLoopCount += 1
                        } else {
                            print("    Door \(door) → label \(c.toRoomId)")
                            connectionCount += 1
                            connectedLabels.insert(c.toRoomId)
                        }
                    } else {
                        print("    Door \(door) → unmapped")
                    }
                }
                
                print("    Connected to \(connectedLabels.count) different room labels")
            }
            
            print("\n📈 Statistics:")
            print("   Total self-loops: \(selfLoopCount)")
            print("   Total connections: \(connectionCount)")
            print("   Average connections per room: \(Double(connectionCount) / Double(rooms.count))")
            
            // Verify full connectivity
            print("\n🔗 Connectivity Analysis:")
            var isFullyConnected = true
            for room in rooms {
                var connectedLabels = Set<Int>()
                for (_, connection) in room.doors {
                    if let conn = connection, conn.toRoomId != room.label {
                        connectedLabels.insert(conn.toRoomId)
                    }
                }
                
                // In a fully connected graph with 4 unique labels (0,1,2,3),
                // each room should connect to all 3 other labels
                let expectedConnections = Set([0, 1, 2, 3]).subtracting([room.label])
                if connectedLabels != expectedConnections {
                    print("   ⚠️ Room with label \(room.label) is not fully connected")
                    print("      Expected: \(expectedConnections)")
                    print("      Found: \(connectedLabels)")
                    isFullyConnected = false
                }
            }
            
            if isFullyConnected {
                print("   ✅ Graph is fully connected!")
            }
            
            if rooms.count != config.roomIds.count {
                print("\n⚠️ INCOMPLETE - found \(rooms.count) rooms, expected \(config.roomIds.count)")
            } else {
                print("\n✅ SUCCESS - All rooms correctly identified!")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Generate all paths of a specific length
    private static func generatePathsOfLength(_ length: Int, current: String, paths: inout [String]) {
        if current.count == length {
            paths.append(current)
            return
        }
        
        for door in 0..<6 {
            generatePathsOfLength(length, current: current + String(door), paths: &paths)
        }
    }
}