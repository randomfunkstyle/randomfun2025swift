import Foundation

public class TestSixRooms {
    public static func run() async {
        print("\n🔮 Testing 6-Room Circular Map")
        print(String(repeating: "=", count: 60))
        
        do {
            // Load the map
            let config = try MapFileLoader.loadMap(from: "six_rooms_circular.config")
            print("✅ Loaded map with \(config.roomIds.count) rooms")
            print("   Room IDs: \(config.roomIds)")
            print("   Labels: \(config.roomLabels)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig("six_rooms_circular.config"))
            
            // Create incremental room builder
            let builder = IncrementalRoomBuilder(maxPathLength: 18 * config.roomIds.count)
            
            print("\n🚀 Starting Incremental Room Discovery:")
            
            // Generate paths of increasing length
            let maxDepth = 10  // Explore deeper to get more info
            var allPaths: [String] = []
            var allLabels: [[Int]] = []
            
            // Systematic exploration: ensure we explore all doors from discovered states
            print("\n📍 Systematic exploration phase:")
            
            // Explore systematically by depth
            for depth in 0...6 {
                print("  Exploring depth \(depth):")
                
                // Generate all paths of this depth
                var pathsAtDepth: [String] = []
                if depth == 0 {
                    pathsAtDepth = [""]
                } else {
                    generatePathsOfLength(depth, current: "", paths: &pathsAtDepth)
                }
                
                // Test a reasonable subset
                let limit = depth <= 2 ? pathsAtDepth.count : min(100, pathsAtDepth.count)
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
            for room in rooms.sorted(by: { $0.id < $1.id }) {
                print("\n  Room \(room.id) (label \(room.label)):")
                for door in 0..<6 {
                    if let conn = room.doors[door], let c = conn {
                        if c.toRoomId == room.id {
                            print("    Door \(door) → self-loop")
                        } else {
                            let toDoorStr = c.toDoor ?? -1 >= 0 ? "door \(c.toDoor ?? -1)" : "unknown door"
                            print("    Door \(door) → Room \(c.toRoomId) \(toDoorStr)")
                        }
                    } else {
                        print("    Door \(door) → unmapped")
                    }
                }
            }
            
            if rooms.count != config.roomIds.count {
                print("\n⚠️ INCOMPLETE - found \(rooms.count) rooms, expected \(config.roomIds.count)")
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