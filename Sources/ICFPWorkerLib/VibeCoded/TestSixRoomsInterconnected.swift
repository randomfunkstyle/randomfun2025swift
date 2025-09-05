import Foundation

public class TestSixRoomsInterconnected {
    public static func run() async {
        print("\n🔮 Testing 6-Room Interconnected Map (Fewer Self-Loops)")
        print(String(repeating: "=", count: 60))
        
        do {
            // Load the map
            let config = try MapFileLoader.loadMap(from: "six_rooms_interconnected.config")
            print("✅ Loaded map with \(config.roomIds.count) rooms")
            print("   Room IDs: \(config.roomIds)")
            print("   Labels: \(config.roomLabels)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig("six_rooms_interconnected.config"))
            
            // Create incremental room builder
            let builder = IncrementalRoomBuilder(maxPathLength: 18 * config.roomIds.count)
            
            print("\n🚀 Starting Incremental Room Discovery:")
            
            var allPaths: [String] = []
            
            // Systematic exploration by depth
            print("\n📍 Systematic exploration phase:")
            
            for depth in 0...8 {
                print("  Exploring depth \(depth):")
                
                // Generate all paths of this depth
                var pathsAtDepth: [String] = []
                if depth == 0 {
                    pathsAtDepth = [""]
                } else {
                    generatePathsOfLength(depth, current: "", paths: &pathsAtDepth)
                }
                
                // Test a reasonable subset - more for interconnected maps
                let limit = depth <= 3 ? pathsAtDepth.count : min(200, pathsAtDepth.count)
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
                
                for door in 0..<6 {
                    if let conn = room.doors[door], let c = conn {
                        if c.toRoomId == room.label {
                            print("    Door \(door) → self-loop")
                            selfLoopCount += 1
                        } else {
                            print("    Door \(door) → label \(c.toRoomId)")
                            connectionCount += 1
                        }
                    } else {
                        print("    Door \(door) → unmapped")
                    }
                }
            }
            
            print("\n📈 Statistics:")
            print("   Total self-loops: \(selfLoopCount)")
            print("   Total connections: \(connectionCount)")
            print("   Average connections per room: \(Double(connectionCount) / Double(rooms.count))")
            
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