
import QuestionParser

public indirect enum Filter<N, E>: Hashable
    where N: Hashable, E: Hashable
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
