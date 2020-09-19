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
        get {
            return cache[key] ?? {
                // Wait and recheck cache, last lock may have already set
                semaphore.wait(); defer { semaphore.signal() }
                if let cached = cache[key] { return cached }

                // Create and set, default result as cache value
                let new = make(key, &cache)
                cache[key] = new
                return new
            }()
        }
    }
}

class HighlightCache: LockingCache<SCNGeometry, SCNGeometry> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let highlighted = key.deepCopy()
        highlighted.firstMaterial?.diffuse.contents = NSUIColor.red
        store[highlighted] = key // reverse lookup to get back the original color
        return highlighted
    }
}

class WordColorCache: LockingCache<String, NSUIColor> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        return NSUIColor(
            displayP3Red: CGFloat(Float.random(in: 0...1)),
            green: CGFloat(Float.random(in: 0...1)),
            blue: CGFloat(Float.random(in: 0...1)),
            alpha: 1.0
        )
    }
}

class WordGeometryCache: LockingCache<Character, SizedText> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let (word, color) =
            key.isWhitespace
                ? (" ",     NSUIColor.clear)
                : ("\(key)", NSUIColor.white) // SCNText doesn't like some Characters

        let textGeometry = SCNText(string: word, extrusionDepth: WORD_EXTRUSION_SIZE)
        textGeometry.font = kDefaultSCNTextFont
        textGeometry.firstMaterial?.diffuse.contents = color

        let sizedText = (textGeometry, String(key).fontedSize)
        return sizedText
    }
}
