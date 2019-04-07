import QuestionCompiler
import QuestionParser
import TestGraphProvider
import XCTest

func t(_ word: String, _ tag: String, _ lemma: String) -> Token {
    return Token(word: word, tag: tag, lemma: lemma)
}

typealias TestCompiler = QuestionCompiler<TestGraphProvider>
