
public struct Node<Labels>: Hashable
    where Labels: GraphLabels
{
    public typealias Node = GraphNode<Labels>
    public typealias Edge = GraphEdge<Labels>
    public typealias Filter = GraphFilter<Labels>

    public var label: Labels.Node
    public var edge: Edge?
    public var filter: Filter?
    public var order: Order?

    public init(
        label: Labels.Node,
        edge: Edge? = nil,
        filter: Filter? = nil,
        order: Order? = nil
    ) {
        self.label = label
        self.edge = edge
        self.filter = filter
        self.order = order
    }

    public func filtered(_ filter: Filter) -> Node {
        var result = self
        result.filter = result.filter.map { $0.and(filter) } ?? filter
        return result
    }

    public func outgoing(_ label: Labels.Edge, _ target: Node) -> Node {
        return and(.outgoing(label, target))
    }

    public func incoming(_ source: Node, _ label: Labels.Edge) -> Node {
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

    public func ordered(_ order: Order) -> Node {
        var result = self
        result.order = order
        return result
    }

    public func aggregating(
        _ node: Node,
        function: AggregateFunction,
        distinct: Bool,
        grouping: Node
    ) -> Node {
        let aggregate: Edge = .aggregate(
            node,
            function: function,
            distinct: distinct,
            grouping: grouping
        )
        return and(aggregate)
    }

    public static func &(lhs: Node, rhs: Edge) -> Node {
        return lhs.and(rhs)
    }

    public static func |(lhs: Node, rhs: Edge) -> Node {
        return lhs.or(rhs)
    }
}

extension Node: Encodable {

    private enum CodingKeys: CodingKey {
        case type
        case label
        case edge
        case filter
        case order
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("node", forKey: .type)
        try container.encode(label, forKey: .label)
        try container.encode(edge, forKey: .edge)
        try container.encode(filter, forKey: .filter)
        try container.encode(order, forKey: .order)
    }
}
