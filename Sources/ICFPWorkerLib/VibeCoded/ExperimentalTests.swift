import Foundation

/// Experimental tests for path traversal and exploration
public class ExperimentalTests {
    
    public static func run() async {
        print("\n🧪 Experimental Tests")
        print(String(repeating: "=", count: 50))
        
        // Test Phase1Analyzer with batch approach (legacy)
        // print("\n📦 BATCH APPROACH (multiple short paths)")
        // await testPhase1AnalyzerOnAllMaps()
        
        // Test Phase1Analyzer with single long path approach
        // print("\n🎯 SINGLE LONG PATH APPROACH (18*rooms)")
        // await testSingleLongPathOnAllMaps()
        
        // Test entropy-optimal approach
        print("\n🧬 ENTROPY-OPTIMAL APPROACH (Smart Paths)")
        // Test just two_rooms_full first
        // await testSmartPathOnMap("two_rooms_full.config")
        
        // Test adaptive multi-exploration approach
        print("\n🔄 ADAPTIVE MULTI-EXPLORATION")
        // Test all configurations
        await testAllMapsWithMultiIteration()
        
        // Test the new 6-room map
        print("\n🔍 TESTING six_rooms_circular:")
        await testMultiIterationMapping("six_rooms_circular.config")
    }
    
    private static func testPhase1AnalyzerOnAllMaps() async {
        print("\n🔬 Testing Phase1Analyzer on all available maps")
        
        let mapFiles = [
            "two_rooms_single.config",
            "two_rooms_full.config", 
            "three_rooms_one_loop.config",
            "three_rooms_two_loops.config",
            "three_rooms_three_loops.config",
            "three_rooms_four_loops.config",
            "three_rooms_five_loops.config"
        ]
        
        for mapFile in mapFiles {
            print("\n" + String(repeating: "-", count: 40))
            print("📍 Testing: \(mapFile)")
            await testPhase1AnalyzerOnMap(mapFile)
        }
    }
    
