
import QuestionParser
import QuestionCompiler
import SPARQL

class TestSPARQLBackend: SPARQLBackend {

    typealias N = TestNodeLabel
    typealias E = TestEdgeLabel
    typealias Env = TestEnvironment

    func compile(nodeLabel: TestNodeLabel, env: TestEnvironment) -> SPARQL.Node {
        switch nodeLabel {
        case let .variable(name):
            return .variable(String(name))

        case let .id(name):
            return .iri(name)

        case let .string(value):
            return .literal(.plain(value))

        case let .number(value, _):
            return .literal(.withDatatype(String(value), .double))
        }
    }

    func compile(edgeLabel: TestEdgeLabel, env: TestEnvironment) -> SPARQL.Predicate {
        return .node(.iri(edgeLabel.name))
    }
}
