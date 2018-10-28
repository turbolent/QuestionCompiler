
public struct Node<N, E>: Equatable
    where N: Equatable & Encodable,
        E: Equatable & Encodable
{
    public typealias Node = GraphNode<N, E>
    public typealias Edge = GraphEdge<E, N>
    public typealias Filter = GraphFilter<N, E>

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

extension Node: Encodable {

    private enum CodingKeys: CodingKey {
        case type
        case label
        case edge
        case filter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("node", forKey: .type)
        try container.encode(label, forKey: .label)
        try container.encode(edge, forKey: .edge)
        try container.encode(filter, forKey: .filter)
    }
}
