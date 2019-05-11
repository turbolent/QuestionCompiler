import QuestionParser
import OrderedSet


public indirect enum Filter<Labels>: Hashable
    where Labels: GraphLabels,
        Labels.Node: Hashable,
        Labels.Edge: Hashable
{
    public typealias Node = GraphNode<Labels>
    public typealias Filter = GraphFilter<Labels>

    case conjunction(OrderedSet<Filter>)
    case equals(Node)
    case lessThan(Node)
    case greaterThan(Node)

    public func and(_ filter: Filter) -> Filter {
        switch (self, filter) {
        case let (.conjunction(filters), .conjunction(otherFilters)):
            return .conjunction(filters.union(otherFilters))
        case let (.conjunction(filters), _):
            var newFilters = filters
            newFilters.insert(filter)
            return .conjunction(newFilters)
        case let (_, .conjunction(filters)):
            var newFilters: OrderedSet = [self]
            newFilters.formUnion(filters)
            return .conjunction(newFilters)
        default:
            return .conjunction([self, filter])
        }
    }
}


extension Filter: Encodable
    where Labels.Node: Encodable, Labels.Edge: Encodable
{
    private enum CodingKeys: CodingKey {
        case type
        case subtype
        case filters
        case node
    }

    private enum Subtype: String, Encodable {
        case conjunction
        case equals
        case lessThan = "less-than"
        case greaterThan = "greater-than"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("filter", forKey: .type)

        switch self {
        case let .conjunction(filters):
            try container.encode(Subtype.conjunction, forKey: .subtype)
            try container.encode(filters, forKey: .filters)

        case let .equals(node):
            try container.encode(Subtype.equals, forKey: .subtype)
            try container.encode(node, forKey: .node)

        case let .lessThan(node):
            try container.encode(Subtype.lessThan, forKey: .subtype)
            try container.encode(node, forKey: .node)

        case let .greaterThan(node):
            try container.encode(Subtype.greaterThan, forKey: .subtype)
            try container.encode(node, forKey: .node)
        }
    }
}
