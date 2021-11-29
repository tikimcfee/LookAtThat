import Foundation
import SceneKit

// Returns reads immediately, and if no value exists, locks dictionary write
// and creates a new object from the given builder. Passed map to allow additional
// modifications during critical section
protocol CacheBuilder {
    associatedtype Key: Hashable
    associatedtype Value
    func make(_ key: Key, _ store: inout [Key: Value]) -> Value
}

open class LockingCache<Key: Hashable, Value>: CacheBuilder {
    
    private var cache = [Key: Value]()
    
//    private var semaphore = DispatchSemaphore(value: 1)
//    public func lock()   { semaphore.wait() }
//    public func unlock() { semaphore.signal() }
    
    private var unfairLock = os_unfair_lock()
    public func lock()   { os_unfair_lock_lock(&unfairLock) }
    public func unlock() { os_unfair_lock_unlock(&unfairLock) }

    open func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        fatalError("LockingCache subscript defaults to `make()`; implement this in [\(type(of: self))].")
    }

    subscript(key: Key) -> Value {
        get { lockAndReturn(key: key) ?? lockAndMake(key: key) }
		set { lockAndSet(key: key, value: newValue) }
    }
    
    func isEmpty() -> Bool {
        cache.isEmpty
    }
    
    @discardableResult
    func remove(_ key: Key) -> Value? {
        lock(); defer { unlock() }
        return cache.removeValue(forKey: key)
    }
    
    func doOnEach(_ action: (Key, Value) -> Void) {
        lock(); defer { unlock() }
        cache.forEach {
            action($0.key, $0.value)
        }
    }
    
    func contains(_ key: Key) -> Bool {
        lock(); defer { unlock() }
        return cache[key] != nil
    }
    
    func lockAndDo(_ op: (inout [Key: Value]) -> Void) {
        lock(); defer { unlock() }
        op(&cache)
    }
    
    private func lockAndReturn(key: Key) -> Value? {
        // So sad =(; any time I go async and concurrent, the dictionary wheeps.
        // Fine. lock it all down.
        lock(); defer { unlock() }
        return cache[key]
    }
	
	private func lockAndSet(key: Key, value: Value) {
        lock(); defer { unlock() }
		cache[key] = value
	}
    
    private func lockAndMake(key: Key) -> Value {
        // Wait and recheck cache, last lock may have already set
        lock(); defer { unlock() }
        if let cached = cache[key] { return cached }
        
        // Create and set, default result as cache value
        let new = make(key, &cache)
        cache[key] = new
        return new
    }
    
    
}
