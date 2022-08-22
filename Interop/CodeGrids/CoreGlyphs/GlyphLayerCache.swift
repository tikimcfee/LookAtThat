//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

public struct GlyphCacheKey: Hashable, Equatable {
    public let source: Character
    public let glyph: String
    public let foreground: NSUIColor
    public let background: NSUIColor
    
    public init(source: Character,
                _ foreground: NSUIColor,
                _ background: NSUIColor = NSUIColor.black) {
        self.source = source
        self.glyph = String(source)
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
