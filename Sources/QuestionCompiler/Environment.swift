
public protocol Environment {
    associatedtype Labels: GraphLabels
        where Labels.Node: Hashable,
            Labels.Edge: Hashable

    func newNode() -> Node<Labels>
}
