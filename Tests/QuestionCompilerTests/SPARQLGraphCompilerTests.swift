
import XCTest
import DiffedAssertEqual
import ParserCombinators
import QuestionParser
import SPARQL
@testable import QuestionCompiler

final class SPARQLGraphCompilerTests: XCTestCase {

    private func compileToSPARQL(node: TestNode, env: TestEnvironment) throws -> String {
        let backend = TestSPARQLBackend()
        let compiler = SPARQLGraphCompiler(environment: env, backend: backend)
        let query = compiler.compileQuery(node: node)
        let context = Context(prefixMapping: [:])
        return try query.serializeToSPARQL(depth: 0, context: context)
    }

    func testQ1() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let movie = env.newNode()
            .hasName("Alien")

        let graph = person
            .incoming(movie, .hasCastMember)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?1 <hasCastMember> ?0 .
              ?1 <hasName> "Alien" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ2() throws {
        let env = TestEnvironment()

        let movie = env.newNode()
            .isA(TestClasses.movie)

        let actress = env.newNode()
            .hasName("Winona Ryder")

        let graph = movie
            .outgoing(.hasCastMember, actress)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <movie> .
              ?0 <hasCastMember> ?1 .
              ?1 <hasName> "Winona Ryder" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ3() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let billClinton = env.newNode()
            .hasName("Bill Clinton")

        let graph = person
            .outgoing(.hasSpouse, billClinton)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?0 <hasSpouse> ?1 .
              ?1 <hasName> "Bill Clinton" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ4() throws {
        let env = TestEnvironment()

        let elevation: TestNode = .number(1000.0, unit: "meter")

        let graph = env.newNode()
            .isA(TestClasses.mountain)
            .outgoing(.hasElevation, elevation)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <mountain> .
              ?0 <hasElevation> 1000.0 .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ5() throws {
        let env = TestEnvironment()

        let author = env.newNode()
            .isA(TestClasses.author)

        let place = env.newNode()
            .hasName("Berlin")

        let place2 = env.newNode()
            .hasName("Paris")

        let graph = author
            .outgoing(.hasPlaceOfBirth, place)
            .outgoing(.hasPlaceOfDeath, place2)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <author> .
              ?0 <hasPlaceOfBirth> ?1 .
              ?1 <hasName> "Berlin" .
              ?0 <hasPlaceOfDeath> ?2 .
              ?2 <hasName> "Paris" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ6() throws {
        let env = TestEnvironment()

        let bill = env.newNode()
            .hasName("Clinton")

        let child = env.newNode()
            .incoming(bill, .hasChild)

        let grandchild = env.newNode()
            .incoming(bill, .hasGrandChild)

        // TODO: merge multiple queries

        let childExpected = """
            SELECT DISTINCT ?1 {
              ?0 <hasChild> ?1 .
              ?0 <hasName> "Clinton" .
            }

            """
        let childActual = try compileToSPARQL(node: child, env: env)
        diffedAssertEqual(childExpected, childActual)

        let grandchildExpected = """
            SELECT DISTINCT ?2 {
              ?0 <hasGrandChild> ?2 .
              ?0 <hasName> "Clinton" .
            }

            """
        let grandchildActual = try compileToSPARQL(node: grandchild, env: env)
        diffedAssertEqual(grandchildExpected, grandchildActual)
    }

    func testQ7() throws {
        let env = TestEnvironment()

        let japan = env.newNode()
            .hasName("Japan")

        let china = env.newNode()
            .hasName("China")

        let japaneseCities = env.newNode()
            .isA(TestClasses.city)
            .and(.outgoing(.isLocatedIn, japan))

        let chineseCities = env.newNode()
            .isA(TestClasses.city)
            .and(.outgoing(.isLocatedIn, china))

        // TODO: merge multiple queries

        let japaneseCitiesExpected = """
            SELECT DISTINCT ?2 {
              ?2 <isA> <city> .
              ?2 <isLocatedIn> ?0 .
              ?0 <hasName> "Japan" .
            }

            """
        let japaneseCitiesActual = try compileToSPARQL(node: japaneseCities, env: env)
        diffedAssertEqual(japaneseCitiesExpected, japaneseCitiesActual)

        let chineseCitiesExpected = """
            SELECT DISTINCT ?3 {
              ?3 <isA> <city> .
              ?3 <isLocatedIn> ?1 .
              ?1 <hasName> "China" .
            }

            """
        let chineseCitiesActual = try compileToSPARQL(node: chineseCities, env: env)
        diffedAssertEqual(chineseCitiesExpected, chineseCitiesActual)

    }

    func testQ8() throws {
        let env = TestEnvironment()

        let thing = env.newNode()

        let author = env
            .newNode()
            .hasName("George Orwell")

        let graph = thing
            .outgoing(.hasAuthor, author)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <hasAuthor> ?1 .
              ?1 <hasName> "George Orwell" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ9() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let obama = env
            .newNode()
            .hasName("Obama")

        let otherBirthDate = env
            .newNode()
            .incoming(obama, .hasDateOfBirth)

        let birthDate = env
            .newNode()
            .filtered(.lessThan(otherBirthDate))

        let graph = person
            .outgoing(.hasDateOfBirth, birthDate)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?0 <hasDateOfBirth> ?3 .
              ?1 <hasDateOfBirth> ?2 .
              ?1 <hasName> "Obama" .
              FILTER (?3 <= ?2)
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ10() throws {
        let env = TestEnvironment()

        let president = env.newNode()
            .isA(TestClasses.president)

        let birthDate = env
            .newNode()
            .filtered(.lessThan(.number(1900)))

        let graph = president
            .outgoing(.hasDateOfBirth, birthDate)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <president> .
              ?0 <hasDateOfBirth> ?1 .
              FILTER (?1 <= 1900.0)
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ11() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Berlin")

        let place2 = env
            .newNode()
            .hasName("Paris")

        let graph = person
            .and(
                Edge.outgoing(.hasPlaceOfBirth, place)
                .or(Edge.outgoing(.hasPlaceOfDeath, place2))
            )

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              {
                ?0 <hasPlaceOfBirth> ?1 .
                ?1 <hasName> "Berlin" .
              } UNION {
                ?0 <hasPlaceOfDeath> ?2 .
                ?2 <hasName> "Paris" .
              }
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ12() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let graph = person
            .and(
                Edge.outgoing(.attends, place)
                .or(Edge.outgoing(.attends, place2))
            )

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              {
                ?0 <attends> ?1 .
                ?1 <hasName> "Stanford" .
              } UNION {
                ?0 <attends> ?2 .
                ?2 <hasName> "Berkeley" .
              }
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ13() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let graph = person
            .and(Edge.outgoing(.attends, place))
            .and(Edge.outgoing(.attends, place2))

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?0 <attends> ?1 .
              ?1 <hasName> "Stanford" .
              ?0 <attends> ?2 .
              ?2 <hasName> "Berkeley" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ14() throws {
        let env = TestEnvironment()

        let artist = env
            .newNode()
            .hasName("Pink Floyd")

        let graph = env
            .newNode()
            .isA(TestClasses.album)
            .outgoing(.hasPerformer, artist)

        let expected = """
            SELECT DISTINCT ?1 {
              ?1 <isA> <album> .
              ?1 <hasPerformer> ?0 .
              ?0 <hasName> "Pink Floyd" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ15() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let bill = env
            .newNode()
            .hasName("Bill Clinton")

        let daughter = env
            .newNode()
            .isA(TestClasses.woman)
            .incoming(bill, .hasChild)

        let graph = person
            .outgoing(.hasSpouse, daughter)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?0 <hasSpouse> ?2 .
              ?2 <isA> <woman> .
              ?1 <hasChild> ?2 .
              ?1 <hasName> "Bill Clinton" .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ16() throws {
        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let authored = env.newNode()

        let graph = person
            .incoming(authored, .hasAuthor)

        let expected = """
            SELECT DISTINCT ?0 {
              ?0 <isA> <person> .
              ?1 <hasAuthor> ?0 .
            }

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ17() throws {
        let env = TestEnvironment()

        let state = env
            .newNode()
            .hasName("California")

        let population = env
            .newNode()
            .ordered(.descending)

        let graph = env
            .newNode()
            .isA(TestClasses.city)
            .outgoing(.isLocatedIn, state)
            .outgoing(.hasPopulation, population)

        let expected = """
            SELECT DISTINCT ?2 {
              ?2 <isA> <city> .
              ?2 <isLocatedIn> ?0 .
              ?0 <hasName> "California" .
              ?2 <hasPopulation> ?1 .
            }
            ORDER BY DESC(?1)

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(expected, actual)
    }

    func testQ18() throws {
        let env = TestEnvironment()

        let planet = env
            .newNode()
            .isA(TestClasses.planet)

        let person = env
            .newNode()
            .isA(TestClasses.person)
            .outgoing(.discovered, planet)

        let graph = env
            .newNode()
            .aggregating(
                planet,
                function: .count,
                distinct: true,
                grouping: person
            )
            .filtered(.greaterThan(.number(3)))
            .ordered(.descending)

        let expected = """
            SELECT DISTINCT ?1 ?2 {
              {
                SELECT DISTINCT ?1 (COUNT(DISTINCT ?0) AS ?2) {
                  ?0 <isA> <planet> .
                  ?1 <isA> <person> .
                  ?1 <discovered> ?0 .
                  ?0 <isA> <planet> .
                }
                GROUP BY ?1
              }
              FILTER (?2 >= 3.0)
            }
            ORDER BY DESC(?2)

            """
        let actual = try compileToSPARQL(node: graph, env: env)
        diffedAssertEqual(actual, expected)
    }
}
