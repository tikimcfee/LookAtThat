//
//  GlyphBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import SceneKit
import MetalKit

public typealias SizedText = (SCNGeometry, SCNGeometry, CGSize)

class GlyphBuilder {
    static let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    static let loader: MTKTextureLoader = MTKTextureLoader(device: device)
    
    let fontRenderer = FontRenderer.shared
    let bridge = MetalLinkNodeBridge()
    
    func makeGlyph(_ key: GlyphCacheKey) -> SizedText {
        let textLayer = makeTextLayer(key)
        
        // Resize the final layer according to descale factor
        let descaledSize = fontRenderer.descale(textLayer.frame.size)
        let keyPlane = SCNPlane(width: descaledSize.width, height: descaledSize.height)
        let templatePlane = SCNPlane(width: descaledSize.width, height: descaledSize.height)
        
        guard let bitmapImages = textLayer.getBitmapImage(using: key) else {
            print("Could not create bitmap glyphs for \(key)")
            return (keyPlane, templatePlane, descaledSize)
        }
        
        keyPlane.firstMaterial?.diffuse.contents = bitmapImages.requested
        templatePlane.firstMaterial?.diffuse.contents = bitmapImages.template
                
        return (keyPlane, templatePlane, descaledSize)
    }
    
    func makeBitmaps(_ key: GlyphCacheKey) -> BitmapImages? {
        let textLayer = makeTextLayer(key)
        return textLayer.getBitmapImage(using: key)
    }
    
    func makeTextLayer(_ key: GlyphCacheKey) -> CATextLayer {
        let safeString = key.glyph
        let (_, wordSizeScaled) = fontRenderer.measure(safeString)
        
        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.foregroundColor = key.foreground.cgColor
        textLayer.string = safeString
        textLayer.font = fontRenderer.renderingFont
        textLayer.alignmentMode = .left
        textLayer.fontSize = wordSizeScaled.height
        textLayer.frame.size = textLayer.preferredFrameSize()
        
        // Try to get the layer content to update manually. Docs say not to do it;
        // experimentally, it fills the backing content properly and can be used immediately
        textLayer.display()
        
        return textLayer
    }
}
