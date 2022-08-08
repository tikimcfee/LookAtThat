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
        
        guard let bitmapImages = textLayer.getBitmapImage(using: key) else {
            print("Could not create bitmap glyphs for \(key)")
            return (keyPlane, templatePlane, descaledSize)
        }
        
        let (requested, _, template, _) = bitmapImages
        keyPlane.firstMaterial?.diffuse.contents = requested
        templatePlane.firstMaterial?.diffuse.contents = template
        
//        let (_, requestedCG, _, templateCG) = bitmapImages
//        let texture = try! Self.loader.newTexture(cgImage: requestedCG)
//        let imageProperty = SCNMaterialProperty(contents: texture)
//        keyPlane.firstMaterial?.setValue(imageProperty, forKey: MetalLink_Glyphy_DiffuseName_Q)
//        keyPlane.firstMaterial?.program = bridge.defaultSceneProgram
//        templatePlane.firstMaterial?.setValue(imageProperty, forKey: MetalLink_Glyphy_DiffuseName_Q)
//        templatePlane.firstMaterial?.program = bridge.defaultSceneProgram
                
        return (keyPlane, templatePlane, descaledSize)
    }
}
