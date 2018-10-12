import XCTest

extension QuestionCompilerTests {
    static let __allTests = [
        ("testQ10", testQ10),
        ("testQ11", testQ11),
        ("testQ12", testQ12),
        ("testQ13", testQ13),
        ("testQ14", testQ14),
        ("testQ15", testQ15),
        ("testQ16", testQ16),
        ("testQ17", testQ17),
        ("testQ18", testQ18),
        ("testQ1", testQ1),
        ("testQ2", testQ2),
        ("testQ3", testQ3),
        ("testQ4", testQ4),
        ("testQ5", testQ5),
        ("testQ6", testQ6),
        ("testQ7", testQ7),
        ("testQ8", testQ8),
        ("testQ9", testQ9),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(QuestionCompilerTests.__allTests),
    ]
}
#endif
