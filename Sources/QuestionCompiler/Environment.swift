
public protocol Environment {
    associatedtype N: Equatable & Encodable
    associatedtype E: Equatable & Encodable

    func newNode() -> Node<N, E>
}
