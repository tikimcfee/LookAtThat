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
    let layoutQueue = DispatchQueue(label: "WordLayerCache=\(UUID())", qos: .userInitiated, attributes: [.concurrent])
    
    let fontRenderer = FontRenderer.shared
    let backgroundColor = NSUIColor.black.cgColor
    let foregroundColor = NSUIColor.white.cgColor
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        // SCALE_FACTOR changes the requested font size for the new layer.
        // OBSERVATION: Setting this value higher creates a smoother font image
        // HYPOTHESIS: The font size is used to determine the size of a bitmap
        //              or canvas to which the layer is drawn
        let SCALE_FACTOR: CGFloat = 16
        let safeString = "\(key.word)"
        let wordSize = safeString.size(withAttributes:
            [.font: fontRenderer.font]
        )
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
            let bitmap = textLayer.getBitmapImage(using: GlyphCacheKey(key.word, NSUIColor.black))
            DispatchQueue.main.async {
                boxPlane.firstMaterial?.diffuse.contents = bitmap
            }
        }
        
        return (boxPlane, boxPlane, descaledSize)
    }
}
