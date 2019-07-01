import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AltCoinTests.allTests),
        testCase(SubsetTests.allTests)
    ]
}
#endif
