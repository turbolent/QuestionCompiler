
import QuestionParser
import QuestionCompiler
import TestOntology

func t(_ word: String, _ tag: String, _ lemma: String) -> Token {
    return Token(word: word, tag: tag, lemma: lemma)
}

typealias TestCompiler =
    QuestionCompiler<TestNodeLabel, TestEdgeLabel, TestEnvironment, TestOntology>
