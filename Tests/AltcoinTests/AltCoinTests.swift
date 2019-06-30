import XCTest
@testable import Altcoin

final class AltcoinTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Altcoin().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
