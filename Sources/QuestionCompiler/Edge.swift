import OrderedSet


public indirect enum Edge<Labels>: Hashable
    where Labels: GraphLabels,
        Labels.Edge: Hashable,
        Labels.Node: Hashable
{
    public typealias Node = GraphNode<Labels>
    public typealias Edge = GraphEdge<Labels>

    case incoming(_ source: Node, _ label: Labels.Edge)
    case outgoing(_ label: Labels.Edge, _ target: Node)
    case conjunction(OrderedSet<Edge>)
    case disjunction(OrderedSet<Edge>)
    case aggregate(
        Node,
        function: AggregateFunction,
        distinct: Bool,
        grouping: Node
    )

    public init<C>(conjunction edges: C)
        where C: Collection, C.Element == Edge
    {
        guard let firstEdge = edges.first else {
            self = .conjunction([])
            return
        }

        if edges.dropFirst().first == nil {
            self = firstEdge
        } else {
            self = .conjunction(OrderedSet(edges))
        }
    }

    public init<C>(disjunction edges: C)
        where C: Collection, C.Element == Edge
    {
        guard let firstEdge = edges.first else {
            self = .disjunction([])
            return
        }

        if edges.dropFirst().first == nil {
            self = firstEdge
        } else {
            self = .disjunction(OrderedSet(edges))
        }
    }

    public func and(_ edge: Edge) -> Edge {
        switch (self, edge) {
        case let (.conjunction(edges), .conjunction(otherEdges)):
            return .conjunction(edges.union(otherEdges))

        case let (.conjunction(edges), _):
            var newEdges = edges
            newEdges.insert(edge)
            return .conjunction(newEdges)

        case let (_, .conjunction(otherEdges)):
            var newEdges: OrderedSet = [self]
            newEdges.formUnion(otherEdges)
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
            newEdges.insert(edge)
            return .disjunction(newEdges)

        case let (_, .disjunction(otherEdges)):
            var newEdges: OrderedSet = [self]
            newEdges.formUnion(otherEdges)
            return .disjunction(newEdges)

        default:
            return .disjunction([self, edge])
        }
    }

    public static func &(lhs: Edge, rhs: Edge) -> Edge {
        return lhs.and(rhs)
    }

    public static func |(lhs: Edge, rhs: Edge) -> Edge {
        return lhs.or(rhs)
    }
}


extension Edge: Encodable
    where Labels.Edge: Encodable, Labels.Node: Encodable
{
    private enum CodingKeys: CodingKey {
        case type
        case subtype
        case source
        case target
        case label
        case edges
        case node
        case function
        case distinct
        case grouping
    }

    private enum Subtype: String, Encodable {
        case incoming
        case outgoing
        case conjunction
        case disjunction
        case aggregate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("edge", forKey: .type)

        switch self {
        case let .incoming(source, label):
            try container.encode(Subtype.incoming, forKey: .subtype)
            try container.encode(source, forKey: .source)
            try container.encode(label, forKey: .label)

        case let .outgoing(label, target):
            try container.encode(Subtype.outgoing, forKey: .subtype)
            try container.encode(label, forKey: .label)
            try container.encode(target, forKey: .target)

        case let .conjunction(edges):
            try container.encode(Subtype.conjunction, forKey: .subtype)
            try container.encode(edges, forKey: .edges)

        case let .disjunction(edges):
            try container.encode(Subtype.disjunction, forKey: .subtype)
            try container.encode(edges, forKey: .edges)

        case let .aggregate(node, function, distinct, grouping):
            try container.encode(Subtype.aggregate, forKey: .subtype)
            try container.encode(node, forKey: .node)
            try container.encode(function, forKey: .function)
            try container.encode(distinct, forKey: .distinct)
            try container.encode(grouping, forKey: .grouping)
        }
    }
}
