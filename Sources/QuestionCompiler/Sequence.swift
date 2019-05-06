extension Sequence {
    func unzip<T, U>() -> ([T], [U]) where Element == (T, U) {
        return reduce(into: ([T](), [U]())) { result, pair in
            let (left, right) = pair
            result.0.append(left)
            result.1.append(right)
        }
    }
}
