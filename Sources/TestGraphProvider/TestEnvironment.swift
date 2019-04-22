
import QuestionCompiler
import QuestionParser

public final class TestEnvironment: Environment {
    private var count = 0

    public init() {}

    public func newNode() -> Node<TestLabels> {
        defer { count += 1 }
        return Node(label: .variable(count))
    }
}
