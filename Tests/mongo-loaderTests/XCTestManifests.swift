import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(mongo_loaderTests.allTests),
    ]
}
#endif
