
public protocol Environment {
    associatedtype Labels: GraphLabels

    func newNode() -> Node<Labels>
}
