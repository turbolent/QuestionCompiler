
import QuestionParser

public indirect enum Filter<N, E>: Hashable
    where N: Hashable, E: Hashable
{
    public typealias Node = QuestionCompiler.Node<N, E>
    public typealias Filter = QuestionCompiler.Filter<N, E>

    case conjunction(Set<Filter>)
    case equals(Node)
    case lessThan(Node)
    case greaterThan(Node)

    func and(_ filter: Filter) -> Filter {
        switch (self, filter) {
        case let (.conjunction(filters), .conjunction(otherFilters)):
            return .conjunction(filters.union(otherFilters))
        case let (.conjunction(filters), _):
            var newFilters = filters
            newFilters.update(with: filter)
            return .conjunction(newFilters)
        case let (_, .conjunction(filters)):
            var newFilters = filters
            newFilters.update(with: self)
            return .conjunction(newFilters)
        default:
            return .conjunction([self, filter])
        }
    }
}
