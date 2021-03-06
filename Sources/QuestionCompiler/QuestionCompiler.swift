import QuestionParser
import Foundation


public typealias GraphNode = Node
public typealias GraphEdge = Edge
public typealias GraphFilter = Filter
public typealias GraphOrder = Order


public final class QuestionCompiler<Provider>
    where Provider: GraphProvider
{
    public enum CompilationError: Error {
        case notImplemented
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
            throw CompilationError.notImplemented
        }
    }

    public func compile(property: Property, subject: Subject) throws -> Edge {
        switch property {
        case let .named(name):
            return try provider.makeNamedPropertyEdge(
                name: name,
                subject: subject,
                env: environment
            )

        case let .withFilter(name, filter):
            let (edge, _) = try compile(filter: filter, property: name) { node, contextFactory in
                let context = try contextFactory(subject)
                return try provider.makeValuePropertyEdge(
                    name: name,
                    node: node,
                    context: context,
                    env: environment
                )
            }
            return edge

        case let .inverseWithFilter(name, filter):
            let (edge, _) = try compile(filter: filter, property: name) { node, contextFactory in
                let context = try contextFactory(subject)
                return try provider.makeInversePropertyEdge(
                    name: name,
                    node: node,
                    context: context,
                    env: environment
                )
            }
            return edge

        case let .adjectiveWithFilter(name, filter):
            let (edge, _) = try compile(filter: filter, property: name) { node, contextFactory in
                let context = try contextFactory(subject)
                return try provider.makeAdjectivePropertyEdge(
                    name: name,
                    node: node,
                    context: context,
                    env: environment
                )
            }
            return edge

        case let .and(properties):
            let edges = try properties.map {
                try compile(property: $0, subject: subject)
            }
            return Edge(conjunction: edges)

        case let .or(properties):
            let edges = try properties.map {
                try compile(property: $0, subject: subject)
            }
            return Edge(disjunction: edges)
        }
    }

    public func compile(
        filter: QuestionParser.Filter,
        property: [Token],
        edgeFactory: EdgeFactory
    )
        throws -> (edge: Edge, useDisjunction: Bool)
    {
        switch filter {
        case let .withModifier(modifier, value):
            let useDisjunction = provider.isDisjunction(
                property: property,
                filter: modifier
            )
            let edges = try compile(
                value: value,
                filter: modifier,
                property: property,
                edgeFactory: edgeFactory,
                filterIsComparative: false
            )
            return (edges, useDisjunction)

        case let .withComparativeModifier(modifier, value):
            let useDisjunction = provider.isDisjunction(
                property: property,
                filter: modifier
            )
            let edges = try compile(
                value: value,
                filter: modifier,
                property: property,
                edgeFactory: edgeFactory,
                filterIsComparative: true
            )
            return (edges, useDisjunction)

        case let .plain(value):
            let useDisjunction = provider.isDisjunction(
                property: property,
                filter: []
            )
            let edges = try compile(
                value: value,
                filter: [],
                property: property,
                edgeFactory: edgeFactory,
                filterIsComparative: false
            )
             return (edges, useDisjunction)

        case let .and(filters):
            let result = try filters.map {
                try compile(
                    filter: $0,
                    property: property,
                    edgeFactory: edgeFactory
                )
            }

            let (edges, useDisjunctions): ([Edge], [Bool]) =
                result.map { ($0.0, $0.1) }.unzip()
            if useDisjunctions.allSatisfy({ $0 }) {
                return (
                    edge: Edge(disjunction: edges),
                    useDisjunction: true
                )
            } else {
                return (
                    edge: Edge(conjunction: edges),
                    useDisjunction: false
                )
            }

        case let .or(filters):
            let result = try filters.map {
                try compile(
                    filter: $0,
                    property: property,
                    edgeFactory: edgeFactory
                )
            }
            let (edges, useDisjunctions): ([Edge], [Bool]) =
                result.map { ($0.0, $0.1) }.unzip()
            return (
                edge: Edge(disjunction: edges),
                useDisjunction: useDisjunctions.allSatisfy({ $0 })
            )
        }
    }

    public func compile(
        value: Value,
        filter: [Token],
        property: [Token],
        edgeFactory: EdgeFactory,
        filterIsComparative: Bool
    )
        throws -> Edge
    {
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
                    valueIsNumber: false,
                    filterIsComparative: filterIsComparative
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
                    valueIsNumber: true,
                    filterIsComparative: filterIsComparative
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
                    valueIsNumber: true,
                    filterIsComparative: filterIsComparative
                )
            }

        case let .or(values):
            let edges = try values.map {
                try compile(
                    value: $0,
                    filter: filter,
                    property: property,
                    edgeFactory: edgeFactory,
                    filterIsComparative: filterIsComparative
                )
            }
            return Edge(disjunction: edges)

        case let .and(values):
            let edges = try values.map {
                try compile(
                    value: $0,
                    filter: filter,
                    property: property,
                    edgeFactory: edgeFactory,
                    filterIsComparative: filterIsComparative
                )
            }
            if provider.isDisjunction(property: property, filter: filter) {
                return Edge(disjunction: edges)
            } else {
                return Edge(conjunction: edges)
            }

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
                property: property,
                edgeFactory: secondEdgeFactory,
                filterIsComparative: filterIsComparative
            )
            let node = environment.newNode().and(edge)
            return try edgeFactory(node) { subject in
                EdgeContext(
                    subject: subject,
                    filter: filter,
                    value: name,
                    unit: [],
                    valueIsNumber: false,
                    filterIsComparative: filterIsComparative
                )
            }

        case .relationship:
            throw CompilationError.notImplemented
        }
    }
}


extension QuestionCompiler.CompilationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "not implemented"
        }
    }
}
