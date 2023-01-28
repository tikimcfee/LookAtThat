import Foundation

/// Thread-safe dictionary wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
public final class ConcurrentDictionary<Key: Hashable, Value> {

    private var container: [Key: Value] = [:]
    private let rwlock = LockWrapper()
    
    public var count: Int {
        let result: Int
        rwlock.readLock()
        result = container.count
        rwlock.unlock()
        return result
    }
    
    public var isEmpty: Bool {
        let result: Bool
        rwlock.readLock()
        result = container.isEmpty
        rwlock.unlock()
        return result
    }

    public var keys: [Key] {
        let result: [Key]
        rwlock.readLock()
        result = Array(container.keys)
        rwlock.unlock()
        return result
    }

    public var values: [Value] {
        let result: [Value]
        rwlock.readLock()
        result = Array(container.values)
        rwlock.unlock()
        return result
    }
    
    public func directCopy() -> [Key: Value] {
        let result: [Key: Value]
        rwlock.readLock()
        result = container
        rwlock.unlock()
        return result
    }

    public func removeAll() {
        rwlock.writeLock()
        container.removeAll()
        rwlock.unlock()
    }
    
    public func directWriteAccess(_ action: (inout [Key: Value]) -> Void) {
        rwlock.writeLock()
        action(&container)
        rwlock.unlock()
    }
    
    public init() {}

    /// Sets the value for key
    ///
    /// - Parameters:
    ///   - value: The value to set for key
    ///   - key: The key to set value for
    public func set(value: Value, forKey key: Key) {
        _setSubscript(key, newValue: value)
    }

    @discardableResult
    public func remove(_ key: Key) -> Value? {
        let result: Value?
        rwlock.writeLock()
        result = _remove(key)
        rwlock.unlock()
        return result
    }

    public func contains(_ key: Key) -> Bool {
        let result: Bool
        rwlock.readLock()
        result = container.index(forKey: key) != nil
        rwlock.unlock()
        return result
    }

    public func value(forKey key: Key) -> Value? {
        let result: Value?
        rwlock.readLock()
        result = container[key]
        rwlock.unlock()
        return result
    }

    public func mutateValue(forKey key: Key, mutation: (Value) -> Value) {
        rwlock.writeLock()
        if let value = container[key] {
            container[key] = mutation(value)
        }
        rwlock.unlock()
    }

    // MARK: Subscript
    public subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        set {
            _setSubscript(key, newValue: newValue)
        }
    }
}

extension ConcurrentDictionary {
    private func _setSubscript(_ key: Key, newValue: Value?) {
        rwlock.writeLock()
        
        guard let newValue = newValue else {
            _remove(key)
            rwlock.unlock()
            return
        }
        
        _set(value: newValue, forKey: key)
        rwlock.unlock()
    }
    
    private func _set(value: Value, forKey key: Key) {
        self.container[key] = value
    }
    
    @discardableResult
    private func _remove(_ key: Key) -> Value? {
        guard let index = container.index(forKey: key) else { return nil }
        
        let tuple = container.remove(at: index)
        return tuple.value
    }
}
