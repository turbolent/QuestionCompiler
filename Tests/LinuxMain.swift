import XCTest

import QuestionCompilerTests
import SPARQLCompilerTests

var tests = [XCTestCaseEntry]()
tests += QuestionCompilerTests.__allTests()
tests += SPARQLCompilerTests.__allTests()

XCTMain(tests)
