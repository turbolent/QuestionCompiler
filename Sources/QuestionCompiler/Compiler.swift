
import QuestionParser

public final class Compiler<N, E, Env, Ont>
    where Ont: Ontology,
        Ont.Env == Env,
        Ont.N == N,
        Ont.E == E
{
    public enum CompilationError: Error {
        case unimplemented
    }

    public typealias Node = QuestionCompiler.Node<N, E>
    public typealias Edge = QuestionCompiler.Edge<E, N>

    public typealias NodeFactory = (Node, [Token]) throws -> Node
    public typealias EdgeContextFactory = (Subject) throws-> EdgeContext
    public typealias EdgeFactory = (Node, EdgeContextFactory) throws-> Edge

    public let environment: Env
    public let ontology: Ont

    public init(environment: Env, ontology: Ont) {
        self.environment = environment
        self.ontology = ontology
    }

    public func compile(question: ListQuestion) throws -> [Node] {
        switch question {
        case .person(let property):
            let node = environment.newNode()
                .and(try ontology.makePersonEdge(env: environment))
                .and(try compile(property: property, subject: .person))
            return [node]

        case .thing(let property):
            let node = environment.newNode()
                .and(try compile(property: property, subject: .thing))
            return [node]

        case .other(let query):
            return try compile(query: query) { node, _ in
                node
            }
        }
    }

    public func compile(query: Query, nodeFactory: NodeFactory) throws -> [Node] {
        switch query  {
        case let .withProperty(nestedQuery, property):
            return try compile(query: nestedQuery) { node, name in
                let edge = try compile(property: property, subject: .named(name))
                return node.and(edge)
            }

        case let .named(name):
            let node = try ontology.makeValueNode(
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
                let edge = try ontology.makeRelationshipEdge(
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
            return try ontology.makeNamedPropertyEdge(
                name: name,
                node: environment.newNode(),
                subject: subject,
                env: environment
            )

        case let .withFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                let context = try contextFactory(subject)
                if case .withComparativeModifier = filter {
                    return try ontology.makeComparativePropertyEdge(
                        name: name,
                        node: node,
                        context: context,
                        env: environment
                    )
                }

                return try ontology.makeValuePropertyEdge(
                    name: name,
                    node: node,
                    context: context,
                    env: environment
                )
            }

        case let .inverseWithFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                try ontology.makeInversePropertyEdge(
                    name: name,
                    node: node,
                    context: contextFactory(subject),
                    env: environment
                )
            }

        case let .adjectiveWithFilter(name, filter):
            return try compile(filter: filter) { node, contextFactory in
                try ontology.makeAdjectivePropertyEdge(
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
            return .conjunction(Set(edges))

        case let .or(properties):
            let edges = try properties.map {
                try compile(property: $0, subject: subject)
            }
            return .disjunction(Set(edges))
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
            return .conjunction(Set(filters))

        case let .or(filters):
            let filters = try filters.map {
                try compile(filter: $0, edgeFactory: edgeFactory)
            }
            return .disjunction(Set(filters))
        }
    }

    public func compile(value: Value, filter: [Token], edgeFactory: EdgeFactory) throws -> Edge {
        switch value {
        case let .named(name):
            let node = try ontology.makeValueNode(
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
            let node = try ontology.makeNumberNode(
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
            let node = try ontology.makeNumberNode(
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
            return .disjunction(Set(edges))

        case let .and(values):
            let edges = try values.map {
                try compile(value: $0, filter: filter, edgeFactory: edgeFactory)
            }
            return .conjunction(Set(edges))

        case let .relationship(.named(name), second, _):
            let secondEdgeFactory: EdgeFactory = { node, _ in
                try self.ontology.makeRelationshipEdge(
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

        case .relationship(_, _, _):
           throw CompilationError.unimplemented
        }
    }
}
