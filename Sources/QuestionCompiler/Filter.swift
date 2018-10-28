
import QuestionParser

public indirect enum Filter<N, E>: Equatable
    where N: Equatable & Encodable,
        E: Equatable & Encodable
{
    public typealias Node = GraphNode<N, E>
    public typealias Filter = GraphFilter<N, E>

    case conjunction([Filter])
    case equals(Node)
    case lessThan(Node)
    case greaterThan(Node)

    func and(_ filter: Filter) -> Filter {
        switch (self, filter) {
        case let (.conjunction(filters), .conjunction(otherFilters)):
            return .conjunction(filters + otherFilters)
        case let (.conjunction(filters), _):
            var newFilters = filters
            newFilters.append(filter)
            return .conjunction(newFilters)
        case let (_, .conjunction(filters)):
            var newFilters = [self]
            newFilters.append(contentsOf: filters)
            return .conjunction(newFilters)
        default:
            return .conjunction([self, filter])
        }
    }
}


extension Filter: Encodable {

    private enum CodingKeys: CodingKey {
        case type
        case subtype
        case filters
        case node
    }

    private enum Subtype: String, Encodable {
        case conjunction
        case equals
        case lessThan
        case greaterThan
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