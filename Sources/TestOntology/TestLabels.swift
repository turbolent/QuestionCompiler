
import QuestionCompiler

public struct TestLabels: Labels {
    public typealias Node = TestNodeLabel
    public typealias Edge = TestEdgeLabel

    private init() {}
}


public enum TestNodeLabel: NodeLabel {
    case variable(Int)
    case item(String)
    case string(String)
    case number(Double, unit: String?)
}

extension TestNodeLabel: Encodable {

    private enum CodingKeys: CodingKey {
        case type
        case subtype
        case name
        case id
        case value
        case url
    }

    private enum PrimaryType: String, Encodable {
        case item
        case variable
        case value
    }

    private enum Subtype: String, Encodable {
        case string
        case number
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .item(name):
            try container.encode(PrimaryType.item, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode("http://example.org/item/\(name)", forKey: .url)

        case let .variable(id):
            try container.encode(PrimaryType.variable, forKey: .type)
            try container.encode(id, forKey: .id)

        case let .string(value):
            try container.encode(PrimaryType.value, forKey: .type)
            try container.encode(Subtype.string, forKey: .subtype)
            try container.encode(value, forKey: .value)

        case let .number(value, _):
            try container.encode(PrimaryType.value, forKey: .type)
            try container.encode(Subtype.number, forKey: .subtype)
            try container.encode(value, forKey: .value)
        }
    }
}

public struct TestClasses {
    public static let person = TestNode(label: .item("person"))
    public static let movie = TestNode(label: .item("movie"))
    public static let mountain = TestNode(label: .item("mountain"))
    public static let author = TestNode(label: .item("author"))
    public static let city = TestNode(label: .item("city"))
    public static let president = TestNode(label: .item("president"))
    public static let album = TestNode(label: .item("album"))
    public static let woman = TestNode(label: .item("woman"))
    public static let planet = TestNode(label: .item("planet"))

    private init() {}
}


public struct TestEdgeLabel: EdgeLabel {
    public let name: String

    public static let isA = TestEdgeLabel(name: "isA")
    public static let hasName = TestEdgeLabel(name: "hasName")
    public static let hasCastMember = TestEdgeLabel(name: "hasCastMember")
    public static let hasSpouse = TestEdgeLabel(name: "hasSpouse")
    public static let hasElevation = TestEdgeLabel(name: "hasElevation")
    public static let hasPlaceOfBirth = TestEdgeLabel(name: "hasPlaceOfBirth")
    public static let hasPlaceOfDeath = TestEdgeLabel(name: "hasPlaceOfDeath")
    public static let hasChild = TestEdgeLabel(name: "hasChild")
    public static let hasGrandChild = TestEdgeLabel(name: "hasGrandChild")
    public static let isLocatedIn = TestEdgeLabel(name: "isLocatedIn")
    public static let hasAuthor = TestEdgeLabel(name: "hasAuthor")
    public static let hasDateOfBirth = TestEdgeLabel(name: "hasDateOfBirth")
    public static let attends = TestEdgeLabel(name: "attends")
    public static let hasPerformer = TestEdgeLabel(name: "hasPerformer")
    public static let hasPopulation = TestEdgeLabel(name: "hasPopulation")
    public static let discovered = TestEdgeLabel(name: "discovered")
}

extension TestEdgeLabel: Encodable {

    private enum CodingKeys: CodingKey {
        case type
        case name
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("property", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode("http://example.org/property/\(name)", forKey: .url)
    }
}
