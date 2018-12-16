
import SPARQL

public struct NodeResult {
    var primaryNodes: OrderedSet<SPARQL.Node>
    var secondaryNodes: OrderedSet<SPARQL.Node>
    var opResult: OpResult

    init(
        primaryNodes: OrderedSet<SPARQL.Node>,
        secondaryNodes: OrderedSet<SPARQL.Node>,
        opResult: OpResult
    ) {
        self.primaryNodes = primaryNodes
        self.secondaryNodes = secondaryNodes
        self.opResult = opResult
    }

    init(compiledNode: SPARQL.Node) {
        self.init(
            compiledNode: compiledNode,
            opResult: .identity
        )
    }

    init(compiledNode: SPARQL.Node, opResult: OpResult) {
        self.init(
            primaryNodes: [compiledNode],
            secondaryNodes: [],
            opResult: opResult
        )
    }

    func merge(_ other: NodeResult, merge: OpResultMerger) -> NodeResult {
        var result = self
        result.primaryNodes = result.primaryNodes.union(other.primaryNodes.elements)
        result.secondaryNodes = result.secondaryNodes.union(other.secondaryNodes.elements)
        result.opResult = merge(other.opResult, result.opResult)
        return result
    }

    var allNodes: OrderedSet<SPARQL.Node> {
        return primaryNodes.union(secondaryNodes.elements)
    }
}
