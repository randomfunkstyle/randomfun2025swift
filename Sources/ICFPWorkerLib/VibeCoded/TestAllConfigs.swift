import Foundation

/// Test all config files and verify consistency
public class TestAllConfigs {
    
    public static func testAllConfigFiles() {
        print("\n🔍 Testing All Config Files")
        print(String(repeating: "=", count: 50))
        
        let configFiles = [
            "two_rooms_single.config",
            "two_rooms_full.config", 
            "three_rooms_one_loop.config",
            "three_rooms_two_loops.config",
            "three_rooms_three_loops.config",
            "three_rooms_four_loops.config",
            "three_rooms_five_loops.config",
            "large_test.config"
        ]
        
        var passCount = 0
        var failCount = 0
        
        for configFile in configFiles {
            print("\n📄 Testing: \(configFile)")
            
            do {
                // Load config (this will auto-generate markdown)
                let config = try MapFileLoader.loadMap(from: configFile)
                
                // Verify basic properties
                print("   ✅ Loaded successfully")
                print("   • Rooms: \(config.roomIds.count) [\(config.roomIds.joined(separator: ", "))]")
                print("   • Labels: \(config.roomLabels)")
                print("   • Connections: \(config.connections.count)")
                print("   • Start room: \(config.startRoom)")
                
                // Verify markdown was generated
                let mdFile = configFile.replacingOccurrences(of: ".config", with: ".md")
                let basePath = #file.replacingOccurrences(of: "Sources/ICFPWorkerLib/VibeCoded/TestAllConfigs.swift", with: "")
                let mdPath = basePath + "Resources/TestMaps/" + mdFile
                
                if FileManager.default.fileExists(atPath: mdPath) {
                    print("   ✅ Markdown file exists: \(mdFile)")
                    
                    // Read and verify markdown content
                    let mdContent = try String(contentsOfFile: mdPath, encoding: .utf8)
                    
                    // Check that markdown contains all room IDs
                    var allRoomsPresent = true
                    for roomId in config.roomIds {
                        if !mdContent.contains("\(roomId)((") {
                            print("   ⚠️  Room \(roomId) not found in markdown")
                            allRoomsPresent = false
                        }
                    }
                    
                    if allRoomsPresent {
                        print("   ✅ All rooms present in markdown")
                    }
                    
                    // Check mermaid structure
                    if mdContent.contains("```mermaid") && mdContent.contains("graph TD") {
                        print("   ✅ Valid mermaid structure")
                    } else {
                        print("   ❌ Invalid mermaid structure")
                    }
                    
                } else {
                    print("   ❌ Markdown file not found: \(mdFile)")
                    failCount += 1
                    continue
                }
                
                passCount += 1
                
            } catch {
                print("   ❌ Error: \(error)")
                failCount += 1
            }
        }
        
        print("\n" + String(repeating: "=", count: 50))
        print("📊 Results: \(passCount) passed, \(failCount) failed")
        
        if failCount == 0 {
            print("✅ All config files are consistent!")
        } else {
            print("⚠️  Some config files have issues")
        }
    }
}