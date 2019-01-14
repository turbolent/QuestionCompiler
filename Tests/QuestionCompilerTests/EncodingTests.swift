import XCTest
import QuestionParser
import DiffedAssertEqual
import TestOntology

class EncodingTests: XCTestCase {

    func testGraph1() throws {
        let env = TestEnvironment()
        let person = env.newNode()
            .isA(TestClasses.person)
        let movie = env.newNode()
            .hasName("Alien")
        let root = person
            .incoming(movie, .hasCastMember)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        diffedAssertEqual(
            String(data: try encoder.encode(root), encoding: .utf8),
            """
            {
              "label" : {
                "type" : "variable",
                "id" : 0
              },
              "filter" : null,
              "order" : null,
              "type" : "node",
              "edge" : {
                "type" : "edge",
                "subtype" : "conjunction",
                "edges" : [
                  {
                    "label" : {
                      "type" : "property",
                      "name" : "isA",
                      "url" : "http:\\/\\/example.org\\/property\\/isA"
                    },
                    "type" : "edge",
                    "subtype" : "outgoing",
                    "target" : {
                      "label" : {
                        "type" : "item",
                        "name" : "person",
                        "url" : "http:\\/\\/example.org\\/item\\/person"
                      },
                      "filter" : null,
                      "order" : null,
                      "type" : "node",
                      "edge" : null
                    }
                  },
                  {
                    "label" : {
                      "type" : "property",
                      "name" : "hasCastMember",
                      "url" : "http:\\/\\/example.org\\/property\\/hasCastMember"
                    },
                    "source" : {
                      "label" : {
                        "type" : "variable",
                        "id" : 1
                      },
                      "filter" : null,
                      "order" : null,
                      "type" : "node",
                      "edge" : {
                        "label" : {
                          "type" : "property",
                          "name" : "hasName",
                          "url" : "http:\\/\\/example.org\\/property\\/hasName"
                        },
                        "type" : "edge",
                        "subtype" : "outgoing",
                        "target" : {
                          "label" : {
                            "type" : "value",
                            "subtype" : "string",
                            "value" : "Alien"
                          },
                          "filter" : null,
                          "order" : null,
                          "type" : "node",
                          "edge" : null
                        }
                      }
                    },
                    "type" : "edge",
                    "subtype" : "incoming"
                  }
                ]
              }
            }
            """
        )
    }
}
