
import QuestionCompiler

public enum TestNodeLabel: NodeLabel {
    case variable(Int)
    case id(String)
    case string(String)
    case number(Double, unit: String?)
}

extension TestNodeLabel: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError("not implemented")
    }
}

public struct TestClasses {
    public static let person = TestNode(label: .id("person"))
    public static let movie = TestNode(label: .id("movie"))
    public static let mountain = TestNode(label: .id("mountain"))
    public static let author = TestNode(label: .id("author"))
    public static let city = TestNode(label: .id("city"))
    public static let president = TestNode(label: .id("president"))
    public static let album = TestNode(label: .id("album"))
    public static let woman = TestNode(label: .id("woman"))
    public static let planet = TestNode(label: .id("planet"))

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
