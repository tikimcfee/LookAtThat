//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

class GlyphLayerCache: LockingCache<GlyphCacheKey, SizedText> {
    
    let glyphBuilder = GlyphBuilder()
    
    override func make(
        _ key: GlyphCacheKey,
        _ store: inout [GlyphCacheKey: SizedText]
    ) -> Value {
        return glyphBuilder.makeGlyph(key)
    }
    
    func diffuseMaterial(_ any: Any?) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = any
        return material
    }
}
