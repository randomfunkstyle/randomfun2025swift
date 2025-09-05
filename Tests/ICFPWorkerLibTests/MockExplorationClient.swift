
import XCTest
@testable import ICFPWorkerLib

final class MockExplorationClientTests: XCTestCase {
    
    func testEquialency() async throws {
        let mockClient = MockExplorationClient()
        XCTAssertTrue(mockClient.mapsAreEquivalent(map1: mockClient.correctMap!, map2: mockClient.correctMap!))
    }

    func testEquialency2() async throws {
        let mockClient = MockExplorationClient()
        XCTAssertTrue(mockClient.mapsAreEquivalent(map1: MockExplorationClient.generateThreeRooms(offset: 0),
                                                   map2: MockExplorationClient.generateThreeRooms(offset: 1)))
    }

}
