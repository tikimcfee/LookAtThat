//
//  GlyphLayer+macOS.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import CoreServices
import SceneKit

extension CALayer {
    var cgSize: CGSize {
        CGSize(width: frame.width, height: frame.height)
    }
    
    func getBitmapImage(
        using key: GlyphCacheKey
    ) -> (requested: NSUIImage, template: NSUIImage)? {
        guard let requested = defaultRepresentation(),
              let template = defaultRepresentation() else {
            return nil
        }
        
        guard let requestedContext = NSGraphicsContext(bitmapImageRep: requested),
              let templateContext = NSGraphicsContext(bitmapImageRep: template) else {
            return nil
        }
        
        backgroundColor = key.background.cgColor
        render(in: requestedContext.cgContext)
        
        backgroundColor = NSUIColor.green.cgColor
        render(in: templateContext.cgContext)
        
        guard let requestedImage = requestedContext.cgContext.makeImage(),
              let templateImage = templateContext.cgContext.makeImage() else {
            return nil
        }
        
        return (
            NSImage(cgImage: requestedImage,size: cgSize),
            NSImage(cgImage: templateImage,size: cgSize)
        )
    }
    
    func compressedJpegRepresentation(
        from source: NSBitmapImageRep,
        using key: GlyphCacheKey
    ) -> (requested: NSBitmapImageRep?, template: NSBitmapImageRep?) {
        let requestedJpegBitmap: NSBitmapImageRep? = source
            .representation(using: .jpeg, properties: [.fallbackBackgroundColor: key.background])
            .flatMap { NSBitmapImageRep(data: $0) }
        
        let templateJpegBitmap: NSBitmapImageRep? = source
            .representation(using: .jpeg, properties: [.fallbackBackgroundColor: NSUIColor.clear])
            .flatMap { NSBitmapImageRep(data: $0) }
        
        return (requestedJpegBitmap, templateJpegBitmap)
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
}
