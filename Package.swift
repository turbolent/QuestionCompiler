// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "QuestionCompiler",
    products: [
        .library(
            name: "QuestionCompiler",
            targets: ["QuestionCompiler"]),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/QuestionParser.git", .branch("master")),
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", .branch("master")),
        .package(url: "https://github.com/turbolent/SPARQL.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "QuestionCompiler",
            dependencies: ["QuestionParser", "SPARQL"]),
        .testTarget(
            name: "QuestionCompilerTests",
            dependencies: ["QuestionCompiler", "DiffedAssertEqual"]),
    ]
)
