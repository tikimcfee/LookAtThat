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

class WordStringCache: LockingCache<String, SizedText> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let (word, color) = ("\(key)", NSUIColor.white)
        let textGeometry = SCNText(string: word, extrusionDepth: WORD_EXTRUSION_SIZE)
        textGeometry.font = kDefaultSCNTextFont
        textGeometry.firstMaterial?.diffuse.contents = color
        let sizedText = (textGeometry, String(key).fontedSize)
        return sizedText
    }
}

class WordLayerCache: LockingCache<String, SizedText> {
    let layoutQueue = DispatchQueue(label: "WordLayerCache", qos: .userInitiated)
    let backgroundColor = NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.4, alpha: 0.95).cgColor
    let foregroundColor = NSUIColor.white.cgColor

    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let wordSize = String(key).fontedSize

        print("WordSize - \(wordSize)")
        let SCALE_FACTOR: CGFloat = 16.0
        let layerSize = (width: wordSize.width * SCALE_FACTOR,
                         height: wordSize.height * SCALE_FACTOR)

        let layer = CALayer()
        let textLayer = CATextLayer()
        let box = SCNBox(width: wordSize.width,
                         height: wordSize.height,
                         length: 0.0,
                         chamferRadius: 0.25)

        layoutQueue.sync {
            layer.backgroundColor = backgroundColor
            layer.frame = CGRect(x: 0, y: 0,
                                 width: layerSize.width,
                                 height: layerSize.height)


            textLayer.string = "\(key)"
            textLayer.font = kDefaultSCNTextFont
            textLayer.fontSize = kDefaultSCNTextFont.pointSize * SCALE_FACTOR
            textLayer.alignmentMode = .left
            textLayer.foregroundColor = foregroundColor
            textLayer.frame = layer.bounds

            textLayer.display()
            layer.addSublayer(textLayer)

            box.firstMaterial?.locksAmbientWithDiffuse = true
            box.firstMaterial?.diffuse.contents = layer
        }

        return (box, wordSize)
    }
}
