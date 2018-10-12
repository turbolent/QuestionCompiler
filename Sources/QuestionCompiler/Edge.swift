
public indirect enum Edge<E, N>: Hashable
    where E: Hashable, N: Hashable
{
    public typealias Node = QuestionCompiler.Node<N, E>
    public typealias Edge = QuestionCompiler.Edge<E, N>

    case incoming(_ source: Node, _ label: E)
    case outgoing(_ label: E, _ target: Node)
    case conjunction(Set<Edge>)
    case disjunction(Set<Edge>)

    public func and(_ edge: Edge) -> Edge {
        switch (self, edge) {
        case let (.conjunction(edges), .conjunction(otherEdges)):
            return .conjunction(edges.union(otherEdges))
        case let (.conjunction(edges), _):
            var newEdges = edges
            newEdges.update(with: edge)
            return .conjunction(newEdges)
        case let (_, .conjunction(otherEdges)):
            var newEdges = otherEdges
            newEdges.update(with: self)
            return .conjunction(newEdges)
        default:
            return .conjunction([self, edge])
        }
    }

    public func or(_ edge: Edge) -> Edge {
        switch (self, edge) {
        case let (.disjunction(edges), .disjunction(otherEdges)):
            return .disjunction(edges.union(otherEdges))
        case let (.disjunction(edges), _):
            var newEdges = edges
            newEdges.update(with: edge)
            return .disjunction(newEdges)
        case let (_, .disjunction(otherEdges)):
            var newEdges = otherEdges
            newEdges.update(with: self)
            return .disjunction(newEdges)
        default:
            return .disjunction([self, edge])
        }
    }
}
