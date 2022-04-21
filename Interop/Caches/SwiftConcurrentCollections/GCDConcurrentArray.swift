import Foundation

/// Thread-safe array wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
@available(*, deprecated, message: "Use `ConcurrentArray` instead")
public final class GCDConcurrentArray<Element> {

    private var container: [Element] = []
    private let containerAccessQueue = DispatchQueue(
        label: "ConcurrentDictionary.containerAccessQueue",
        qos: .default,
        attributes: .concurrent
    )

    public var values: [Element] {
        return containerAccessQueue.sync {
            return Array(self.container)
        }
    }

    public var count: Int {
        return containerAccessQueue.sync {
            return self.container.count
        }
    }

    public init() {}

    public init(_ array: Array<Element>) {
        container = array
    }

    public func append(_ newElement: Element) {
        containerAccessQueue.sync(flags: .barrier) {
            self.container.append(newElement)
        }
    }

    public func remove(at index: Int) -> Element {
        return containerAccessQueue.sync(flags: .barrier) {
            self.container.remove(at: index)
        }
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        containerAccessQueue.sync(flags: .barrier) {
            self.container.removeAll(keepingCapacity: keepCapacity)
        }
    }

    public func removeFirst(_ k: Int) {
        containerAccessQueue.sync(flags: .barrier) {
            self.container.removeFirst(k)
        }
    }

    public func removeFirst() -> Element {
        return containerAccessQueue.sync(flags: .barrier) {
            self.container.removeFirst()
        }
    }

    public func value(at index: Int) -> Element {
        return containerAccessQueue.sync {
            return self.container[index]
        }
    }

    // MARK: Subscript
    public subscript(index: Int) -> Element {
        get {
            return value(at: index)
        }
        set {
            containerAccessQueue.sync(flags: .barrier) {
                self._set(value: newValue, at: index)
            }
        }
    }

    // MARK: Private
    @inline(__always)
    private func _set(value: Element, at index: Int) {
        self.container[index] = value
    }

}
