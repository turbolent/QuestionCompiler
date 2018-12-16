
import QuestionCompiler
import QuestionParser

public class TestEnvironment: Environment {
    private var count = 0

    public init() {}

    public func newNode() -> Node<TestNodeLabel, TestEdgeLabel> {
        defer { count += 1 }
        return Node(label: .variable(count))
    }
}
