import XCTest
@testable import ICFPWorkerLib

final class ICFPWorkerTests: XCTestCase {
    
    var worker: ICFPWorker!
    
    override func setUpWithError() throws {
        worker = ICFPWorker()
    }
    
    override func tearDownWithError() throws {
        worker = nil
    }
    
    func testProcessInput() throws {
        let input = "test input"
        let result = worker.process(input)
        XCTAssertEqual(result, "Processed: test input")
    }
    
    func testProcessEmptyInput() throws {
        let input = ""
        let result = worker.process(input)
        XCTAssertEqual(result, "Processed: ")
    }
    
    func testCalculation() throws {
        let result = worker.calculate(a: 5, b: 3)
        XCTAssertEqual(result, 8)
    }
    
    func testCalculationWithZero() throws {
        let result = worker.calculate(a: 0, b: 0)
        XCTAssertEqual(result, 0)
    }
    
    func testCalculationWithNegatives() throws {
        let result = worker.calculate(a: -5, b: 3)
        XCTAssertEqual(result, -2)
    }
    
    func testValidateValidData() throws {
        let validData = "valid data"
        XCTAssertTrue(worker.validate(validData))
    }
    
    func testValidateEmptyData() throws {
        let emptyData = ""
        XCTAssertFalse(worker.validate(emptyData))
    }
    
    func testValidateShortData() throws {
        let shortData = "ab"
        XCTAssertFalse(worker.validate(shortData))
    }
    
    func testValidateMinimalValidData() throws {
        let minimalData = "abc"
        XCTAssertTrue(worker.validate(minimalData))
    }
}