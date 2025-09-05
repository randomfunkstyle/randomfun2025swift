import Foundation

/// Test disconnected graph validation
public class TestDisconnected {
    
    public static func test() {
        print("🔍 Testing disconnected graph validation")
        
        do {
            _ = try MapFileLoader.loadMap(from: "test_disconnected.config")
            print("❌ Should have failed - graph is disconnected!")
        } catch {
            print("✅ Correctly rejected disconnected graph:")
            print("   \(error)")
        }
    }
}