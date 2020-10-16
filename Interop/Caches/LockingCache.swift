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
    let backgroundColor = NSUIColor.black.cgColor
    let foregroundColor = NSUIColor.white.cgColor

    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {

        // SCALE_FACTOR changes the requested font size for the new layer.
        // OBSERVATION: Setting this value higher creates a smoother font image
        // HYPOTHESIS: The font size is used to determine the size of a bitmap
        //              or canvas to which the layer is drawn
        let SCALE_FACTOR: CGFloat = 16
        let wordSize = String(key).fontedSize
        let wordSizeScaled = CGSize(width: wordSize.width * SCALE_FACTOR,
                                    height: wordSize.height * SCALE_FACTOR)

        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.foregroundColor = self.foregroundColor
        textLayer.alignmentMode = .left
        textLayer.string = "\(key)"
        textLayer.font = kDefaultSCNTextFont
        textLayer.fontSize = wordSizeScaled.height
        textLayer.frame.size = textLayer.preferredFrameSize()

        // Recompute descaled size of new layer
        let descaledWidth = textLayer.frame.size.width / SCALE_FACTOR
        let descaledHeight = textLayer.frame.size.height / SCALE_FACTOR
        let descaledSize = CGSize(width: descaledWidth, height: descaledHeight)
        let boxPlane = SCNPlane(width: descaledWidth, height: descaledHeight)

        // Create bitmap on queue, set the layer on main. May want to batch this.
        layoutQueue.async {
            // For whatever reason, we need to call display() manually. Or at least,
            // in this particular commit, the image is just blank without it.
            textLayer.display()
            let bitmap = textLayer.getBitmapImage()
            DispatchQueue.main.async {
                boxPlane.firstMaterial?.diffuse.contents = bitmap
            }
        }

        return (boxPlane, descaledSize)
    }
}

private extension CALayer {

    func getBitmapImage() -> NSImage? {

        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(frame.width),
            pixelsHigh: Int(frame.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        ) else {
            print("Failed to make bitmap representation")
            return nil
        }

        guard let nsContext = NSGraphicsContext(
                bitmapImageRep: representation
        ) else {
            print("Failed to create new NSGraphicsContext")
            return nil
        }

        let cgContext = nsContext.cgContext
        render(in: cgContext)

        guard let cgImage = cgContext.makeImage()
        else {
            print("Failed to retreive cgContext image")
            return nil
        }

        return NSImage(
            cgImage: cgImage,
            size: CGSize(width: frame.width,height: frame.height)
        )
    }
}
