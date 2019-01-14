import QuestionCompiler
import QuestionParser
import SPARQL
import SPARQLCompiler
import TestOntology

public class TestSPARQLBackend: SPARQLBackend {

    public typealias N = TestNodeLabel
    public typealias E = TestEdgeLabel
    public typealias Env = TestEnvironment

    public init() {}

    public func compile(nodeLabel: TestNodeLabel, env: TestEnvironment) -> SPARQL.Node {
        switch nodeLabel {
        case let .variable(name):
            return .variable(String(name))

        case let .item(name):
            return .iri(name)

        case let .string(value):
            return .literal(.plain(value))

        case let .number(value, _):
            return .literal(.withDatatype(String(value), .double))
        }
    }

    public func compile(edgeLabel: TestEdgeLabel, env: TestEnvironment) -> SPARQL.Predicate {
        return .node(.iri(edgeLabel.name))
    }
}
