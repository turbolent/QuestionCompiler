
import QuestionParser
import QuestionCompiler

class TestEnvironment: Environment {
    private var count = 0

    func newNode() -> Node<TestNodeLabel, TestEdgeLabel> {
        defer { count += 1 }
        return Node(label: .variable(count))
    }
}
