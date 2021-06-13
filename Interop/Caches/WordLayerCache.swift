//
//  WordLayerCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

struct LayerCacheKey: Hashable, Equatable {
    let word: String
    let foreground: NSUIColor
}

class WordLayerCache: LockingCache<LayerCacheKey, SizedText> {
    let layoutQueue = DispatchQueue(label: "WordLayerCache", qos: .userInitiated)
    let backgroundColor = NSUIColor.black.cgColor
    let foregroundColor = NSUIColor.white.cgColor
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        
        // SCALE_FACTOR changes the requested font size for the new layer.
        // OBSERVATION: Setting this value higher creates a smoother font image
        // HYPOTHESIS: The font size is used to determine the size of a bitmap
        //              or canvas to which the layer is drawn
        let SCALE_FACTOR: CGFloat = 16
        let wordSize = String(key.word).fontedSize
        let wordSizeScaled = CGSize(width: wordSize.width * SCALE_FACTOR,
                                    height: wordSize.height * SCALE_FACTOR)
        
        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.foregroundColor = key.foreground.cgColor
        textLayer.alignmentMode = .left
        textLayer.string = "\(key.word)"
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
