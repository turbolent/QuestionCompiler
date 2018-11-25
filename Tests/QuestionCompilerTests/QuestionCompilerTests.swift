
import XCTest
import DiffedAssertEqual
import ParserCombinators
import QuestionParser
@testable import QuestionCompiler

final class QuestionCompilerTests: XCTestCase {

    private func newCompiler() -> TestCompiler {
        let environment = TestEnvironment()
        let ontology = TestOntology()
        return QuestionCompiler(environment: environment, ontology: ontology)
    }

    func testQ1() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("acted", "VBD", "act")],
                    filter: .withModifier(
                        modifier: [t("in", "IN", "in")],
                        value: .named([t("Alien", "NNP", "alien")])
                    )
                )
            )
        )

        let env = TestEnvironment()
        let person = env.newNode()
            .isA(TestClasses.person)
        let movie = env.newNode()
            .hasName("Alien")
        let expected = person
            .incoming(movie, .hasCastMember)

        diffedAssertEqual([expected], result)
    }

    func testQ2() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .withProperty(
                    .named([t("Movies", "NNP", "movie")]),
                    property: .withFilter(
                        name: [t("starring", "VB", "star")],
                        filter: .plain(.named([
                            t("Winona", "NNP", "winona"),
                            t("Ryder", "NNP", "ryder")
                        ]))
                    )
                )
            )
        )

        let env = TestEnvironment()
        let movie = env.newNode()
            .isA(TestClasses.movie)
        let actress = env.newNode()
            .hasName("Winona Ryder")
        let expected = movie
            .outgoing(.hasCastMember, actress)

        diffedAssertEqual([expected], result)
    }

    func testQ3() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .inverseWithFilter(
                    name: [
                        t("did", "VBD", "do"),
                        t("marry", "VB", "marry")
                    ],
                    filter: .plain(.named([
                        t("Bill", "NNP", "bill"),
                        t("Clinton", "NNP", "clinton")
                    ]))
                )
            )
        )

        let env = TestEnvironment()
        let person = env.newNode()
            .isA(TestClasses.person)
        let billClinton = env.newNode()
            .hasName("Bill Clinton")
        let expected = person
            .outgoing(.hasSpouse, billClinton)

        diffedAssertEqual([expected], result)
    }

    func testQ4() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .withProperty(
                    .named([t("mountains", "NNS", "mountain")]),
                    property: .adjectiveWithFilter(
                        name: [
                            t("are", "VBP", "be"),
                            t("high", "JJ", "high")
                        ],
                        filter: .plain(.numberWithUnit(
                            [t("1000", "CD", "1000")],
                            unit: [t("meters", "NNS", "meter")])
                        )
                    )
                )
            )
        )

        let env = TestEnvironment()

        let elevation: Node = .number(1000.0, unit: "meter")

        let expected = env.newNode()
            .isA(TestClasses.mountain)
            .outgoing(.hasElevation, elevation)

        diffedAssertEqual([expected], result)
    }

    func testQ5() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .withProperty(
                    .named([t("authors", "NNS", "author")]),
                    property: .and([
                        .withFilter(
                            name: [
                                t("were", "VBD", "be"),
                                t("born", "VBD", "bear")
                            ],
                            filter: .withModifier(
                                modifier: [t("in", "IN", "in")],
                                value: .named([t("Berlin", "NNP", "berlin")])
                            )
                        ),
                        .withFilter(
                            name: [t("died", "VBD", "die")],
                            filter: .withModifier(
                                modifier: [t("in", "IN", "in")],
                                value: .named([t("Paris", "NNP", "paris")])
                            )
                        )
                    ])
                )
            )
        )

        let env = TestEnvironment()

        let author = env.newNode()
            .isA(TestClasses.author)

        let place = env.newNode()
            .hasName("Berlin")

        let place2 = env.newNode()
            .hasName("Paris")

        let expected = author
            .outgoing(.hasPlaceOfBirth, place)
            .outgoing(.hasPlaceOfDeath, place2)

        diffedAssertEqual([expected], result)
    }

    func testQ6() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .relationship(
                    .and([
                        .named([t("children", "NNS", "child")]),
                        .named([t("grandchildren", "NNS", "grandchild")])
                    ]),
                    .named([t("Clinton", "NNP", "clinton")]),
                    token: t("'s", "POS", "'s")
                )
            )
        )

        let env = TestEnvironment()
        let bill = env.newNode()
            .hasName("Clinton")

        let child = env.newNode()
            .incoming(bill, .hasChild)
        let grandchild = env.newNode()
            .incoming(bill, .hasGrandChild)

        diffedAssertEqual([child, grandchild], result)
    }

    func testQ7() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .relationship(
                    .named([
                        t("cities", "NNS", "city")
                    ]),
                    .and([
                        .named([t("Japan", "NNP", "japan")]),
                        .named([t("China", "NNP", "china")])
                    ]),
                    token: t("of", "IN", "of")
                )
            )
        )

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

        diffedAssertEqual([japaneseCities, chineseCities], result)
    }

    func testQ8() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .thing(
                .inverseWithFilter(
                    name: [
                        t("did", "VBD", "do"),
                        t("write", "VB", "write")
                    ],
                    filter: .plain(.named([
                        t("George", "NNP", "george"),
                        t("Orwell", "NNP", "orwell")
                    ]))
                )
            )
        )

        let env = TestEnvironment()

        let thing = env.newNode()

        let author = env
            .newNode()
            .hasName("George Orwell")

        let expected = thing
            .outgoing(.hasAuthor, author)

        diffedAssertEqual([expected], result)
    }

    func testQ9() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("is", "VBZ", "be")],
                    filter: .withComparativeModifier(
                        modifier: [
                            t("older", "JJR", "old"),
                            t("than", "IN", "than")
                        ],
                        value: .named([t("Obama", "NNP", "obama")])
                    )
                )
            )
        )

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

        let expected = person
            .outgoing(.hasDateOfBirth, birthDate)

        diffedAssertEqual([expected], result)
    }

    func testQ10() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .withProperty(
                    .named([t("presidents", "NNS", "president")]),
                    property: .withFilter(
                        name: [
                            t("were", "VBD", "be"),
                            t("born", "VBN", "bear")
                        ],
                        filter: .withModifier(
                            modifier: [t("before", "IN", "before")],
                            value: .number([t("1900", "CD", "1900")])
                        )
                    )
                )
            )
        )

        let env = TestEnvironment()

        let president = env.newNode()
            .isA(TestClasses.president)

        let birthDate = env
            .newNode()
            .filtered(.lessThan(.number(1900)))

        let expected = president
            .outgoing(.hasDateOfBirth, birthDate)

        diffedAssertEqual([expected], result)
    }

    func testQ11() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .or([
                    .withFilter(
                        name: [
                            t("was", "VBD", "be"),
                            t("born", "VBD", "bear")
                        ],
                        filter: .withModifier(
                            modifier: [t("in", "IN", "in")],
                            value: .named([t("Berlin", "NNP", "berlin")])
                        )
                    ),
                    .withFilter(
                        name: [t("died", "VBD", "die")],
                        filter: .withModifier(
                            modifier: [t("in", "IN", "in")],
                            value: .named([t("Paris", "NNP", "paris")])
                        )
                    )
                ])
            )
        )

        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Berlin")

        let place2 = env
            .newNode()
            .hasName("Paris")

        let expected = person
            .and(
                Edge.outgoing(.hasPlaceOfBirth, place)
                .or(Edge.outgoing(.hasPlaceOfDeath, place2))
            )

        diffedAssertEqual([expected], result)
    }

    func testQ12() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("attended", "VBD", "attend")],
                    filter: .or([
                        .plain(.named([t("Stanford", "NNP", "stanford")])),
                        .plain(.named([t("Berkeley", "NNP", "berkeley")]))
                    ])
                )
            )
        )

        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let expected = person
            .and(
                Edge.outgoing(.attends, place)
                .or(Edge.outgoing(.attends, place2))
            )

        diffedAssertEqual([expected], result)
    }

    func testQ13() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("attended", "VBD", "attend")],
                    filter: .and([
                        .plain(.named([t("Stanford", "NNP", "stanford")])),
                        .plain(.named([t("Berkeley", "NNP", "berkeley")]))
                    ])
                )
            )
        )

        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let expected = person
            .and(Edge.outgoing(.attends, place))
            .and(Edge.outgoing(.attends, place2))

        diffedAssertEqual([expected], result)
    }

    func testQ14() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("attended", "VBD", "attend")],
                    filter: .plain(
                        .or([
                            .named([t("Stanford", "NNP", "stanford")]),
                            .named([t("Berkeley", "NNP", "berkeley")])
                        ])
                    )
                )
            )
        )

        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let expected = person
            .and(
                Edge.outgoing(.attends, place)
                .or(Edge.outgoing(.attends, place2))
            )

        diffedAssertEqual([expected], result)
    }

    func testQ15() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .withFilter(
                    name: [t("attended", "VBD", "attend")],
                    filter: .plain(
                        .and([
                            .named([t("Stanford", "NNP", "stanford")]),
                            .named([t("Berkeley", "NNP", "berkeley")])
                        ])
                    )
                )
            )
        )

        let env = TestEnvironment()

        let person = env.newNode()
            .isA(TestClasses.person)

        let place = env
            .newNode()
            .hasName("Stanford")

        let place2 = env
            .newNode()
            .hasName("Berkeley")

        let expected = person
            .and(Edge.outgoing(.attends, place))
            .and(Edge.outgoing(.attends, place2))

        diffedAssertEqual([expected], result)
    }

    func testQ16() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .other(
                .relationship(
                    .named([t("albums", "NNS", "album")]),
                    .named([
                        t("Pink", "NNP", "pink"),
                        t("Floyd", "NNP", "floyd")
                    ]),
                    token: t("of", "IN", "of")
                )
            )
        )

        let env = TestEnvironment()

        let artist = env
            .newNode()
            .hasName("Pink Floyd")

        let expected = env
            .newNode()
            .isA(TestClasses.album)
            .outgoing(.hasPerformer, artist)

        diffedAssertEqual([expected], result)
    }


    func testQ17() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(
                .inverseWithFilter(
                    name: [
                        t("did", "VBD", "do"),
                        t("marry", "VB", "marry")
                    ],
                    filter: .plain(
                        .relationship(
                            .named([t("daughter", "NN", "daughter")]),
                            .named([
                                t("Bill", "NNP", "bill"),
                                t("Clinton", "NNP", "clinton")
                                ]),
                            token: t("'s", "POS", "'s")
                        )
                    )
                )
            )
        )

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

        let expected = person
            .outgoing(.hasSpouse, daughter)

        diffedAssertEqual([expected], result)
    }

    func testQ18() throws {
        let compiler = newCompiler()
        let result = try compiler.compile(
            question: .person(.named([t("wrote", "VBD", "write")]))
        )

        let env = TestEnvironment()
        let person = env.newNode()
            .isA(TestClasses.person)
        let authored = env.newNode()
        let expected = person
            .incoming(authored, .hasAuthor)

        diffedAssertEqual([expected], result)
    }
}
