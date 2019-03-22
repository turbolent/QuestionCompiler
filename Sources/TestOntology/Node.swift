
import QuestionCompiler

public extension Node
    where Labels.Node == TestNodeLabel,
        Labels.Edge == TestEdgeLabel
{
    func isA(_ class: Node) -> Node {
        return outgoing(.isA, `class`)
    }

    func hasName(_ name: String) -> Node {
        let target = Node(label: TestNodeLabel.string(name))
        return outgoing(.hasName, target)
    }

    static func number(_ number: Double, unit: String? = nil) -> Node {
        return Node(label:
            TestNodeLabel.number(number, unit: unit)
        )
    }
}
