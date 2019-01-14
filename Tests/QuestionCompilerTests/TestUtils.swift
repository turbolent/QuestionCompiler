import QuestionCompiler
import QuestionParser
import TestOntology
import XCTest

func t(_ word: String, _ tag: String, _ lemma: String) -> Token {
    return Token(word: word, tag: tag, lemma: lemma)
}

typealias TestCompiler =
    QuestionCompiler<TestNodeLabel, TestEdgeLabel, TestEnvironment, TestOntology>

@available(OSX 10.13, *)
func diffJSON<T>(
    _ expected: String,
    _ actual: T,
    file: StaticString = #file,
    line: UInt = #line
    )
    where T: Encodable
{
    do {
        let actualEncodedData = try JSONEncoder().encode(actual)
        guard let expectedEncodedData = expected.data(using: .utf8) else {
            XCTFail("failed to UTF8-decode expected string")
            return
        }

        let expectedDecoded = try JSONSerialization.jsonObject(with: expectedEncodedData, options: [])
        let actualDecoded = try JSONSerialization.jsonObject(with: actualEncodedData, options: [])

        let expectedDecodedData = try JSONSerialization.data(
            withJSONObject: expectedDecoded,
            options: .sortedKeys
        )
        let actualDecodedData = try JSONSerialization.data(
            withJSONObject: actualDecoded,
            options: .sortedKeys
        )

        XCTAssertEqual(expectedDecodedData, actualDecodedData)

    } catch let error {
        XCTFail(error.localizedDescription,
                file: file,
                line: line)
    }
}
