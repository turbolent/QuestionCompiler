
public struct Node<N, E>: Hashable
    where N: Hashable, E: Hashable
{
    public typealias Node = QuestionCompiler.Node<N, E>
    public typealias Edge = QuestionCompiler.Edge<E, N>
    public typealias Filter = QuestionCompiler.Filter<N, E>

    public var label: N
    public var edge: Edge?
    public var filter: Filter?

    public init(
        label: N,
        edge: Edge? = nil,
        filter: Filter? = nil
    ) {
        self.label = label
        self.edge = edge
        self.filter = filter
    }

    public func filtered(_ filter: Filter) -> Node {
        var result = self
        result.filter = result.filter.map { $0.and(filter) } ?? filter
        return result
    }

    public func outgoing(_ label: E, _ target: Node) -> Node {
        return and(.outgoing(label, target))
    }

    public func incoming(_ source: Node, _ label: E) -> Node {
        return and(.incoming(source, label))
    }

    public func and(_ edge: Edge) -> Node {
        var result = self
        result.edge = result.edge.map { $0.and(edge) } ?? edge
        return result
    }

    public func or(_ edge: Edge) -> Node {
        var result = self
        result.edge = result.edge.map { $0.or(edge) } ?? edge
        return result
    }
}
