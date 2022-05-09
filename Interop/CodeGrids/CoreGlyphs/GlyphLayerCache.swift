//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

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
    
    let glyphBuilder = GlyphBuilder()
    
    override func make(_ key: GlyphCacheKey, _ store: inout [GlyphCacheKey: SizedText]) -> Value {
        return glyphBuilder.makeGlyph(key)
    }
    
    func diffuseMaterial(_ any: Any?) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = any
        return material
    }
}
