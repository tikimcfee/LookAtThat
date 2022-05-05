//
//  GlyphBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import SceneKit

class GlyphBuilder {
    let fontRenderer = FontRenderer.shared
    
    func makeGlyph(_ key: GlyphCacheKey) -> SizedText {
        let safeString = key.glyph
        let (_, wordSizeScaled) = fontRenderer.measure(safeString)
        
        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.foregroundColor = key.foreground.cgColor
        textLayer.string = safeString
        textLayer.font = fontRenderer.unitFont
        textLayer.alignmentMode = .left
        textLayer.fontSize = wordSizeScaled.height
        textLayer.frame.size = textLayer.preferredFrameSize()
        
        // Resize the final layer according to descale factor
        let descaledSize = fontRenderer.descale(textLayer.frame.size)
        let boxPlane = SCNPlane(width: descaledSize.width, height: descaledSize.height)
        
        // Try to get the layer content to update manually. Docs say not to do it;
        // experimentally, it fills the backing content properly and can be used immediately
        textLayer.display()
        guard let (requested, _) = textLayer.getBitmapImage(using: key) else {
            print("Could not create bitmap glyphs for \(key)")
            return (boxPlane, descaledSize)
        }
        
//        let wrapper = MaterialWrapper(requested, template)
        boxPlane.firstMaterial?.diffuse.contents = requested
        
        return (boxPlane, descaledSize)
    }
}
