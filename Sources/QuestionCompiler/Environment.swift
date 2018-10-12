
public protocol Environment {
    associatedtype N: Hashable
    associatedtype E: Hashable

    func newNode() -> Node<N, E>
}
