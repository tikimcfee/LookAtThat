import Foundation

/// Thread-safe dictionary wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
@available(*, deprecated, message: "Use `ConcurrentDictionary` instead")
public final class GCDConcurrentDictionary<Key: Hashable, Value> {

    private var container: [Key: Value] = [:]
    private let containerAccessQueue = DispatchQueue(
        label: "ConcurrentDictionary.containerAccessQueue",
        qos: .default,
        attributes: .concurrent
    )

    public var keys: [Key] {
        return containerAccessQueue.sync {
            return Array(self.container.keys)
        }
    }

    public var values: [Value] {
        return containerAccessQueue.sync {
            return Array(self.container.values)
        }
    }

    public init() {}
    
    var isEmpty: Bool {
        return containerAccessQueue.sync { self.container.isEmpty }
    }

    /// Sets the value for key
    ///
    /// - Parameters:
    ///   - value: The value to set for key
    ///   - key: The key to set value for
    public func set(value: Value, forKey key: Key) {
        containerAccessQueue.sync(flags: .barrier) {
            self._set(value: value, forKey: key)
        }
    }

    @discardableResult
    public func remove(_ key: Key) -> Value? {
        return containerAccessQueue.sync(flags: .barrier) {
            self._remove(key)
        }
    }

    public func contains(_ key: Key) -> Bool {
        return containerAccessQueue.sync {
            return self.container.index(forKey: key) != nil
        }
    }

    public func value(forKey key: Key) -> Value? {
        return containerAccessQueue.sync {
            return self.container[key]
        }
    }

    // MARK: Subscript
    public subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        set {
            containerAccessQueue.sync(flags: .barrier) {
                guard let newValue = newValue else {
                    self._remove(key)
                    return
                }
                self._set(value: newValue, forKey: key)
            }
        }
    }

    // MARK: Private
    @inline(__always)
    private func _set(value: Value, forKey key: Key) {
        self.container[key] = value
    }

    @inline(__always)
    @discardableResult
    private func _remove(_ key: Key) -> Value? {
        guard let index = self.container.index(forKey: key) else { return nil }

        let tuple = self.container.remove(at: index)
        return tuple.value
    }

}
