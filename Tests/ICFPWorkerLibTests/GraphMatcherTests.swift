import XCTest
@testable import ICFPWorkerLib

final class GraphMatcherTests: XCTestCase {
    
    func testHelloWorld() {
        let matcher = GraphMatcher()
        let result = matcher.helloWorld()
        XCTAssertEqual(result, "Hello, World!")
    }
}