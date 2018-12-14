
import SPARQL

public protocol SPARQLBackend {
    associatedtype N
    associatedtype E
    associatedtype Env: Environment
        where Env.N == N, Env.E == E

    typealias Node = GraphNode<N, E>
    typealias Edge = GraphEdge<E, N>

    /// Return a SPARQL node for the given node label
    func compile(nodeLabel: N, env: Env) -> SPARQL.Node

    /// Return a SPARQL node or path for the given edge label
    func compile(edgeLabel: E, env: Env) -> SPARQL.Predicate

    //// optional hooks

    /// Expand the given node into another, possibly more complex node, if needed
    func expand(node: Node, context: NodeCompilationContext, env: Env) -> Node

    func prepare(leftExpression: SPARQL.Expression, otherNode: Node) -> SPARQL.Expression

    func prepare(op: SPARQL.Op, variables: [String], env: Env) -> SPARQL.Op

    func additionalResultVariables(variables: [String], env: Env) -> [String]
}

extension SPARQLBackend {

    public func expand(node: Node, context: NodeCompilationContext, env: Env) -> Node {
        return node
    }

    public func prepare(leftExpression: SPARQL.Expression, otherNode: Node) -> SPARQL.Expression {
        return leftExpression
    }

    public func prepare(op: SPARQL.Op, variables: [String], env: Env) -> SPARQL.Op {
        return op
    }

    public func additionalResultVariables(variables: [String], env: Env) -> [String] {
        return []
    }
}

