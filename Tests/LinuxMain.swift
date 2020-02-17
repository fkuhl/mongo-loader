import XCTest

import mongo_loaderTests

var tests = [XCTestCaseEntry]()
tests += mongo_loaderTests.allTests()
XCTMain(tests)
