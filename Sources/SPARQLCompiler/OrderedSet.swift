
public struct OrderedSet<Element> where Element: Hashable {
    public private(set) var elements: [Element] = []
    private var set: Set<Element> = Set()

    public init<S>(_ sequence: S) where S: Sequence, Element == S.Element {
        sequence.forEach { append($0) }
    }

    public mutating func append<S>(contentsOf newElements: S) where S: Sequence, Element == S.Element {
        newElements.forEach { append($0) }
    }

    public mutating func append(_ newElement: Element) {
        let (inserted, _) = set.insert(newElement)
        guard inserted else { return }
        elements.append(newElement)
    }

    public func union<S>(_ other: S) -> OrderedSet<Element> where S: Sequence, Element == S.Element {
        var result = self
        result.append(contentsOf: other)
        return result
    }
}

extension OrderedSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
