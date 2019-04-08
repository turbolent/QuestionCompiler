
import QuestionCompiler
import SPARQL

public final class SPARQLCompiler<Backend>
    where Backend: SPARQLBackend,
        Backend.Env.Labels.Node: Hashable,
        Backend.Env.Labels.Edge: Hashable
{

    public typealias Node = GraphNode<Backend.Env.Labels>
    public typealias Edge = GraphEdge<Backend.Env.Labels>
    public typealias Filter = GraphFilter<Backend.Env.Labels>

    public enum Error: Swift.Error {
        case missingEdge
        case finalNodeNotCompiledToVariable
        case aggregatedNodeNotCompiledToVariable
        case groupingNodeNotCompiledToVariable
    }

    private let environment: Backend.Env
    private let backend: Backend
    private var nodeResults: [Node: NodeResult] = [:]

    public init(environment: Backend.Env, backend: Backend) {
        self.environment = environment
        self.backend = backend
    }

    private func compile(
        aggregateFunction: AggregateFunction,
        distinct: Bool,
        compiledNode: SPARQL.Node
    )
        -> SPARQL.Aggregation
    {
        let expression: Expression = .node(compiledNode)
        switch aggregateFunction {
        case .avg:
            return .avg(expression, distinct: distinct)
        case .count:
            return .count(expression, distinct: distinct)
        case .min:
            return .min(expression, distinct: distinct)
        case .max:
            return .max(expression, distinct: distinct)
        case .sample:
            return .sample(expression, distinct: distinct)
        case .sum:
            return .sum(expression, distinct: distinct)
        case .groupConcat:
            return .groupConcat(expression, distinct: distinct, separator: "\u{001F}")
        }
    }

    private func compile(order: GraphOrder) -> SPARQL.Order {
        switch order {
        case .ascending:
            return .ascending
        case .descending:
            return .descending
        }
    }

    private func compile(filter: Filter, compiledNode: SPARQL.Node, opResult: OpResult) throws -> OpResult {

        typealias ExpressionMerger =
            (SPARQL.Expression, SPARQL.Expression) -> SPARQL.Expression

        func compileBinaryExpression(otherNode: Node, merge: ExpressionMerger) throws -> OpResult {

            // TODO: verify secondary nodes can be ignored in closure and result
            let otherNodeResult =
                try compile(node: otherNode, context: .filter) { nodeResult in
                    var newNodeResult = nodeResult
                    newNodeResult.opResult = opResult.join(nodeResult.opResult)
                    return newNodeResult
                }

            let leftExpression = backend.prepare(
                leftExpression: .node(compiledNode),
                otherNode: otherNode
            )

            let filterOp = otherNodeResult.primaryNodes.elements
                .reduce(otherNodeResult.opResult.op) { op, compiledOtherNode in
                    let rightExpression = Expression.node(compiledOtherNode)
                    let finalExpression = merge(leftExpression, rightExpression)
                    return .filter(finalExpression, op)
                }

            return OpResult(
                op: filterOp,
                orderComparators: otherNodeResult.opResult.orderComparators
            )
        }

        switch filter {
        case let .equals(otherNode):
            return try compileBinaryExpression(otherNode: otherNode) {
                .equals($0, $1)
            }

        case let .lessThan(otherNode):
            return try compileBinaryExpression(otherNode: otherNode) {
                .lessThanOrEquals($0, $1)
            }

        case let .greaterThan(otherNode):
            return try compileBinaryExpression(otherNode: otherNode) {
                .greaterThanOrEquals($0, $1)
            }

        case let .conjunction(filters):
            return try filters.reduce(opResult) { opResult, filter in
                try compile(
                    filter: filter,
                    compiledNode: compiledNode,
                    opResult: opResult
                )
            }
        }
    }

    private func compile(
        node: Node,
        context: NodeContext,
        continuation: ((NodeResult) throws -> NodeResult) = { $0 }
    )
        throws -> NodeResult
    {
        if var nodeResult = nodeResults[node] {
            nodeResult.opResult = .identity
            return nodeResult
        }

        let expandedNode = backend.expand(
            node: node,
            context: context,
            env: environment
        )
        let compiledNode = backend.compile(
            nodeLabel: expandedNode.label,
            env: environment
        )

        var nodeResult = NodeResult(compiledNode: compiledNode)

        if let edge = expandedNode.edge {
            nodeResult = try compile(
                edge: edge,
                compiledNode: compiledNode
            )
        }

        nodeResult = try continuation(nodeResult)

        if let filter = node.filter {
            nodeResult.opResult = try nodeResult.primaryNodes.elements
                .reduce(nodeResult.opResult) { opResult, compiledNode in
                    try compile(
                        filter: filter,
                        compiledNode: compiledNode,
                        opResult: opResult
                    )
                }
        }

        if let order = node.order {
            let compiledOrder = compile(order: order)
            for compiledNode in nodeResult.primaryNodes.elements {
                let orderComparator = SPARQL.OrderComparator(
                    order: compiledOrder,
                    expression: .node(compiledNode)
                )
                nodeResult.opResult.orderComparators.append(orderComparator)
            }
        }

        nodeResults[node] = nodeResult

        return nodeResult
    }

    private func compile(edges: [Edge], compiledNode: SPARQL.Node, merge: OpResultMerger) throws -> NodeResult {
        let compiledEdges = try edges.map { edge in
            try compile(edge: edge, compiledNode: compiledNode)
        }
        guard let firstEdge = compiledEdges.first else {
            return NodeResult(compiledNode: compiledNode)
        }
        let remainingEdges = compiledEdges.dropFirst()
        return remainingEdges.reduce(firstEdge) {
            $1.merge($0, merge: merge)
        }
    }

    private func compile(edge: Edge, compiledNode: SPARQL.Node) throws -> NodeResult {
        switch edge {
        case let .outgoing(label, target):
            let opResult = try compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: target,
                direction: .forward
            )
            return NodeResult(
                compiledNode: compiledNode,
                opResult: opResult
            )

        case let .incoming(source, label):
            let opResult = try compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: source,
                direction: .backward
            )
            return NodeResult(
                compiledNode: compiledNode,
                opResult: opResult
            )

        case let .conjunction(edges):
            return try compile(edges: edges, compiledNode: compiledNode) {
                $0.join($1)
            }

        case let .disjunction(edges):
            return try compile(edges: edges, compiledNode: compiledNode) {
                $0.union($1)
            }

        case let .aggregate(aggregatedNode, function, distinct, groupingNode):
            return try compile(node: aggregatedNode, context: .triple) { aggregatedNodeResult in

                var aggregations: [String: Aggregation] = [:]
                for compiledAggregatedNode in aggregatedNodeResult.primaryNodes.elements {
                    guard case let .variable(variableName) = compiledNode else {
                        throw Error.aggregatedNodeNotCompiledToVariable
                    }
                    aggregations[variableName] = compile(
                        aggregateFunction: function,
                        distinct: distinct,
                        compiledNode: compiledAggregatedNode
                    )
                }

                return try compile(node: groupingNode, context: .triple) { groupingNodeResult in

                    let newSecondaryNodes =
                        aggregatedNodeResult.secondaryNodes
                            .union(groupingNodeResult.primaryNodes.elements)
                            .union(groupingNodeResult.secondaryNodes.elements)

                    let newOpResult =
                        aggregatedNodeResult.opResult
                            .join(groupingNodeResult.opResult)

                    let groupingVariables = try newSecondaryNodes.elements
                        .map { compiledNode -> String in
                            guard case let .variable(variableName) = compiledNode else {
                                throw Error.groupingNodeNotCompiledToVariable
                            }
                            return variableName
                        }

                    return NodeResult(
                        primaryNodes: [compiledNode],
                        secondaryNodes: newSecondaryNodes,
                        opResult: OpResult(
                            op: distinctProjectOrderBy(
                                op: .group(newOpResult.op, groupingVariables, aggregations),
                                variables: groupingVariables,
                                orderComparators: newOpResult.orderComparators
                            ),
                            orderComparators: []
                        )
                    )
                }
            }
        }
    }

    private func compile(
        edgeLabel: Backend.Env.Labels.Edge,
        compiledNode: SPARQL.Node,
        otherNode: Node,
        direction: EdgeDirection
    )
        throws -> OpResult
    {
        let predicate = backend.compile(
            edgeLabel: edgeLabel,
            env: environment
        )

        // TODO: verify primary and secondary nodes of result can be ignored
        let nodeResult = try compile(node: otherNode, context: .triple) { nodeResult in

            // TODO: verify secondary compiled nodes of result don't have to be considered for triples

            let triples: [Triple]

            switch direction {
            case .forward:
                triples = nodeResult.primaryNodes.elements.map { compiledOtherNode in
                    Triple(
                        subject: compiledNode,
                        predicate: predicate,
                        object: compiledOtherNode
                    )
                }

            case .backward:
                triples = nodeResult.primaryNodes.elements.map { compiledOtherNode in
                    Triple(
                        subject: compiledOtherNode,
                        predicate: predicate,
                        object: compiledNode
                    )
                }
            }

            var newNodeResult = nodeResult
            newNodeResult.opResult = OpResult(op: .bgp(triples))
                .join(nodeResult.opResult)
            return newNodeResult
        }

        return nodeResult.opResult
    }

    public func compileQuery(node: Node) throws -> SPARQL.Query {

        guard node.edge != nil else {
            throw Error.missingEdge
        }

        nodeResults = [:]

        let nodeResult = try compile(node: node, context: .triple)

        let compiledNodes = nodeResult.allNodes

        let variableNames: [String] = try compiledNodes.elements.map { compiledNode in
            guard case let .variable(variableName) = compiledNode else {
                throw Error.finalNodeNotCompiledToVariable
            }
            return variableName
        }

        let preparedOp =
            backend.prepare(
                op: nodeResult.opResult.op,
                variables: variableNames,
                env: environment
            )

        let variables = variableNames +
            backend.additionalResultVariables(
                variables: variableNames,
                env: environment
            )

        // TODO: optimize op
        return Query(op:
            distinctProjectOrderBy(
                op: preparedOp,
                variables: variables,
                orderComparators: nodeResult.opResult.orderComparators
            )
        )
    }

    private func distinctProjectOrderBy(
        op: Op,
        variables: [String],
        orderComparators: [SPARQL.OrderComparator]
    )
        -> Op
    {
        return .distinct(
            .project(
                variables,
                .orderBy(
                    op,
                    orderComparators
                )
            )
        )
    }
}
