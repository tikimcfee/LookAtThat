//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

public struct GlyphCacheKey: Hashable, Equatable {
    public let glyph: String
    public let foreground: NSUIColor
    public var attributes: [String: AnyHashable]
    
    public init(_ glyph: String,
                _ foreground: NSUIColor,
                _ attributes: [String: AnyHashable] = [:]) {
        self.glyph = glyph
        self.foreground = foreground
        self.attributes = attributes
    }
    
    private lazy var identifier: String = {
        print("Glyph instantiated, [\(glyph)]")
        return UUID().uuidString
    }()
}

struct GlyphRender {
    private static let kDefaultSCNTextFont = NSUIFont.monospacedSystemFont(ofSize: WORD_FONT_POINT_SIZE, weight: .regular)
    let font: NSUIFont = kDefaultSCNTextFont
    
    func size(_ target: GlyphCacheKey) -> CGSize {
        target.glyph.size(withAttributes: [
            .font: font
        ])
    }
}

class GlyphLayerCache: LockingCache<GlyphCacheKey, SizedText> {
    let layoutQueue = DispatchQueue(label: "GlyphLayerCache=\(UUID())", qos: .userInitiated, attributes: [.concurrent])
    
    let fontRenderer = FontRenderer()
    
    override func make(_ key: GlyphCacheKey, _ store: inout [GlyphCacheKey: SizedText]) -> Value {
        print("--- Caching \(key.glyph) || Size == \(store.count)")
        
        // SCALE_FACTOR changes the requested font size for the new layer.
        // OBSERVATION: Setting this value higher creates a smoother font image
        // HYPOTHESIS: The font size is used to determine the size of a bitmap
        //              or canvas to which the layer is drawn
        let SCALE_FACTOR: CGFloat = 16
        let safeString = "\(key.glyph)"
        let wordSize = fontRenderer.size(safeString)
        let wordSizeScaled = CGSize(width: wordSize.width * SCALE_FACTOR,
                                    height: wordSize.height * SCALE_FACTOR)
        
        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.foregroundColor = key.foreground.cgColor
        textLayer.alignmentMode = .left
        textLayer.string = safeString
        textLayer.font = fontRenderer.font
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
#if os(iOS)
    func getBitmapImage() -> NSUIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        render(in: context)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return outputImage
    }
#elseif os(OSX)
    func getBitmapImage() -> NSUIImage? {
        guard let representation = defaultRepresentation() else {
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
            size: CGSize(width: frame.width, height: frame.height)
        )
    }
    
    func defaultRepresentation() -> NSBitmapImageRep? {
        return NSBitmapImageRep(
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
        )
    }
#endif
}
