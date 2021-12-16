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
    
    private var semaphore = DispatchSemaphore(value: 1)
    public func lock()   { semaphore.wait() }
    public func unlock() { semaphore.signal() }
    
//    private var unfairLock = os_unfair_lock()
//    public func lock()   { os_unfair_lock_lock(&unfairLock) }
//    public func unlock() { os_unfair_lock_unlock(&unfairLock) }

    open func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        fatalError("LockingCache subscript defaults to `make()`; implement this in [\(type(of: self))].")
    }

    subscript(key: Key) -> Value {
        get { lockAndMake(key: key) }
		set { lockAndSet(key: key, value: newValue) }
    }
    
    func isEmpty() -> Bool {
        cache.isEmpty
    }
    
    @discardableResult
    func remove(_ key: Key) -> Value? {
        lock()
        let removed = cache.removeValue(forKey: key)
        unlock()
        return removed
    }
    
    func doOnEach(_ action: (Key, Value) -> Void) {
        lock()
        cache.forEach {
            action($0.key, $0.value)
        }
        unlock()
    }
    
    func lockAndDo(_ op: (inout [Key: Value]) -> Void) {
        lock()
        op(&cache)
        unlock()
    }
	
	private func lockAndSet(key: Key, value: Value) {
        lock()
		cache[key] = value
        unlock()
	}
    
    private func lockAndMake(key: Key) -> Value {
        lock()
        if let cached = cache[key] {
            unlock()
            return cached
        }
        
        var diff = [Key:Value]()
        let new = make(key, &diff)
        cache[key] = new
        
        unlock()
        return new
    }
    
    
}
