
import QuestionParser
import QuestionCompiler

func t(_ word: String, _ tag: String, _ lemma: String) -> Token {
    return Token(word: word, tag: tag, lemma: lemma)
}

typealias TestCompiler =
    Compiler<TestNodeLabel, TestEdgeLabel, TestEnvironment, TestOntology>

func newCompiler() -> TestCompiler {
    let environment = TestEnvironment()
    let ontology = TestOntology()
    return Compiler(environment: environment, ontology: ontology)
}
