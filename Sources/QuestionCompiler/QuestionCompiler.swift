
import QuestionParser

public typealias GraphNode = Node
public typealias GraphEdge = Edge
public typealias GraphFilter = Filter

public final class QuestionCompiler<Provider>
    where Provider: GraphProvider
{
    public enum CompilationError: Error {
        case unimplemented
    }

    public typealias Labels = Provider.Env.Labels
    public typealias Node = GraphNode<Labels>
    public typealias Edge = GraphEdge<Labels>

    public typealias NodeFactory = (Node, [Token]) throws -> Node
    public typealias EdgeContextFactory = (Subject) throws -> EdgeContext
    public typealias EdgeFactory = (Node, EdgeContextFactory) throws -> Edge

    public let environment: Provider.Env
    public let provider: Provider

    public init(environment: Provider.Env, provider: Provider) {
        self.environment = environment
        self.provider = provider
    }

    public func compile(question: ListQuestion) throws -> [Node] {
        switch question {
        case let .person(property):
            let node = environment.newNode()
                .and(try provider.makePersonEdge(env: environment))
                .and(try compile(property: property, subject: .person))
            return [node]

        case let .thing(property):
            let node = environment.newNode()
                .and(try compile(property: property, subject: .thing))
            return [node]

        case let .other(query):
            return try compile(query: query) { node, _ in
                node
            }
        }
    }

    public func compile(query: Query, nodeFactory: NodeFactory) throws -> [Node] {
        switch query {
        case let .withProperty(nestedQuery, property):
            return try compile(query: nestedQuery) { node, name in
                let edge = try compile(property: property, subject: .named(name))
                return node.and(edge)
            }

        case let .named(name):
            let node = try provider.makeValueNode(
                name: name,
                filter: [],
                env: environment
            )
            let resultNode = try nodeFactory(node, name)
            return [resultNode]

        case let .and(queries):
            return try queries.flatMap {
                try compile(query: $0, nodeFactory: nodeFactory)
            }

        case let .relationship(first, second, _):
            let nodes = try compile(query: second, nodeFactory: nodeFactory)
            return try compileRelationshipSubquery(query: first, nodes: nodes)
        }
    }

    public func compileRelationshipSubquery(query: Query, nodes: [Node]) throws -> [Node] {
        switch query {
        case let .named(name):
            return try nodes.map { node in
                let edge = try provider.makeRelationshipEdge(
                    name: name,
                    node: node,
                    env: environment
                )
                return environment.newNode().and(edge)
            }

        case let .and(queries):
            return try queries.flatMap {
                try compileRelationshipSubquery(query: $0, nodes: nodes)
            }

        case let .relationship(first, second, _):
            let secondNodes =
                try compileRelationshipSubquery(query: second, nodes: nodes)
            return try compileRelationshipSubquery(
                query: first,
                nodes: secondNodes
            )

        case .withProperty:
            throw CompilationError.unimplemented
        }
    }

    public func compile(property: Property, subject: Subject) throws -> Edge {
        switch property {
        case let .named(name):
            return try provider.makeNamedPropertyEdge(
                name: name,
                node: environment.newNode(),
                subject: subject,
                env: environment
            )

        case let .withFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                let context = try contextFactory(subject)
                if case .withComparativeModifier = filter {
                    return try provider.makeComparativePropertyEdge(
                        name: name,
                        node: node,
                        context: context,
                        env: environment
                    )
                }

                return try provider.makeValuePropertyEdge(
                    name: name,
                    node: node,
                    context: context,
                    env: environment
                )
            }

        case let .inverseWithFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                try provider.makeInversePropertyEdge(
                    name: name,
                    node: node,
                    context: contextFactory(subject),
                    env: environment
                )
            }

        case let .adjectiveWithFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                try provider.makeAdjectivePropertyEdge(
                    name: name,
                    node: node,
                    context: contextFactory(subject),
                    env: environment
                )
            }

        case let .and(properties):
            let edges = try properties.map {
                try compile(property: $0, subject: subject)
            }
            return .conjunction(edges)

        case let .or(properties):
            let edges = try properties.map {
                try compile(property: $0, subject: subject)
            }
            return .disjunction(edges)
        }
    }

    public func compile(filter: QuestionParser.Filter, edgeFactory: EdgeFactory) throws -> Edge {
        switch filter {
        case let .withModifier(modifier, value):
            return try compile(
                value: value,
                filter: modifier,
                edgeFactory: edgeFactory
            )

        case let .withComparativeModifier(modifier, value):
            return try compile(
                value: value,
                filter: modifier,
                edgeFactory: edgeFactory
            )

        case let .plain(value):
            return try compile(
                value: value,
                filter: [],
                edgeFactory: edgeFactory
            )

        case let .and(filters):
            let filters = try filters.map {
                try compile(filter: $0, edgeFactory: edgeFactory)
            }
            return .conjunction(filters)

        case let .or(filters):
            let filters = try filters.map {
                try compile(filter: $0, edgeFactory: edgeFactory)
            }
            return .disjunction(filters)
        }
    }

    public func compile(value: Value, filter: [Token], edgeFactory: EdgeFactory) throws -> Edge {
        switch value {
        case let .named(name):
            let node = try provider.makeValueNode(
                name: name,
                filter: filter,
                env: environment
            )
            return try edgeFactory(node) { subject in
                EdgeContext(
                    subject: subject,
                    filter: filter,
                    value: name,
                    unit: [],
                    valueIsNumber: false
                )
            }

        case let .number(number):
            let node = try provider.makeNumberNode(
                number: number,
                unit: [],
                filter: filter,
                env: environment
            )
            return try edgeFactory(node) { subject in
                EdgeContext(
                    subject: subject,
                    filter: filter,
                    value: number,
                    unit: [],
                    valueIsNumber: true
                )
            }

        case let .numberWithUnit(number, unit):
            let node = try provider.makeNumberNode(
                number: number,
                unit: unit,
                filter: filter,
                env: environment
            )
            return try edgeFactory(node) { subject in
                EdgeContext(
                    subject: subject,
                    filter: filter,
                    value: number,
                    unit: unit,
                    valueIsNumber: true
                )
            }

        case let .or(values):
            let edges = try values.map {
                try compile(value: $0, filter: filter, edgeFactory: edgeFactory)
            }
            return .disjunction(edges)

        case let .and(values):
            let edges = try values.map {
                try compile(value: $0, filter: filter, edgeFactory: edgeFactory)
            }
            return .conjunction(edges)

        case let .relationship(.named(name), second, _):
            let secondEdgeFactory: EdgeFactory = { node, _ in
                try self.provider.makeRelationshipEdge(
                    name: name,
                    node: node,
                    env: self.environment
                )
            }
            let edge = try compile(
                value: second,
                filter: filter,
                edgeFactory: secondEdgeFactory
            )
            let node = environment.newNode().and(edge)
            return try edgeFactory(node) { subject in
                EdgeContext(
                    subject: subject,
                    filter: filter,
                    value: name,
                    unit: [],
                    valueIsNumber: false
                )
            }

        case .relationship:
            throw CompilationError.unimplemented
        }
    }
}
