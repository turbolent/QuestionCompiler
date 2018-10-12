
import QuestionParser

public struct EdgeContext {
    public let subject: Subject
    public let filter: [Token]
    public let value: [Token]
    public let unit: [Token]
    public let valueIsNumber: Bool
}
