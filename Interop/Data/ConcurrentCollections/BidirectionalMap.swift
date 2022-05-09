// Originally from https://gist.github.com/CanTheAlmighty/70b3bf66eb1f2a5cee28

class ConcurrentBiMap<Key: Hashable, Value: Hashable>: ExpressibleByDictionaryLiteral {
    typealias Forward = ConcurrentDictionary<Key, Value>
    typealias Backward = ConcurrentDictionary<Value, Key>
    private(set) var keysToValues = Forward()
    private(set) var valuesToKeys = Backward()
    
    // MARK: - Initializers
    
    init(forward: Forward) {
        let newBackward = Backward()
        forward.directCopy().forEach { pair in
            newBackward[pair.value] = pair.key
        }
        self.keysToValues = forward
        self.valuesToKeys = newBackward
    }
    
    init(backward: Backward) {
        let newForward = Forward()
        backward.directCopy().forEach { pair in
            newForward[pair.value] = pair.key
        }
        self.keysToValues = newForward
        self.valuesToKeys = backward
    }
    
    required init(dictionaryLiteral elements: (Key, Value)...) {
        for keyValuePair in elements {
            keysToValues[keyValuePair.0] = keyValuePair.1
            valuesToKeys[keyValuePair.1] = keyValuePair.0
        }
    }
    
    init() { }
    
    // MARK: - Subscripts
    
    subscript(key: Key) -> Value? {
        get {
            return keysToValues[key]
        }
        
        set {
            if let toRemove = keysToValues[key] {
                valuesToKeys[toRemove] = newValue == nil ? nil : key
            } else if let newValue = newValue {
                valuesToKeys[newValue] = key
            }
            keysToValues[key] = newValue
        }
    }
    
    subscript(valueAsKey: Value) -> Key? {
        get {
            return valuesToKeys[valueAsKey]
        }
        
        set {
            if let keyAsKeyToUpdate = valuesToKeys[valueAsKey] {
                keysToValues[keyAsKeyToUpdate] = newValue == nil ? nil : valueAsKey
            } else if let newValue = newValue {
                keysToValues[newValue] = valueAsKey
            }
            valuesToKeys[valueAsKey] = newValue
        }
    }

}

struct BiMap<Key: Hashable, Value: Hashable>: ExpressibleByDictionaryLiteral {
    var keysToValues: [Key : Value] = [:]
    var valuesToKeys: [Value : Key] = [:]

    // MARK: - Initializers

    init(forward: [Key: Value]) {
        var newBackward: [Value: Key] = [:]

        for (key,value) in forward {
            newBackward[value] = key
        }

        self.keysToValues = forward
        self.valuesToKeys = newBackward
    }

    init(backward: [Value: Key]) {
        var newForward: [Key: Value] = [:]

        for (key, value) in backward {
            newForward[value] = key
        }

        self.keysToValues = newForward
        self.valuesToKeys = backward
    }

    init(dictionaryLiteral elements: (Key, Value)...) {
        for keyValuePair in elements {
            keysToValues[keyValuePair.0] = keyValuePair.1
            valuesToKeys[keyValuePair.1] = keyValuePair.0
        }
    }

    init() { }

    // MARK: - Subscripts

    subscript(key : Key) -> Value? {
        get {
            return keysToValues[key]
        }

        set {
            if let toRemove = keysToValues[key] {
                valuesToKeys[toRemove] = newValue == nil ? nil : key
            } else if let newValue = newValue {
                valuesToKeys[newValue] = key
            }
            keysToValues[key] = newValue
        }
    }

    subscript(valueAsKey : Value) -> Key? {
        get {
            return valuesToKeys[valueAsKey]
        }

        set {
            if let keyAsKeyToUpdate = valuesToKeys[valueAsKey] {
                keysToValues[keyAsKeyToUpdate] = newValue == nil ? nil : valueAsKey
            } else if let newValue = newValue {
                keysToValues[newValue] = valueAsKey
            }
            valuesToKeys[valueAsKey] = newValue
        }
    }
}
