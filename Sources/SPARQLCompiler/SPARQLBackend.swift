
import QuestionCompiler
import SPARQL

public protocol SPARQLBackend {
    associatedtype Env: Environment

    typealias Node = GraphNode<Env.T>
    typealias Edge = GraphEdge<Env.T>

    /// Return a SPARQL node for the given node label
    func compile(nodeLabel: Env.T.Node, env: Env) -> SPARQL.Node

    /// Return a SPARQL node or path for the given edge label
    func compile(edgeLabel: Env.T.Edge, env: Env) -> SPARQL.Predicate

    //// optional hooks

    /// Expand the given node into another, possibly more complex node, if needed
    func expand(node: Node, context: NodeContext, env: Env) -> Node

    func prepare(leftExpression: SPARQL.Expression, otherNode: Node) -> SPARQL.Expression

    func prepare(op: SPARQL.Op, variables: [String], env: Env) -> SPARQL.Op

    func additionalResultVariables(variables: [String], env: Env) -> [String]
}

extension SPARQLBackend {
    public func expand(node: Node, context _: NodeContext, env _: Env) -> Node {
        return node
    }

    public func prepare(leftExpression: SPARQL.Expression, otherNode _: Node) -> SPARQL.Expression {
        return leftExpression
    }

    public func prepare(op: SPARQL.Op, variables _: [String], env _: Env) -> SPARQL.Op {
        return op
    }

    public func additionalResultVariables(variables _: [String], env _: Env) -> [String] {
        return []
    }
}
