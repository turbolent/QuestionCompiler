
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

    public typealias OpResultMerger =
        (OpResult, OpResult) -> OpResult

    public typealias ExpressionMerger =
        (SPARQL.Expression, SPARQL.Expression) -> SPARQL.Expression

    public let environment: Env
    public let backend: Backend

    public init(environment: Env, backend: Backend) {
        self.environment = environment
        self.backend = backend
    }

    public func compile(order: Order) -> SPARQL.Order {
        switch order {
        case .ascending:
            return .ascending
        case .descending:
            return .descending
        }
    }

    public func compile(filter: Filter, compiledNode: SPARQL.Node, opResult: OpResult) -> OpResult {

        func compileBinaryExpression(otherNode: Node, merge: ExpressionMerger) -> OpResult {

            let (compiledOtherNode, otherOpResult) =
                compile(node: otherNode, context: .filter) {
                    (compiledOtherNode, otherOpResult) in

                    opResult.join(otherOpResult)
                }

            let leftExpression = backend.prepare(
                leftExpression: .node(compiledNode),
                otherNode: otherNode
            )
            let rightExpression = Expression.node(compiledOtherNode)
            let finalExpression = merge(leftExpression, rightExpression)
            let filterOp = Op.filter(finalExpression, otherOpResult.op)

            return OpResult(
                op: filterOp,
                orderComparators: otherOpResult.orderComparators
            )
        }

        switch filter {
        case let .equals(otherNode):
            return compileBinaryExpression(otherNode: otherNode) {
                .equals($0, $1)
            }

        case let .lessThan(otherNode):
            return compileBinaryExpression(otherNode: otherNode) {
                .lessThan($0, $1)
            }

        case let .greaterThan(otherNode):
            return compileBinaryExpression(otherNode: otherNode) {
                .greaterThan($0, $1)
            }

        case let .conjunction(filters):
            return filters.reduce(opResult) {
                compile(
                    filter: $1,
                    compiledNode: compiledNode,
                    opResult: $0
                )
            }
        }
    }

    public func compile(
        node: Node,
        context: NodeCompilationContext,
        continuation: (SPARQL.Node, OpResult) -> OpResult
    )
        -> (SPARQL.Node, OpResult)
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
        let edgeOpResult = expandedNode.edge.map {
            compile(edge: $0, compiledNode: compiledNode)
        }

        var opResult = continuation(
            compiledNode,
            edgeOpResult ?? .identity
        )

        if let filter = node.filter {
            opResult = compile(
                filter: filter,
                compiledNode: compiledNode,
                opResult: opResult
            )
        }

        return (compiledNode, opResult)
    }

    func compile(edges: [Edge], compiledNode: SPARQL.Node, merge: OpResultMerger) -> OpResult {
        let compiledEdges = edges.map { edge in
            compile(edge: edge, compiledNode: compiledNode)
        }
        guard let firstEdge = compiledEdges.first else {
            return .identity
        }
        let remainingEdges = compiledEdges.dropFirst()
        return remainingEdges.reduce(firstEdge, merge)
    }

    func compile(edge: Edge, compiledNode: SPARQL.Node) -> OpResult {
        switch edge {
        case let .outgoing(label, target):
            return compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: target,
                direction: .forward
            )

        case let .incoming(source, label):
            return compile(
                edgeLabel: label,
                compiledNode: compiledNode,
                otherNode: source,
                direction: .backward
            )

        case let .conjunction(edges):
            return compile(edges: edges, compiledNode: compiledNode) {
                $0.join($1)
            }

        case let .disjunction(edges):
            return compile(edges: edges, compiledNode: compiledNode) {
                $0.union($1)
            }
        }
    }

    public func compile(
        edgeLabel: E,
        compiledNode: SPARQL.Node,
        otherNode: Node,
        direction: EdgeDirection
    )
        -> OpResult
    {
        let predicate = backend.compile(
            edgeLabel: edgeLabel,
            env: environment
        )

        let (_, opResult) = compile(node: otherNode, context: .triple) {
            (compiledOtherNode, otherOpResult) in

            let triple: Triple
            switch direction {
            case .forward:
                triple = Triple(
                    subject: compiledNode,
                    predicate: predicate,
                    object: compiledOtherNode
                )

            case .backward:
                triple = Triple(
                    subject: compiledOtherNode,
                    predicate: predicate,
                    object: compiledNode
                )
            }

            let result = OpResult(
                op: .bgp([triple]),
                orderComparators: []
            )

            return result.join(otherOpResult)
        }

        return opResult
    }

    public func compileQuery(node: Node) -> SPARQL.Query {

        guard node.edge != nil else {
            // TODO:
            fatalError("root node needs to have edges")
        }

        let (compiledNode, opResult) =
            compile(node: node, context: .triple) { (_, result) in result }

        guard case let .variable(variableName) = compiledNode else {
            // TODO:
            fatalError("root node needs to be compiled to a variable")
        }

        let preparedOp = backend.prepare(
            op: opResult.op,
            variable: variableName,
            env: environment
        )
        let variables = [variableName] +
            backend.additionalResultVariables(
                variable: variableName,
                env: environment
            )

        // TODO: optimize op
        return Query(op:
            .distinct(
                .project(
                    variables,
                    .orderBy(
                        preparedOp,
                        opResult.orderComparators
                    )
                )
            )
        )
    }
}
