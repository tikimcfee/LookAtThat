import Foundation

/// Thread-safe array wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
public final class ConcurrentArray<Element> {

    private var container: [Element] = []
    private let rwlock = RWLock()

    public var values: [Element] {
        let result: [Element]
        rwlock.readLock()
        result = container
        rwlock.unlock()
        return result
    }

    public var count: Int {
        let result: Int
        rwlock.readLock()
        result = container.count
        rwlock.unlock()
        return result
    }

    // MARK: Lifecycle
    public init() {}

    public init(_ array: Array<Element>) {
        container = array
    }

    // MARK: Public
    public func append(_ newElement: Element) {
        rwlock.writeLock()
        container.append(newElement)
        rwlock.unlock()
    }

    @discardableResult
    public func remove(at index: Int) -> Element {
        let result: Element
        rwlock.writeLock()
        result = container.remove(at: index)
        rwlock.unlock()
        return result
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        rwlock.writeLock()
        container.removeAll(keepingCapacity: keepCapacity)
        rwlock.unlock()
    }

    public func removeFirst(_ k: Int) {
        rwlock.writeLock()
        container.removeFirst(k)
        rwlock.unlock()
    }

    @discardableResult
    public func removeFirst() -> Element {
        let result: Element
        rwlock.writeLock()
        result = container.removeFirst()
        rwlock.unlock()
        return result
    }

    public func value(at index: Int) -> Element {
        let result: Element
        rwlock.readLock()
        result = container[index]
        rwlock.unlock()
        return result
    }

    public func mutateValue(at index: Int, mutation: (Element) -> Element) {
        rwlock.writeLock()
        let value = container[index]
        container[index] = mutation(value)
        rwlock.unlock()
    }

    // MARK: Subscript
    public subscript(index: Int) -> Element {
        get {
            return value(at: index)
        }
        set {
            rwlock.writeLock()
            _set(value: newValue, at: index)
            rwlock.unlock()
        }
    }

    public subscript(safe index: Int) -> Element? {
        get {
            let result: Element?
            rwlock.readLock()
            if index >= container.count || index < 0 {
                result = nil
            } else {
                result = container[index]
            }
            rwlock.unlock()
            return result
        }
    }

    // MARK: Private
    @inline(__always)
    private func _set(value: Element, at index: Int) {
        container[index] = value
    }

}
