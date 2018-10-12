
import QuestionParser
import QuestionCompiler


typealias TestNode = Node<TestNodeLabel, TestEdgeLabel>


class TestOntology: Ontology {
    typealias N = TestNodeLabel
    typealias E = TestEdgeLabel
    typealias Env = TestEnvironment

    func makePersonEdge(
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
        return .outgoing(.isA, TestClasses.person)
    }

    func makeNamedPropertyEdge(
        name: [Token],
        node: TestOntology.Node,
        subject: Subject,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
        let lemmas = name.map { $0.lemma }
        switch lemmas {
        case ["write"]:
            return .incoming(node, .hasAuthor)
        default:
            fatalError("not implemented")
        }
    }

    func makeInversePropertyEdge(
        name: [Token],
        node: TestOntology.Node,
        context: EdgeContext,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
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

    func makeAdjectivePropertyEdge(
        name: [Token],
        node: TestOntology.Node,
        context: EdgeContext,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
        let lemmas = (name + context.filter)
            .map { $0.lemma }
        switch lemmas {
        case ["be", "high"]:
            return .outgoing(.hasElevation, node)
        default:
            fatalError("not implemented")
        }
    }

    func makeComparativePropertyEdge(
        name: [Token],
        node: TestOntology.Node,
        context: EdgeContext,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
        let lemmas = (name + context.filter)
            .map { $0.lemma }
        switch lemmas {
        case ["be", "old", "than"]:
            let otherBirthDate = env
                .newNode()
                .incoming(node, .hasDateOfBirth)
            let birthDate = env
                .newNode()
                .filtered(.lessThan(otherBirthDate))
            return .outgoing(.hasDateOfBirth, birthDate)
        default:
            fatalError("not implemented")
        }
    }

    func makeValuePropertyEdge(
        name: [Token],
        node: TestOntology.Node,
        context: EdgeContext,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {
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
        default:
            fatalError("not implemented")
        }
    }

    func makeRelationshipEdge(
        name: [Token],
        node: TestOntology.Node,
        env: TestEnvironment
    ) throws -> TestOntology.Edge {

        let lemmas = name.filter { $0.tag != "DT" }.map { $0.lemma }
        switch lemmas {
        case ["child"]:
            return .incoming(node, .hasChild)
        case ["grandchild"]:
            return .incoming(node, .hasGrandChild)
        case ["city"]:
            return TestOntology.Edge
                .outgoing(TestEdgeLabel.isA, TestClasses.city)
                .and(.outgoing(TestEdgeLabel.isLocatedIn, node))
        case ["album"]:
            return TestOntology.Edge
                .outgoing(.isA, TestClasses.album)
                .and(.outgoing(TestEdgeLabel.hasPerformer, node))
        case ["daughter"]:
            return TestOntology.Edge
                .outgoing(.isA, TestClasses.woman)
                .and(.incoming(node, .hasChild))
        default:
            fatalError("not implemented")
        }
    }

    private func getClass(_ name: [Token]) -> TestNode? {
        guard name.count == 1 else {
            return nil
        }

        switch name.first?.lemma {
        case "movie":
            return TestClasses.movie
        case "mountain":
            return TestClasses.mountain
        case "author":
            return TestClasses.author
        case "president":
            return TestClasses.president
        default:
            return nil
        }
    }

    func makeValueNode(
        name: [Token],
        filter: [Token],
        env: TestEnvironment
    ) throws -> TestOntology.Node {

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

    func makeNumberNode(
        number: [Token],
        unit: [Token],
        filter: [Token],
        env: TestEnvironment
    ) throws -> TestOntology.Node {
        let numberString = number.map { $0.lemma }.joined(separator: " ")
        let unitString = unit.isEmpty
            ? nil
            : unit.map { $0.lemma }.joined(separator: " ")
        return Node(label: .number(Double(numberString)!, unit: unitString))
    }
}
