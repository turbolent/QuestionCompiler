
import SPARQL

public final class SPARQLGraphCompiler<N, E, Env, Backend>
    where Backend: SPARQLBackend,
        Backend.Env == Env,
        Backend.N == N,
        Backend.E == E
{
    public typealias Node = GraphNode<N, E>
    public typealias Edge = GraphEdge<E, N>
    public typealias Filter = GraphFilter<N, E>

    public enum Error: Swift.Error {
        case missingEdge
        case finalNodeNotCompiledToVariable
        case aggregatedNodeNotCompiledToVariable
        case groupingNodeNotCompiledToVariable
    }

    private typealias Result = (
        primaryCompiledNodes: Set<SPARQL.Node>,
        secondaryCompiledNodes: Set<SPARQL.Node>,
        opResult: OpResult
    )

    private typealias OpResultMerger =
        (OpResult, OpResult) -> OpResult

    private typealias ExpressionMerger =
        (SPARQL.Expression, SPARQL.Expression) -> SPARQL.Expression

    private let environment: Env
    private let backend: Backend

    public init(environment: Env, backend: Backend) {
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

    private func compile(order: Order) -> SPARQL.Order {
        switch order {
        case .ascending:
            return .ascending
        case .descending:
            return .descending
        }
    }

    private func compile(filter: Filter, compiledNode: SPARQL.Node, opResult: OpResult) throws -> OpResult {

        func compileBinaryExpression(otherNode: Node, merge: ExpressionMerger) throws -> OpResult {

            // TODO: verify secondary nodes can be ignored in closure and result
            let (compiledOtherNodes, _, otherOpResult) =
                try compile(node: otherNode, context: .filter) { result in
                    (
                        result.primaryCompiledNodes,
                        result.secondaryCompiledNodes,
                        opResult.join(result.opResult)
                    )
                }

            let leftExpression = backend.prepare(
                leftExpression: .node(compiledNode),
                otherNode: otherNode
            )

            let filterOp = compiledOtherNodes.reduce(otherOpResult.op) { op, compiledOtherNode in
                let rightExpression = Expression.node(compiledOtherNode)
                let finalExpression = merge(leftExpression, rightExpression)
                return .filter(finalExpression, op)
            }

            return OpResult(
                op: filterOp,
                orderComparators: otherOpResult.orderComparators
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
        context: NodeCompilationContext,
        continuation: (Result) throws -> Result
    )
        throws -> Result
    {
        let expandedNode = backend.expand(
            node: node,
            context: context,
            env: environment
        )
        let compiledNode = backend.compile(
            nodeLabel: expandedNode.label,
            env: environment
        )

        var result: Result = ([compiledNode], [], .identity)

        if let edge = expandedNode.edge {
            result = try compile(
                edge: edge,
                compiledNode: compiledNode
            )
        }

        result = try continuation(result)

        if let filter = node.filter {
            var newOpResult = result.opResult
            for compiledNode in result.primaryCompiledNodes {
                newOpResult = try compile(
                    filter: filter,
                    compiledNode: compiledNode,
                    opResult: newOpResult
                )
            }
            result = (
                result.primaryCompiledNodes,
                result.secondaryCompiledNodes,
                newOpResult
            )
        }

        if let order = node.order {
            let compiledOrder = compile(order: order)
            for compiledNode in result.primaryCompiledNodes {
                let orderComparator = SPARQL.OrderComparator(
                    order: compiledOrder,
                    expression: .node(compiledNode)
                )
                result.opResult.orderComparators.append(orderComparator)
            }
        }

        return result
    }

    private func compile(edges: [Edge], compiledNode: SPARQL.Node, merge: OpResultMerger) throws -> Result {
        let compiledEdges = try edges.map { edge in
            try compile(edge: edge, compiledNode: compiledNode)
        }
        guard let firstEdge = compiledEdges.first else {
            return ([compiledNode], [], .identity)
        }
        let remainingEdges = compiledEdges.dropFirst()
        return remainingEdges.reduce(firstEdge) { result, next in
            let (resultPrimaryNodes, resultSecondaryNodes, resultOpResult) = result
            let (nextPrimaryNodes, nextSecondaryNodes, nextOpResult) = next
            return (
                resultPrimaryNodes.union(nextPrimaryNodes),
                resultSecondaryNodes.union(nextSecondaryNodes),
                merge(resultOpResult, nextOpResult)
            )
        }
    }

    private func compile(edge: Edge, compiledNode: SPARQL.Node) throws -> Result {
        switch edge {
        case let .outgoing(label, target):
            let opResult = try compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: target,
                direction: .forward
            )
            return ([compiledNode], [], opResult)

        case let .incoming(source, label):
            let opResult = try compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: source,
                direction: .backward
            )
            return ([compiledNode], [], opResult)

        case let .conjunction(edges):
            return try compile(edges: edges, compiledNode: compiledNode) {
                $0.join($1)
            }

        case let .disjunction(edges):
            return try compile(edges: edges, compiledNode: compiledNode) {
                $0.union($1)
            }

        case let .aggregate(aggregatedNode, function, distinct, groupingNode):
            return try compile(node: aggregatedNode, context: .triple) { aggregatedResult in

                var aggregations: [String: Aggregation] = [:]
                for compiledAggregatedNode in aggregatedResult.primaryCompiledNodes {
                    guard case let .variable(variableName) = compiledNode else {
                        throw Error.aggregatedNodeNotCompiledToVariable
                    }
                    aggregations[variableName] = compile(
                        aggregateFunction: function,
                        distinct: distinct,
                        compiledNode: compiledAggregatedNode
                    )
                }

                return try compile(node: groupingNode, context: .triple) { groupingResult in

                    let newSecondaryNodes =
                        aggregatedResult.secondaryCompiledNodes
                            .union(groupingResult.primaryCompiledNodes)
                            .union(groupingResult.secondaryCompiledNodes)

                    let newOpResult = aggregatedResult.opResult.join(groupingResult.opResult)

                    let groupingVariables = try newSecondaryNodes.map { compiledNode -> String in
                        guard case let .variable(variableName) = compiledNode else {
                            throw Error.groupingNodeNotCompiledToVariable
                        }
                        return variableName
                    }

                    return (
                        [compiledNode],
                        newSecondaryNodes,
                        OpResult(
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
        edgeLabel: E,
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

        // TODO: verify second argument in closure can be ignored
        let (_, _, opResult) = try compile(node: otherNode, context: .triple) { result in

            // TODO: verify secondary compiled nodes of result don't have to be considered for triples

            let triples: [Triple]

            switch direction {
            case .forward:
                triples = result.primaryCompiledNodes.map { compiledOtherNode in
                    Triple(
                        subject: compiledNode,
                        predicate: predicate,
                        object: compiledOtherNode
                    )
                }

            case .backward:
                triples = result.primaryCompiledNodes.map { compiledOtherNode in
                    Triple(
                        subject: compiledOtherNode,
                        predicate: predicate,
                        object: compiledNode
                    )
                }
            }

            let opResult = OpResult(
                op: .bgp(triples),
                orderComparators: []
            )

            return (
                result.primaryCompiledNodes,
                result.secondaryCompiledNodes,
                opResult.join(result.opResult)
            )
        }

        return opResult
    }

    public func compileQuery(node: Node) throws -> SPARQL.Query {

        guard node.edge != nil else {
            throw Error.missingEdge
        }

        let (compiledPrimaryNodes, compiledSecondaryNodes, opResult) =
            try compile(node: node, context: .triple) { $0 }

        let compiledNodes = compiledPrimaryNodes.union(compiledSecondaryNodes)

        let variableNames: [String] = try compiledNodes.map { compiledNode in
            guard case let .variable(variableName) = compiledNode else {
                throw Error.finalNodeNotCompiledToVariable
            }
            return variableName
        }

        let preparedOp =
            backend.prepare(
                op: opResult.op,
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
                orderComparators: opResult.orderComparators
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
