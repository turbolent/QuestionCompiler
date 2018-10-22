
public indirect enum Edge<E, N>: Hashable
    where E: Hashable, N: Hashable
{
    public typealias Node = GraphNode<N, E>
    public typealias Edge = GraphEdge<E, N>

    case incoming(_ source: Node, _ label: E)
    case outgoing(_ label: E, _ target: Node)
    case conjunction([Edge])
    case disjunction([Edge])

    public func and(_ edge: Edge) -> Edge {
        switch (self, edge) {
        case let (.conjunction(edges), .conjunction(otherEdges)):
            return .conjunction(edges + otherEdges)

        case let (.conjunction(edges), _):
            var newEdges = edges
            newEdges.append(edge)
            return .conjunction(newEdges)

        case let (_, .conjunction(otherEdges)):
            var newEdges = [self]
            newEdges.append(contentsOf: otherEdges)
            return .conjunction(newEdges)

        default:
            return .conjunction([self, edge])
        }
    }

    public func or(_ edge: Edge) -> Edge {
        switch (self, edge) {
        case let (.disjunction(edges), .disjunction(otherEdges)):
            return .disjunction(edges + otherEdges)

        case let (.disjunction(edges), _):
            var newEdges = edges
            newEdges.append(edge)
            return .disjunction(newEdges)

        case let (_, .disjunction(otherEdges)):
            var newEdges = [self]
            newEdges.append(contentsOf: otherEdges)
            return .disjunction(newEdges)

        default:
            return .disjunction([self, edge])
        }
    }
}
