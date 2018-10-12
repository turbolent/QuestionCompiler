
enum TestNodeLabel: Hashable {
    case variable(Int)
    case id(String)
    case string(String)
    case number(Double, unit: String?)
}

struct TestClasses {
    static let person = TestNode(label: .id("person"))
    static let movie = TestNode(label: .id("movie"))
    static let mountain = TestNode(label: .id("mountain"))
    static let author = TestNode(label: .id("author"))
    static let city = TestNode(label: .id("city"))
    static let president = TestNode(label: .id("president"))
    static let album = TestNode(label: .id("album"))
    static let woman = TestNode(label: .id("woman"))

    private init() {}
}

struct TestEdgeLabel: Hashable {
    let name: String

    static let isA = TestEdgeLabel(name: "isA")
    static let hasName = TestEdgeLabel(name: "hasName")
    static let hasCastMember = TestEdgeLabel(name: "hasCastMember")
    static let hasSpouse = TestEdgeLabel(name: "hasSpouse")
    static let hasElevation = TestEdgeLabel(name: "hasElevation")
    static let hasPlaceOfBirth = TestEdgeLabel(name: "hasPlaceOfBirth")
    static let hasPlaceOfDeath = TestEdgeLabel(name: "hasPlaceOfDeath")
    static let hasChild = TestEdgeLabel(name: "hasChild")
    static let hasGrandChild = TestEdgeLabel(name: "hasGrandChild")
    static let isLocatedIn = TestEdgeLabel(name: "isLocatedIn")
    static let hasAuthor = TestEdgeLabel(name: "hasAuthor")
    static let hasDateOfBirth = TestEdgeLabel(name: "hasDateOfBirth")
    static let attends = TestEdgeLabel(name: "attends")
    static let hasPerformer = TestEdgeLabel(name: "hasPerformer")
}
