import Foundation

// Returns reads immediately, and if no value exists, locks dictionary write
// and creates a new object from the given builder. Passed map to allow additional
// modifications during critical section
protocol CacheBuilder {
    associatedtype Key: Hashable
    associatedtype Value
    func make(_ key: Key, _ store: inout [Key: Value]) -> Value
}

open class LockingCache<Key: Hashable, Value>: CacheBuilder {
    
    private var cache = ConcurrentDictionary<Key, Value>()

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
        
    func doOnEach(_ action: (Key, Value) -> Void) {
        var keys = cache.keys.makeIterator()
        var values = cache.values.makeIterator()
        while let key = keys.next(),
              let value = values.next() {
            action(key, value)
        }
    }
    
    func doOnEachThrowing(_ action: (Key, Value) throws -> Void) rethrows {
        var keys = cache.keys.makeIterator()
        var values = cache.values.makeIterator()
        while let key = keys.next(),
              let value = values.next() {
            try action(key, value)
        }
    }
	
	private func lockAndSet(key: Key, value: Value) {
		cache[key] = value
	}
    
    private func lockAndMake(key: Key) -> Value {
        if let cached = cache[key] {
            return cached
        }
        
        var diff = [Key:Value]()
        let new = make(key, &diff)
        cache[key] = new

        return new
    }
}
