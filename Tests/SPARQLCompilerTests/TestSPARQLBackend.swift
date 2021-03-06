import QuestionCompiler
import QuestionParser
import SPARQL
import SPARQLCompiler
import TestGraphProvider

public class TestSPARQLBackend: SPARQLBackend {

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
