//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit
import UniformTypeIdentifiers

public struct GlyphCacheKey: Hashable, Equatable {
    public let glyph: String
    public let foreground: NSUIColor
    public let background: NSUIColor
    
    public init(_ glyph: String,
                _ foreground: NSUIColor,
                _ background: NSUIColor = NSUIColor.black) {
        self.glyph = glyph
        self.foreground = foreground
        self.background = background
    }
}

class GlyphLayerCache: LockingCache<GlyphCacheKey, SizedText> {
    
    #if os(iOS)
    private static let FONT_SIZE = 8.0
    private let SCALE_FACTOR = 1.0
    private let DESCALE_FACTOR = 16.0
    #else
    private static let FONT_SIZE = 16.0
    private let SCALE_FACTOR = 1.0
    private let DESCALE_FACTOR = 16.0
    #endif
    
    private static let MONO_FONT = NSUIFont.monospacedSystemFont(ofSize: FONT_SIZE, weight: .regular)
    
    let layoutQueue = DispatchQueue(label: "GlyphLayerCache=\(UUID())", qos: .userInitiated, attributes: [.concurrent])
    let fontRenderer = FontRenderer()
    private var highlightCache = ConcurrentDictionary<SCNNode, SizedText>()
    
    subscript(key: SCNNode) -> SizedText? {
        get {
            highlightCache[key]
        }
        set {
            highlightCache[key] = newValue
        }
    }
    
    override func make(_ key: GlyphCacheKey, _ store: inout [GlyphCacheKey: SizedText]) -> Value {
//        print("--- Caching \(key.glyph) || Size == \(store.count)")
        
		// Size the glyph from the font using a rendering scale factor
        let safeString = key.glyph
        
        let wordSize = safeString.size(withAttributes: [.font: Self.MONO_FONT])
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
        
		// Resize the final layer according to descale factor
        let descaledWidth = textLayer.frame.size.width / DESCALE_FACTOR
        let descaledHeight = textLayer.frame.size.height / DESCALE_FACTOR
        let descaledSize = CGSize(width: descaledWidth, height: descaledHeight)
        let boxPlane = SCNPlane(width: descaledWidth, height: descaledHeight)
        
        textLayer.display()
        let bitmap = textLayer.getBitmapImage(using: key)
        DispatchQueue.main.async {
            boxPlane.firstMaterial?.diffuse.contents = bitmap
        }
        
        return (boxPlane, descaledSize)
    }
}

import CoreServices
extension CALayer {
#if os(iOS)
    
    func getBitmapImage(
        using key: GlyphCacheKey
    ) -> NSUIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(key.background.cgColor)
        context.fill(frame)
        render(in: context)
        
        let options = NSDictionary(dictionary: [
            kCGImageDestinationLossyCompressionQuality: 0.0
        ])
        
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        let mutableData = CFDataCreateMutable(nil, 0)!
        let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil)!
        CGImageDestinationSetProperties(destination, options)
        CGImageDestinationAddImage(destination, outputImage, nil)
        CGImageDestinationFinalize(destination)
        let source = CGImageSourceCreateWithData(mutableData, nil)!
        let finalImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        
        return UIImage(cgImage: finalImage)
//        return outputImage
    }
    
#elseif os(OSX)
    
    func getBitmapImage(
        using key: GlyphCacheKey
    ) -> NSUIImage? {
        guard var representation = defaultRepresentation() else {
            print("Failed to make bitmap representation")
            return nil
        }
        
        guard let compressed = compressedJpegRepresentation(from: representation, using: key)
        else {
            print("Failed to make compressed jpeg representation")
            return nil
        }
        representation = compressed
        
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
        
        let finalImage = cgImage
        
        //        guard let finalImage = cgImagePrimitivesJPEG(from: cgImage) else {
        //            print("Failed to recreate as JPEG")
        //            return nil
        //        }
        
        return NSImage(
            cgImage: finalImage,
            size: CGSize(width: frame.width, height: frame.height)
        )
    }
    
    func compressedJpegRepresentation(
        from source: NSBitmapImageRep,
        using key: GlyphCacheKey
    ) -> NSBitmapImageRep? {
        guard
            let jpegData = source.representation(
                using: .jpeg,
                properties: [
                    .fallbackBackgroundColor: key.background
                ]
            ),
            let jpegRepresentation = NSBitmapImageRep(data: jpegData)
        else {
            print("Failed to make jepg representation")
            return nil
        }
        
        return jpegRepresentation
    }
    
    func cgImagePrimitivesJPEG(from cgImage: CGImage) -> CGImage? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil)
        else {
            print("Failed to make CFData / CGImageDest")
            return nil
        }
        
        let options = NSDictionary(dictionary: [
            kCGImageDestinationLossyCompressionQuality: 0.0
        ])
        CGImageDestinationAddImage(destination, cgImage, options)
        CGImageDestinationFinalize(destination)
        
        guard let source = CGImageSourceCreateWithData(mutableData, nil)
        else {
            print("Failed to make CGImageSource")
            return nil
        }
        let finalImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        
        return finalImage
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
