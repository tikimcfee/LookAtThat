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
    private let semaphore = DispatchSemaphore(value: 1)

    open func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        fatalError("A locking cache may not be used without a builder.")
    }

    subscript(key: Key) -> Value {
        get { cache[key] ?? lockAndMake(key: key) }
		set { lockAndSet(key: key, value: newValue) }
    }
    
    func isEmpty() -> Bool {
        cache.isEmpty
    }
    
    @discardableResult
    func remove(_ key: Key) -> Value? {
        semaphore.wait(); defer { semaphore.signal() }
        return cache.removeValue(forKey: key)
    }
    
    func doOnEach(_ action: (Key, Value) -> Void) {
        semaphore.wait(); defer { semaphore.signal() }
        cache.forEach {
            action($0.key, $0.value)
        }
    }
    
    func contains(_ key: Key) -> Bool {
        semaphore.wait(); defer { semaphore.signal() }
        return cache[key] != nil
    }
	
	private func lockAndSet(key: Key, value: Value) {
		semaphore.wait(); defer { semaphore.signal() }
		cache[key] = value
	}
    
    private func lockAndMake(key: Key) -> Value {
        // Wait and recheck cache, last lock may have already set
        semaphore.wait(); defer { semaphore.signal() }
        if let cached = cache[key] { return cached }
        
        // Create and set, default result as cache value
        let new = make(key, &cache)
        cache[key] = new
        return new
    }
}
