
import SPARQL

public struct OpResult {

    public static let identity = OpResult(
        op: .identity,
        orderComparators: []
    )

    public let op: SPARQL.Op
    public let orderComparators: [SPARQL.OrderComparator]

    public init(
        op: SPARQL.Op,
        orderComparators: [SPARQL.OrderComparator]
    ) {
        self.op = op
        self.orderComparators = orderComparators
    }

    public func join(_ other: OpResult) -> OpResult {

        // optimization
        if case let (.bgp(triples), .bgp(otherTriples)) = (op, other.op) {
            return OpResult(
                op: .bgp(triples + otherTriples),
                orderComparators:
                    orderComparators + other.orderComparators
            )
        }

        return OpResult(
            op: .join(op, other.op),
            orderComparators:
                orderComparators + other.orderComparators
        )
    }

    public func union(_ other: OpResult) -> OpResult {
        return OpResult(
            op: .union(op, other.op),
            orderComparators:
                orderComparators + other.orderComparators
        )
    }
}
