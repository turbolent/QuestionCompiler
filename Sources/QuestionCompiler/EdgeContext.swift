
import QuestionParser

public struct EdgeContext {
    public let subject: Subject
    public let filter: [Token]
    public let value: [Token]
    public let unit: [Token]
    public let valueIsNumber: Bool

    /// True when the filter is `withComparativeModifier`, i.e., when the property contains
    /// a comparative filter, e.g., for the question "who is older than Obama?".
    ///
    /// For this example `filter` would be:
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
    public let filterIsComparative: Bool
}
