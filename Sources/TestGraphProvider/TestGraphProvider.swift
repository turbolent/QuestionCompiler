
import QuestionCompiler
import QuestionParser

public final class TestGraphProvider: GraphProvider {
    public typealias Labels = TestLabels
    public typealias Env = TestEnvironment

    public init() {}

    public func makePersonEdge(
        env _: Env
    ) throws -> TestGraphProvider.Edge {
        return .outgoing(.isA, TestClasses.person)
    }

    public func makeNamedPropertyEdge(
        name: [Token],
        subject _: Subject,
        env: Env
    ) throws -> TestGraphProvider.Edge {
        let lemmas = name.map { $0.lemma }
        switch lemmas {
        case ["write"]:
            let node = env.newNode()
            return .incoming(node, .hasAuthor)
        default:
            fatalError("not implemented")
        }
    }

    public func makeInversePropertyEdge(
        name: [Token],
        node: TestGraphProvider.Node,
        context _: EdgeContext,
        env _: Env
    ) throws -> TestGraphProvider.Edge {
        let lemmas = name.map { $0.lemma }
        switch lemmas {
        case ["do", "marry"]:
            return .outgoing(.hasSpouse, node)
        case ["do", "write"]:
            return .outgoing(.hasAuthor, node)
        default:
            fatalError("not implemented")
        }
    }

    public func makeAdjectivePropertyEdge(
        name: [Token],
        node: TestGraphProvider.Node,
        context: EdgeContext,
        env: Env
    ) throws -> TestGraphProvider.Edge {
        let lemmas = (name + context.filter)
            .map { $0.lemma }
        switch lemmas {
        case ["be", "high"]:
            return .outgoing(.hasElevation, node)
        case ["be", "old", "more", "than"] where context.valueIsNumber:
            let age = env.newNode()
                .filtered(.greaterThan(node))
            return .outgoing(.hasAge, age)
        default:
            fatalError("not implemented")
        }
    }

    public func makeValuePropertyEdge(
        name: [Token],
        node: TestGraphProvider.Node,
        context: EdgeContext,
        env: Env
    ) throws -> TestGraphProvider.Edge {
        let lemmas = (name + context.filter)
            .map { $0.lemma }
        switch lemmas {
        case ["act", "in"]:
            return .incoming(node, .hasCastMember)
        case ["star"]:
            return .outgoing(.hasCastMember, node)
        case ["be", "bear", "in"]:
            return .outgoing(.hasPlaceOfBirth, node)
        case ["die", "in"]:
            return .outgoing(.hasPlaceOfDeath, node)
        case ["be", "bear", "before"]:
            let birthDate = env
                .newNode()
                .filtered(.lessThan(node))
            return .outgoing(.hasDateOfBirth, birthDate)
        case ["attend"]:
            return .outgoing(.attends, node)
        case ["of"], ["in"]:
            if case let .named(subjectName) = context.subject {
                return getRelationshipEdge(name: subjectName, node: node)
            }
            break
        case ["be", "old", "than"]:
            let otherBirthDate = env
                .newNode()
                .incoming(node, .hasDateOfBirth)
            let birthDate = env
                .newNode()
                .filtered(.lessThan(otherBirthDate))
            return .outgoing(.hasDateOfBirth, birthDate)
        default:
            break
        }

        fatalError("not implemented")
    }

    public func makeRelationshipEdge(
        name: [Token],
        node: TestGraphProvider.Node,
        env _: Env
    ) throws -> TestGraphProvider.Edge {
        let relationshipEdge = getRelationshipEdge(name: name, node: node)

        let lemmas = name.filter { $0.tag != "DT" }.map { $0.lemma }
        switch lemmas {
        case ["city"]:
            return relationshipEdge
                & .outgoing(.isA, TestClasses.city)
        case ["album"]:
            return relationshipEdge
                & .outgoing(.isA, TestClasses.album)
        case ["daughter"]:
            return relationshipEdge
                & .outgoing(.isA, TestClasses.woman)
        default:
            return relationshipEdge
        }
    }

    private func getRelationshipEdge(
        name: [Token],
        node: TestGraphProvider.Node
    )
        -> TestGraphProvider.Edge
    {
        let lemmas = name.filter { $0.tag != "DT" }.map { $0.lemma }
        switch lemmas {
        case ["child"]:
            return .incoming(node, .hasChild)
        case ["grandchild"]:
            return .incoming(node, .hasGrandChild)
        case ["city"]:
            return .outgoing(.isLocatedIn, node)
        case ["album"]:
            return .outgoing(.hasPerformer, node)
        case ["daughter"]:
            return.incoming(node, .hasChild)
        default:
            fatalError("not implemented")
        }
    }

    private func getClass(_ name: [Token]) -> TestNode? {
        guard name.count == 1 else {
            return nil
        }

        switch name.first?.lemma {
        case "album":
            return TestClasses.album
        case "movie":
            return TestClasses.movie
        case "mountain":
            return TestClasses.mountain
        case "author":
            return TestClasses.author
        case "president":
            return TestClasses.president
        case "city":
            return TestClasses.city
        default:
            return nil
        }
    }

    public func makeValueNode(
        name: [Token],
        filter _: [Token],
        env: Env
    ) throws -> TestGraphProvider.Node {
        if let `class` = getClass(name) {
            return env.newNode()
                .outgoing(.isA, `class`)
        }

        let nameString = name
            .map { $0.word }
            .joined(separator: " ")
        let nameLabel = TestNodeLabel.string(nameString)
        return env.newNode()
            .outgoing(.hasName, Node(label: nameLabel))
    }

    public func makeNumberNode(
        number: [Token],
        unit: [Token],
        filter _: [Token],
        env _: Env
    ) throws -> TestGraphProvider.Node {
        let numberString = number.map { $0.lemma }.joined(separator: " ")
        let unitString = unit.isEmpty
            ? nil
            : unit.map { $0.lemma }.joined(separator: " ")
        return Node(label: .number(Double(numberString)!, unit: unitString))
    }

    public func isDisjunction(property: [Token], filter: [Token]) -> Bool {
        return property.isEmpty && filter.allSatisfy { $0.tag == "IN" }
    }
}
