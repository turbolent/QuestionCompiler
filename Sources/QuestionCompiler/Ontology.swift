
import QuestionParser

public protocol Ontology {
    associatedtype N
    associatedtype E
    associatedtype Env: Environment
        where Env.N == N, Env.E == E

    typealias Node = GraphNode<N, E>
    typealias Edge = GraphEdge<E, N>
    typealias Filter = GraphFilter<E, N>

    /// Return an edge which will identify a node representing the subject to be a person.
    ///
    /// Invoked for `ListQuestion.person`, i.e., when the question asks for a person,
    /// e.g., for the question "who died?".
    ///
    /// A suitable return value could be an outgoing edge declaring that the edge source
    /// is a an instance of a person:
    /// ```
    /// .outgoing(EdgeLabels.isInstanceOf, NodeLabels.person)
    /// ```
    ///
    func makePersonEdge(env: Env) throws -> Edge

    /// Return an edge which will identify a node representing the subject to have the property
    /// given by `name`. `node` is the object.
    ///
    /// Invoked for `Property.named`, i.e., when the subject has a simple property without a filter,
    /// e.g., for the question "who wrote?".
    ///
    /// For this example `name` would be
    /// ```
    /// [Token(word: "wrote", tag: "VBD", lemma: "write")]
    /// ```
    ///
    /// A suitable return value could be an incoming edge declaring that the source
    /// is the author of the target node
    /// ```
    /// .incoming(otherNode, EdgeLabels.hasAuthor)
    /// ```
    ///
    func makeNamedPropertyEdge(name: [Token], node: Node, subject: Subject, env: Env) throws -> Edge

    /// Return and edge which will identify a node representing the subject (given in the context)
    /// to have a property given by `name`. `node` is the object.
    ///
    /// Invoked for `Property.inverseWithFilter`, i.e., when the subject has an inverse property
    /// with a filter (given in the context), e.g., for the question "what books did Shakespeare write?".
    ///
    /// For this example the object (`node`) is representing Shakespeare, the subject
    /// (given in the context) is representing a book, and `name` would be
    /// ```
    /// [
    ///     Token(word: "did", tag: "VBD", lemma: "do"),
    ///     Token(word: "write", tag: "VB", lemma: "write")
    /// ]
    ///
    /// A suitable return value could be an outgoing edge declaring that the source
    /// has the target (the node representing Shakespeare) as its author:
    /// ```
    /// .outgoing(EdgeLabels.hasAuthor, node)
    /// ```
    ///
    func makeInversePropertyEdge(name: [Token], node: Node, context: EdgeContext, env: Env) throws -> Edge

    /// Return and edge which will identify a node representing the subject (given in the context)
    /// to have the property given by `name`, which contains an adjective. `node` is the object.
    ///
    /// Invoked for `Property.adjectiveWithFilter`, i.e., when th e subject has a property
    /// with an adjective, e.g., for the question "who is 42 years old?".
    ///
    /// For this example `name` would be
    /// ```
    /// [
    ///     Token(word: "is", tag: "VBP", lemma: "be"),
    ///     Token(word: "old", tag: "JJ", lemma: "old")
    /// ]
    /// ```
    ///
    /// A suitable return value could be an outgoing edge declaring that the source has
    /// has a certain age (represented by `node`):
    /// ```
    /// .outgoing(EdgeLabels.hasAge, node)
    /// ```
    ///
    func makeAdjectivePropertyEdge(name: [Token], node: Node, context: EdgeContext, env: Env) throws -> Edge

    /// Return an edge which will identify the node representing the subject to have the property
    /// given by `name`, which compares to `node`, which is the object.
    ///
    /// Invoked for `Property.withFilter` with `Filter.withComparativeModifier`, i.e., when the property
    /// contains a comparative filter, e.g., for the question "who is older than Obama?".
    ///
    /// For this example `name` would be
    /// ```
    /// [Token(word: "is", tag: "VBD", lemma: "be")]
    /// ```
    ///
    /// `context.filter` would be
    /// ```
    /// [
    ///     Token(word: "older", tag: "JJR", lemma: "old"),
    ///     Token(word: "than", tag: "IN", lemma: "than")
    /// ]
    /// ```
    ///
    /// A suitable return value could be an outgoing edge declaring that the source has
    /// an earlier birth date than that of `node`:
    /// ```
    /// let birthDate = otherAgeNode.incoming(node, EdgeLabels.hasBirthDate)
    /// return .outgoing(EdgeLabels.hasBirthDate, ageNode.filter(.lessThan(birthDate)))
    /// ```
    ///
    func makeComparativePropertyEdge(name: [Token], node: Node, context: EdgeContext, env: Env) throws -> Edge

