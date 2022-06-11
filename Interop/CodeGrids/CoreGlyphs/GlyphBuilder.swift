//
//  GlyphBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import SceneKit

public typealias SizedText = (
    SCNGeometry, // colorized text
    SCNGeometry, // 'highlight' style text
    CGSize       // computed size of text
)

/**
 
 Ok so the theory is, based on the Metal GPU render snapshot, that the CPU is creating these images and memory is being shared.
 Ideally, if I could get this glyph stored to a url, I could create a texture that directly references it instead, and let the GPU sort our access
 to said memory.
 
 This shouldn't be that hard, actually.
 
 What I'll do is use the cache-key as a flat file name for a glyph's image data.
 Then, I'll render the glyph as normal, and write the result images to disk. Literally a slower font cache.
 Then, use something like MetalPetal (ohhhh please...) to load the resource from disk,
 and allow the memory mode to map directly without shared management.
 
 This... could... work.
 
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 I just need to use Metal directly and do shader stuff.
 Loading textures just isn't working at my level. MetalPetal seems to be mostly filter based. It's fast and works,
 but doesn't do what I need it to.
 
 I also disovered I can just write to a URL directly and load from it. It's.. faster to load. Seriously.
 Rendering is still not there yet. But yeah, it is a faster load. It's cool. At least, I think it is.
 
 */

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
        textLayer.display() // Try to get the layer content to update manually. Docs say not to do it;
                            // experimentally, it fills the backing content properly and can be used immediately
        
        // Resize the final layer according to descale factor
        let descaledSize = fontRenderer.descale(textLayer.frame.size)
        let keyPlane = SCNPlane(width: descaledSize.width, height: descaledSize.height)
        let templatePlane = SCNPlane(width: descaledSize.width, height: descaledSize.height)
        
        guard let (requested, template) = textLayer.getBitmapImage(using: key) else {
            print("Could not create bitmap glyphs for \(key)")
            return (keyPlane, templatePlane, descaledSize)
        }
        
//        let wrapper = MaterialWrapper(requested, template)
        keyPlane.firstMaterial?.diffuse.contents = requested
        templatePlane.firstMaterial?.diffuse.contents = template
        
        return (keyPlane, templatePlane, descaledSize)
    }
}