    private static func testPhase1AnalyzerOnMap(_ configFile: String) async {
        do {
            // Load the actual map configuration
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            print("Actual map: \(actualConfig.roomIds.count) rooms")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Create Phase1Analyzer with known room count
            let analyzer = Phase1Analyzer(roomCount: actualConfig.roomIds.count)
            
            // Generate initial paths
            let paths = analyzer.generateInitialPaths()
            print("Generated \(paths.count) initial paths")
            
            // Show what paths we're actually exploring for debugging
            if configFile == "three_rooms_five_loops.config" {
                print("Paths generated:")
                for (i, path) in paths.enumerated() {
                    if i < 20 || path.hasPrefix("54") || path.hasPrefix("5") && path.count == 3 {
                        print("  \(path)")
                    }
                }
            }
            
            // Explore all paths
            let response = try await client.explore(plans: paths)
            
            // Process the results
            analyzer.processExplorations(paths: paths, results: response.results)
            
            // Get the state analyzer and build the map
            let stateAnalyzer = analyzer.getStateAnalyzer()
            let rooms = stateAnalyzer.identifyRooms()
            
            print("✅ Identified \(rooms.count) rooms")
            print("Expected: \(actualConfig.roomIds.count) rooms")
            
            // Check if complete
            let isComplete = stateAnalyzer.isComplete()
            print("Complete mapping: \(isComplete)")
            
            // Show confidence
            let hypothesis = analyzer.getCurrentHypothesis()
            print("Confidence: \(String(format: "%.2f", hypothesis.connectionConfidence))")
            
            // For incomplete maps, show more details
            if !isComplete {
                print("\n⚠️ Incomplete mapping details:")
                for room in rooms {
                    var unmappedDoors: [Int] = []
                    for door in 0..<6 {
                        if room.doors[door] == nil {
                            unmappedDoors.append(door)
                        }
                    }
                    if !unmappedDoors.isEmpty {
                        print("  Room \(room.id) (label \(room.label)): unmapped doors \(unmappedDoors)")
                    }
                }
                
                // Show some specific paths to understand what we explored
                print("\nSample paths that should reach room C (label 2):")
                let pathsToC = ["54", "544", "540", "541", "542", "543", "545"]
                for path in pathsToC {
                    if let index = paths.firstIndex(of: path) {
                        print("  Path '\(path)': labels \(response.results[index])")
                    } else {
                        print("  Path '\(path)': NOT EXPLORED")
                    }
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testSingleLongPathOnAllMaps() async {
        print("\n🔬 Testing single long path approach on all maps")
        
        let mapFiles = [
            "two_rooms_single.config",
            "two_rooms_full.config",
            "three_rooms_one_loop.config",
            "three_rooms_two_loops.config",
            "three_rooms_three_loops.config",
            "three_rooms_four_loops.config",
            "three_rooms_five_loops.config"
        ]
        
        for mapFile in mapFiles {
            print("\n" + String(repeating: "-", count: 40))
            print("📍 Testing: \(mapFile)")
            await testSingleLongPathOnMap(mapFile)
        }
    }
    
    private static func testSingleLongPathOnMap(_ configFile: String) async {
        do {
            // Load the actual map configuration
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            let roomCount = actualConfig.roomIds.count
            print("Map has \(roomCount) rooms, max path length: \(18 * roomCount)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Create Phase1Analyzer with known room count
            let analyzer = Phase1Analyzer(roomCount: roomCount)
            
            var explorationCount = 0
            let maxExplorations = 10  // Safety limit
            
            // Iterative exploration
            while explorationCount < maxExplorations {
                guard let path = analyzer.generateNextPath() else {
                    print("✅ Exploration complete after \(explorationCount) paths")
                    break
                }
                
                explorationCount += 1
                print("  Path \(explorationCount): length \(path.count)")
                
                // Explore the single long path
                let response = try await client.explore(plans: [path])
                print("  Response: \(response.results[0].count) labels")
                
                // Process the results
                analyzer.processExplorations(paths: [path], results: response.results)
                
                // Check if we're done
                let stateAnalyzer = analyzer.getStateAnalyzer()
                let rooms = stateAnalyzer.identifyRooms()
                let isComplete = stateAnalyzer.isComplete()
                
                if isComplete && rooms.count == roomCount {
                    print("✅ Complete mapping achieved!")
                    print("  Identified \(rooms.count) rooms correctly")
                    break
                }
            }
            
            if explorationCount >= maxExplorations {
                print("⚠️ Reached exploration limit")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testSmartPathOnAllMaps() async {
        print("\n🔬 Testing entropy-optimal smart paths on all maps")
        
        let mapFiles = [
            "two_rooms_single.config",
            "two_rooms_full.config",
            "three_rooms_one_loop.config",
            "three_rooms_two_loops.config",
            "three_rooms_three_loops.config",
            "three_rooms_four_loops.config",
            "three_rooms_five_loops.config"
        ]
        
        for mapFile in mapFiles {
            print("\n" + String(repeating: "-", count: 40))
            print("📍 Testing: \(mapFile)")
            await testSmartPathOnMap(mapFile)
        }
    }
    
    private static func testSmartPathOnMap(_ configFile: String) async {
        do {
            // Load the actual map configuration
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            let roomCount = actualConfig.roomIds.count
            print("Map has \(roomCount) rooms, max path length: \(18 * roomCount)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Create Phase1Analyzer with smart path generation
            let analyzer = Phase1Analyzer(roomCount: roomCount)
            
            var explorationCount = 0
            let maxExplorations = 5  // Should need fewer with smart paths
            
            // Show the smart initial path
            let initialPath = analyzer.generateSmartPath()
            print("Smart initial path: \(String(initialPath.prefix(24)))...")
            
            // Iterative exploration
            while explorationCount < maxExplorations {
                guard let path = analyzer.generateNextPath() else {
                    print("✅ Complete mapping in \(explorationCount) explorations!")
                    break
                }
                
                explorationCount += 1
                
                // Explore the smart path
                let response = try await client.explore(plans: [path])
                let labels = response.results[0]
                
                // Process and extract information
                analyzer.processExplorations(paths: [path], results: response.results)
                
                // Extract structural information
                let stateAnalyzer = analyzer.getStateAnalyzer()
                let structInfo = stateAnalyzer.extractStructuralInformation(from: path, labels: labels)
                
                print("  Exploration \(explorationCount):")
                print("    Path length: \(path.count)")
                print("    Return pairs found: \(structInfo.bidirectionalConnections.count)")
                print("    Cycles found: \(structInfo.cycles.count)")
                print("    Information gained: \(String(format: "%.1f", structInfo.informationBits)) bits")
                
                // Check if we're done
                let rooms = stateAnalyzer.identifyRooms()
                let isComplete = stateAnalyzer.isComplete()
                
                if isComplete && rooms.count == roomCount {
                    print("✅ Complete mapping achieved!")
                    print("  Identified \(rooms.count) rooms correctly")
                    
                    // Show what we learned from return pairs
                    if !structInfo.bidirectionalConnections.isEmpty {
                        print("  Bidirectional connections discovered:")
                        for conn in structInfo.bidirectionalConnections.prefix(5) {
                            print("    Door \(conn.door1) ↔ Door \(conn.door2) (from room with label \(conn.startLabel))")
                        }
                    }
                    break
                }
            }
            
            if explorationCount >= maxExplorations {
                print("⚠️ Reached exploration limit")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testAdaptiveExploration(_ configFile: String) async {
        print("\n" + String(repeating: "-", count: 50))
        print("📍 Testing Adaptive Exploration on: \(configFile)")
        
        do {
            // Load the actual map configuration
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            let roomCount = actualConfig.roomIds.count
            print("Target: \(roomCount) rooms")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Create adaptive explorer
            let explorer = AdaptiveExplorer(roomCount: roomCount)
            
            let maxExplorations = 5
            var explorationCount = 0
            
            // First exploration with entropy-optimal path
            let firstPath = explorer.generateFirstPath()
            print("\n📊 Exploration 1: Entropy-optimal initial path")
            print("  Path: \(String(firstPath.prefix(24)))...")
            
            let firstResponse = try await client.explore(plans: [firstPath])
            let firstLabels = firstResponse.results[0]
            explorer.processExploration(path: firstPath, labels: firstLabels)
            
            let stats1 = explorer.getStatistics()
            print("  Results: Found \(stats1.rooms) rooms, mapped \(stats1.mappedConnections) connections")
            print("  Generated \(stats1.hypotheses) connection hypotheses")
            
            explorationCount = 1
            
            // Adaptive explorations
            while explorationCount < maxExplorations && !explorer.isComplete() {
                explorationCount += 1
                
                let adaptivePath = explorer.generateAdaptivePath()
                print("\n📊 Exploration \(explorationCount): Adaptive path")
                print("  Path: \(String(adaptivePath.prefix(24)))...")
                
                let response = try await client.explore(plans: [adaptivePath])
                let labels = response.results[0]
                explorer.processExploration(path: adaptivePath, labels: labels)
                
                let stats = explorer.getStatistics()
                print("  Results: Found \(stats.rooms) rooms, mapped \(stats.mappedConnections) connections")
                
                // Show top hypotheses
                let topHypotheses = explorer.getHypotheses().prefix(3)
                if !topHypotheses.isEmpty {
                    print("  Top hypotheses:")
                    for hyp in topHypotheses {
                        print("    Room \(hyp.fromRoom) door \(hyp.fromDoor) → Room \(hyp.toRoom) (confidence: \(String(format: "%.2f", hyp.confidence)))")
                    }
                }
                
                if explorer.isComplete() {
                    print("\n✅ SUCCESS! Mapped complete graph in \(explorationCount) explorations")
                    
                    // Show final mapping
                    let analyzer = explorer.getStateAnalyzer()
                    let rooms = analyzer.identifyRooms()
                    print("Final mapping:")
                    for room in rooms {
                        print("  Room \(room.id) (label \(room.label)):")
                        for door in 0..<6 {
                            if let conn = room.doors[door] {
                                if let toConn = conn {
                                    print("    Door \(door) → Room \(toConn.toRoomId)")
                                }
                            }
                        }
                    }
                    break
                }
            }
            
            if !explorer.isComplete() {
                print("\n⚠️ Could not complete mapping in \(maxExplorations) explorations")
                let stats = explorer.getStatistics()
                print("Final state: \(stats.rooms) rooms, \(stats.mappedConnections) connections mapped")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testAllMapsWithMultiIteration() async {
        print("\n📊 TESTING ALL CONFIGURATIONS")
        print(String(repeating: "=", count: 60))
        
        let configs = [
            ("two_rooms_single.config", 2),
            ("two_rooms_full.config", 2),
            ("three_rooms_one_loop.config", 3),
            ("three_rooms_two_loops.config", 3),
            ("three_rooms_three_loops.config", 3),
            ("three_rooms_four_loops.config", 3),
            ("three_rooms_five_loops.config", 3),
            ("six_rooms_circular.config", 6)
        ]
        
        var results: [(config: String, iterations: Int, success: Bool)] = []
        
        for (config, expectedRooms) in configs {
            let (iterations, success) = await testMapQuietly(config, expectedRooms: expectedRooms)
            results.append((config, iterations, success))
        }
        
        // Print summary
        print("\n📈 SUMMARY:")
        print(String(repeating: "-", count: 60))
        for result in results {
            let status = result.success ? "✅" : "❌"
            let configName = result.config.replacingOccurrences(of: ".config", with: "")
            print("\(status) \(configName): \(result.iterations) iterations")
        }
    }
    
    private static func testMapQuietly(_ configFile: String, expectedRooms: Int) async -> (iterations: Int, success: Bool) {
        do {
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            let explorer = AdaptiveExplorer(roomCount: actualConfig.roomIds.count)
            
            let maxIterations = 5
            var iteration = 0
            var isComplete = false
            
            while iteration < maxIterations && !isComplete {
                iteration += 1
                let path = iteration == 1 ? 
                    explorer.generateFirstPath() : 
                    explorer.generateAdaptivePath()
                
                let response = try await client.explore(plans: [path])
                explorer.processExploration(path: path, labels: response.results[0])
                
                let analyzer = explorer.getStateAnalyzer()
                let rooms = analyzer.identifyRooms()
                isComplete = analyzer.isComplete() && rooms.count == expectedRooms
            }
            
            return (iteration, isComplete)
        } catch {
            return (0, false)
        }
    }
    
    private static func testMultiIterationMapping(_ configFile: String) async {
        print("\n" + String(repeating: "=", count: 60))
        print("🎯 MULTI-ITERATION MAPPING: \(configFile)")
        print(String(repeating: "=", count: 60))
        
        do {
            // Load the actual map
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            print("\n📊 TARGET MAP:")
            print("  Rooms: \(actualConfig.roomIds.joined(separator: ", "))")
            print("  Labels: \(actualConfig.roomLabels)")
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Create adaptive explorer
            let explorer = AdaptiveExplorer(roomCount: actualConfig.roomIds.count)
            
            let maxIterations = 5
            var iteration = 0
            var isComplete = false
            
            print("\n🔄 ITERATIVE EXPLORATION:")
            
            while iteration < maxIterations && !isComplete {
                iteration += 1
                
                // Generate path based on current knowledge
                let path = iteration == 1 ? 
                    explorer.generateFirstPath() : 
                    explorer.generateAdaptivePath()
                
                print("\n📍 Iteration \(iteration):")
                print("   Path: \(String(path.prefix(36)))...")
                
                // Explore
                let response = try await client.explore(plans: [path])
                let labels = response.results[0]
                
                // Show label patterns
                print("   Labels: \(labels.prefix(37))")
                
                // Debug: Look for specific patterns that should map B:4 <-> C:4
                if configFile == "three_rooms_two_loops.config" && iteration == 2 {
                    // Check if we're exploring from B (label 1) through door 4
                    for i in 0..<min(path.count - 1, labels.count - 1) {
                        if labels[i] == 1 && i < path.count { // In room B
                            let door = String(path[path.index(path.startIndex, offsetBy: i)])
                            if door == "4" && labels[i+1] == 2 { // Goes to room C
                                print("   DEBUG: Found B:4 -> C at position \(i)")
                                // Now check what door from C returns to B
                                for j in i+1..<min(path.count - 1, labels.count - 1) {
                                    if labels[j] == 2 && labels[j+1] == 1 {
                                        let returnDoor = String(path[path.index(path.startIndex, offsetBy: j)])
                                        print("   DEBUG: Found C:\(returnDoor) -> B at position \(j)")
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Process exploration
                explorer.processExploration(path: path, labels: labels)
                
                // Get current state
                let stats = explorer.getStatistics()
                let analyzer = explorer.getStateAnalyzer()
                let rooms = analyzer.identifyRooms()
                
                print("   Progress: \(rooms.count) rooms, \(stats.mappedConnections) connections mapped")
                
                // Check if complete
                isComplete = analyzer.isComplete() && rooms.count == actualConfig.roomIds.count
                
                if isComplete {
                    print("\n✅ COMPLETE MAPPING IN \(iteration) ITERATIONS!")
                    break
                }
                
                // Show what's still unknown
                var unknownConnections: [(roomId: Int, door: Int)] = []
                for room in rooms {
                    for door in 0..<6 {
                        if room.doors[door] == nil {
                            unknownConnections.append((room.id, door))
                        }
                    }
                }
                
                if !unknownConnections.isEmpty && unknownConnections.count <= 10 {
                    print("   Unknown: ", terminator: "")
                    for (roomId, door) in unknownConnections.prefix(5) {
                        print("R\(roomId):D\(door) ", terminator: "")
                    }
                    if unknownConnections.count > 5 {
                        print("...", terminator: "")
                    }
                    print()
                }
            }
            
            // Show final mapping
            let analyzer = explorer.getStateAnalyzer()
            let rooms = analyzer.identifyRooms()
            
            print("\n📊 FINAL MAPPING:")
            for room in rooms.sorted(by: { $0.id < $1.id }) {
                print("  Room \(room.id) (label \(room.label)):")
                for door in 0..<6 {
                    if let conn = room.doors[door], let c = conn {
                        if c.toRoomId == room.id {
                            print("    Door \(door) → self-loop")
                        } else {
                            print("    Door \(door) → Room \(c.toRoomId) door \(c.toDoor ?? -1)")
                        }
                    } else {
                        print("    Door \(door) → ???")
                    }
                }
            }
            
            if !isComplete {
                print("\n⚠️ INCOMPLETE after \(iteration) iterations")
                print("  More sophisticated strategies needed")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testAdaptiveExplorationOnAllMaps() async {
        print("\n🔬 Testing adaptive exploration on all maps")
        
        let mapFiles = [
            "two_rooms_single.config",
            "two_rooms_full.config",
            "three_rooms_one_loop.config",
            "three_rooms_two_loops.config",
            "three_rooms_three_loops.config",
            "three_rooms_four_loops.config",
            "three_rooms_five_loops.config"
        ]
        
        for mapFile in mapFiles {
            await testAdaptiveExplorationDetailed(mapFile)
        }
    }
    
    private static func testAdaptiveExplorationDetailed(_ configFile: String) async {
        print("\n" + String(repeating: "=", count: 60))
        print("📍 DETAILED TEST: \(configFile)")
        print(String(repeating: "=", count: 60))
        
        do {
            // Load and show the actual map
            let actualConfig = try MapFileLoader.loadMap(from: configFile)
            print("\n🎯 ACTUAL MAP:")
            print("  Rooms: \(actualConfig.roomIds.joined(separator: ", "))")
            print("  Labels: \(actualConfig.roomLabels)")
            print("  Connections:")
            for conn in actualConfig.connections {
                print("    \(conn.from):\(conn.fromDoor) ↔ \(conn.to):\(conn.toDoor)")
            }
            
            // Create mock client
            let client = MockExplorationClient(layout: .fromConfig(configFile))
            
            // Test specific paths to understand the mapping
            print("\n🧪 EXPLORATION EXPERIMENTS:")
            
            // Test 1: Return pairs
            print("\n1️⃣ Testing return pairs pattern '001122334455':")
            let path1 = "001122334455"
            let response1 = try await client.explore(plans: [path1])
            let labels1 = response1.results[0]
            print("   Path: \(path1)")
            print("   Labels: \(labels1)")
            
            // Count return pairs found
            var returnPairsFound = 0
            for i in 0..<min(6, path1.count/2) {
                let startLabel = labels1[i*2]
                let midLabel = labels1[i*2 + 1]
                let endLabel = i*2 + 2 < labels1.count ? labels1[i*2 + 2] : -1
                
                if endLabel >= 0 && startLabel == endLabel && startLabel != midLabel {
                    returnPairsFound += 1
                }
            }
            print("   Found \(returnPairsFound) return pairs out of 6 doors tested")
            
            // Skip detailed debugging for other configs
            if configFile == "two_rooms_full.config" {
                // Test 2: Asymmetric patterns
                print("\n2️⃣ Testing asymmetric pattern '010203040512131415':")
                let path2 = "010203040512131415"
                let response2 = try await client.explore(plans: [path2])
                let labels2 = response2.results[0]
                print("   Path: \(path2)")
                print("   Labels: \(labels2)")
                
                // Test 3: Specific door combinations
                print("\n3️⃣ Testing specific combinations:")
                let testPaths = ["01", "10", "23", "32", "45", "54"]
                for testPath in testPaths {
                    let response = try await client.explore(plans: [testPath])
                    let labels = response.results[0]
                    print("   Path '\(testPath)': \(labels)")
                    if labels.count >= 3 && labels[0] == labels[2] {
                        print("     → Returns to start! Possible bidirectional connection")
                    }
                }
            }
            
            // Now run the adaptive explorer
            print("\n🤖 ADAPTIVE EXPLORER RESULTS:")
            let explorer = AdaptiveExplorer(roomCount: actualConfig.roomIds.count)
            
            // First exploration
            let firstPath = explorer.generateFirstPath()
            let firstResponse = try await client.explore(plans: [firstPath])
            explorer.processExploration(path: firstPath, labels: firstResponse.results[0])
            
            let stats1 = explorer.getStatistics()
            print("\nAfter exploration 1:")
            print("  Rooms found: \(stats1.rooms)")
            print("  Connections mapped: \(stats1.mappedConnections) / 12")
            
            // Show what StateTransitionAnalyzer found
            let analyzer = explorer.getStateAnalyzer()
            let rooms = analyzer.identifyRooms()
            print("\n📊 STATE ANALYZER MAPPING:")
            for room in rooms {
                print("  Room \(room.id) (label \(room.label)):")
                for door in 0..<6 {
                    if let conn = room.doors[door], let c = conn {
                        print("    Door \(door) → Room \(c.toRoomId) door \(c.toDoor ?? -1)")
                    } else {
                        print("    Door \(door) → UNKNOWN")
                    }
                }
            }
            
            // Check if complete
            if analyzer.isComplete() && rooms.count == actualConfig.roomIds.count {
                print("\n✅ COMPLETE MAPPING ACHIEVED!")
            } else {
                print("\n⚠️ INCOMPLETE MAPPING")
                print("  Need more explorations to disambiguate connections")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func testSimplePath() async {
        print("\n📍 Test: Path '000000' on three_rooms_five_loops")
        
        do {
            // Load the map
            let config = try MapFileLoader.loadMap(from: "three_rooms_five_loops.config")
            print("Loaded map with \(config.roomIds.count) rooms")
            
            // Create mock client with this config
            let client = MockExplorationClient(layout: .fromConfig("three_rooms_five_loops.config"))
            
            // Explore the path
            let response = try await client.explore(plans: ["000000"])
            let labels = response.results[0]
            print("Path: 000000")
            print("Labels: \(labels)")
            print("Label sequence: \(labels.map(String.init).joined())")
            
            // Try another path
            let response2 = try await client.explore(plans: ["555555"])
            let labels2 = response2.results[0]
            print("\nPath: 555555")
            print("Labels: \(labels2)")
            print("Label sequence: \(labels2.map(String.init).joined())")
            
            // Try a path that moves between rooms
            let response3 = try await client.explore(plans: ["5544"])
            let labels3 = response3.results[0]
            print("\nPath: 5544")  
            print("Labels: \(labels3)")
            print("Label sequence: \(labels3.map(String.init).joined())")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
}