// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "QuestionCompiler",
    products: [
        .library(
            name: "QuestionCompiler",
            targets: ["QuestionCompiler"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/QuestionParser.git", .branch("master")),
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", from: "0.2.0"),
        .package(url: "https://github.com/turbolent/SPARQL.git", from: "0.2.0"),
        .package(url: "https://github.com/turbolent/OrderedSet.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "QuestionCompiler",
            dependencies: [
                "QuestionParser",
                "OrderedSet"
            ]
        ),
        .testTarget(
            name: "QuestionCompilerTests",
            dependencies: [
                "QuestionCompiler",
                "SPARQLCompiler",
                "DiffedAssertEqual",
                "TestGraphProvider"
            ]
        ),
        .target(
            name: "TestGraphProvider",
            dependencies: ["QuestionCompiler"]
        ),
        .target(
            name: "SPARQLCompiler",
            dependencies: ["QuestionCompiler", "SPARQL"]
        ),
        .testTarget(
            name: "SPARQLCompilerTests",
            dependencies: [
                "QuestionCompiler",
                "SPARQLCompiler",
                "DiffedAssertEqual",
                "TestGraphProvider"
            ]
        ),
    ]
)