    /// Return an edge which will identify the node representing the subject to have the property
    /// given by `name`. `node` is the object.
    ///
    /// Invoked for `Property.withFilter` with any filter but `Filter.plain` or `Filter.withModifier`,
    /// i.e., when the filter is not comparative, e.g., for the question "who wrote Macbeth?".
    ///
    /// For this example `name` would be
    /// ```
    /// [Token(word: "wrote", tag: "VBD", lemma: "write")]
    /// ```
    ///
    /// A suitable return value could be an incoming edge declaring that the edge source is the author
    /// of the target (`node`):
    /// ```
    /// .incoming(node, EdgeLabels.hasAuthor)
    /// ```
    ///
    func makeValuePropertyEdge(name: [Token], node: Node, context: EdgeContext, env: Env) throws -> Edge

    /// Return an edge which will declare a node to have a possessive relationship to `node`.
    ///
    /// Invoked for `Value.relationship`, i.e., when the object/value in a question contains
    /// a possessive relationship, e.g., for the question "who married Clinton's daughter?".
    ///
    /// For this example `name` would be
    /// ```
    /// [Token(word: "daughter", tag: "NN", lemma: "daughter")]
    /// ```
    ///
    /// A suitable return value could be an incoming edge declaring that the edge source is the daughter
    /// of the target (`node`):
    /// ```
    /// .incoming(node, EdgeLabels.hasDaughter)
    /// ```
    ///
    func makeRelationshipEdge(name: [Token], node: Node, env: Env) throws -> Edge

    /// Return a node for the given `name`.
    ///
    /// Invoked for `Query.named` and `Value.named`, i.e., for the subject or object of a question.
    /// `filter` is given for context purposes and might be empty.
    ///
    /// For example, this method is invoked for the questions
    /// "which authors were born before 2000?" and "who lived in Berlin?".
    ///
    /// For the first example `name` would be
    /// ```
    /// [Token(word: "authors", tag: "NNS", lemma: "author")]
    /// ```
    ///
    /// A suitable return value could be an anonymous node with an outgoing edge declaring
    /// that the node should be an instance of an author:
    /// ```
    /// .outgoing(EdgeLabels.isInstanceOf, NodeLabels.author)
    /// ```
    ///
    /// For the second example, `name` would be
    /// ```
    /// [Token(word: "Berlin", tag: "NNP", lemma: "Berlin")]
    /// ```
    ///
    /// A suitable return value could be and an anonymous node with an ougoing edge declaring
    /// that the name of the referenced node should be "Berlin".
    /// ```
    /// .outgoing(EdgeLabels.hasName, NodeLabel.string("Berlin"))
    /// ```
    ///
    func makeValueNode(name: [Token], filter: [Token], env: Env) throws -> Node

    /// Return a node for the given `number` and `unit`.
    ///
    /// Invoked for `Value.number` and `Value.numberWithUnit`, i.e., when the question contains
    /// a numeric value with an optional unit, e.g., for the question "who was born in 1900?".
    ///
    /// For this example, `number` would be `[Token(word: "1900", tag: "CD", lemma: "1900")]`,
    /// and `unit` would be `[]`. A suitable return value might be a node representing the year 1900.
    ///
    /// Note that `number` may contain spelled out numbers, and `unit` "non-standard" units,
    /// e.g. for "two million inhabitants", `name` would be
    /// ```
    /// [
    ///     Token(word: "two", tag: "CD", lemma: "two"),
    ///     Token(word: "million", tag: "CD", lemma: "million")
    /// ]
    /// ```
    ///
    /// `unit` would be
    /// ```
    /// [Token(word: "inhabitants", tag: "NNS", lemma: "inhabitant")]
    /// ```
    ///
    func makeNumberNode(number: [Token], unit: [Token], filter: [Token], env: Env) throws -> Node
}
