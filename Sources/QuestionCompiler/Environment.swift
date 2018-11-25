
public protocol Environment {
    associatedtype N: NodeLabel
    associatedtype E: EdgeLabel

    func newNode() -> Node<N, E>
}
