
public protocol Environment {
    associatedtype T: Labels

    func newNode() -> Node<T>
}
