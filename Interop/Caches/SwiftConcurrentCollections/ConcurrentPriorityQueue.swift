import Foundation

/// Thread-safe priority queue wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
public final class ConcurrentPriorityQueue<Element> {

    private var container: PriorityQueue<Element>
    private let rwlock = RWLock()

    public var count: Int {
        rwlock.readLock()
        defer {
            rwlock.unlock()
        }
        return container.count
    }

    public init(capacity: Int, complexComparator: @escaping PriorityQueue<Element>.ComplexComparator) {
        self.container = PriorityQueue(capacity: capacity, complexComparator: complexComparator)
    }

    public init(capacity: Int, comparator: @escaping PriorityQueue<Element>.Comparator) {
        self.container = PriorityQueue(capacity: capacity, comparator: comparator)
    }

    /// Creates `ConcurrentPriorityQueue` with default capacity
    /// - Parameter comparator: heap property will hold if `comparator(parent(i), i)` is `true`
    ///     e.g. `<` will create a minimum-queue and `>` - maximum-queue
    public init(_ comparator: @escaping PriorityQueue<Element>.Comparator) {
        self.container = PriorityQueue(comparator)
    }

    public func insert(_ value: Element) {
        rwlock.writeLock()
        container.insert(value)
        rwlock.unlock()
    }

    /// Remove top element from the queue
    public func pop() -> Element {
        rwlock.writeLock()
        defer {
            rwlock.unlock()
        }

        return container.pop()
    }

    /// Get top element from the queue
    public func peek() -> Element {
        rwlock.readLock()
        defer {
            rwlock.unlock()
        }

        return container.peek()
    }

    /// Get top element from the queue, returns `nil`if queue is empty
    public func safePeek() -> Element? {
        rwlock.readLock()
        defer {
            rwlock.unlock()
        }
        return container.count > 0
            ? container.peek()
            : nil
    }

    /// Remove top element from the queue, returns `nil`if queue is empty
    public func safePop() -> Element? {
        rwlock.writeLock()
        defer {
            rwlock.unlock()
        }

        return container.count > 0
            ? container.pop()
            : nil
    }

}
