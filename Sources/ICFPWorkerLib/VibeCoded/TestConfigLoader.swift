import Foundation

/// Test the config loading system
public class TestConfigLoader {
    
    public static func testLoadConfig() {
        print("🔧 Testing Config System Validation")
        print(String(repeating: "=", count: 50))
        
        // Test 1: Valid config
        testValidConfig()
        
        // Test 2: Invalid configs
        testInvalidConfigs()
        
        print("\n🎯 Validation Tests Complete!")
    }
    
    private static func testValidConfig() {
        print("\n📝 Testing Valid Configs:")
        
        // Test 1: Two rooms config
        do {
            let config = try MapFileLoader.loadMap(from: "two_rooms_single.config")
            print("✅ Two rooms: Loaded \(config.roomIds.count) rooms, \(config.connections.count) connections")
            
            let configMap = try MapConfigGenerator.loadConfig(from: "two_rooms_single.config")
            let _ = MapConfigGenerator.generateMarkdown(config: configMap, title: "Test Generated")
            print("✅ Generated markdown successfully")
            
        } catch {
            print("❌ Two rooms error: \(error)")
        }
        
        // Test 2: Four rooms with lowercase
        do {
            let config = try MapFileLoader.loadMap(from: "large_test.config")
            print("✅ Four rooms (with lowercase): Loaded \(config.roomIds.count) rooms, \(config.connections.count) connections")
            print("   Room IDs: \(config.roomIds.joined(separator: ", "))")
            
        } catch {
            print("❌ Four rooms error: \(error)")
        }
    }
    
    private static func testInvalidConfigs() {
        print("\n🚨 Testing Invalid Configs (should fail):")
        
        let invalidConfigs = [
            // Missing room count
            ("", "Empty config file"),
            
            // Invalid room count
            ("abc\nROOMS:\nA 0", "First line must be number of rooms"),
            
            // Room count out of range
            ("0\nROOMS:", "Number of rooms must be between 1 and 52"),
            ("53\nROOMS:", "Number of rooms must be between 1 and 52"),
            
            // Missing sections
            ("2\nA 0\nB 1", "Missing required 'ROOMS:' section"),
            ("2\nROOMS:\nA 0\nB 1", "Missing required 'CONNECTIONS:' section"),
            
            // Invalid room format
            ("1\nROOMS:\nA", "Invalid room format"),
            ("1\nROOMS:\nA B C", "Invalid room format"),
            ("1\nROOMS:\nA abc", "Invalid room label"),
            
            // Invalid room ID
            ("1\nROOMS:\nAB 0\nCONNECTIONS:", "Room ID 'AB' must be a single letter"),
            ("1\nROOMS:\n1 0\nCONNECTIONS:", "Room ID '1' must be a single letter"),
            
            // Invalid label range
            ("1\nROOMS:\nA 4\nCONNECTIONS:", "Room label 4 must be between 0 and 3"),
            ("1\nROOMS:\nA -1\nCONNECTIONS:", "Room label -1 must be between 0 and 3"),
            
            // Duplicate room ID
            ("2\nROOMS:\nA 0\nA 1\nCONNECTIONS:", "Duplicate room ID: A"),
            
            // Wrong room count
            ("2\nROOMS:\nA 0\nCONNECTIONS:", "Expected 2 rooms, found 1 room definitions"),
            
            // Invalid connection format
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nA0", "Invalid connection format"),
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nA0 B0 C0", "Invalid connection format"),
            
            // Invalid door numbers
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nA6 A0", "Door number 6 in 'A6 A0' must be between 0 and 5"),
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nA0 A-1", "Invalid connection format"),
            
            // Unknown room in connection
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nB0 A0", "Unknown room 'B' in connection 'B0 A0'"),
            
            // Wrong connection count
            ("1\nROOMS:\nA 0\nCONNECTIONS:\nA0 A0\nA1 A1", "Expected 6 connections (1 rooms × 6 doors), found 2")
        ]
        
        for (i, (config, expectedError)) in invalidConfigs.enumerated() {
            print("  Test \(i + 1): ", terminator: "")
            do {
                _ = try MapFileLoader.parseMap(config)
                print("❌ Should have failed: \(expectedError)")
            } catch {
                let errorMsg = String(describing: error)
                if errorMsg.contains(expectedError) || expectedError.isEmpty {
                    print("✅ Correctly rejected: \(expectedError)")
                } else {
                    print("⚠️  Wrong error - Expected: '\(expectedError)', Got: '\(errorMsg)'")
                }
            }
        }
    }
}