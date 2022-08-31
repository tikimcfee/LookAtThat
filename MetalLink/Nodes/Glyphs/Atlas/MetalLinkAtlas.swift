//
//  MetalLinkAtlas.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/12/22.
//

import MetalKit

enum LinkAtlasError: Error {
    case noTargetAtlasTexture
    case noStateBuilder
}

class MetalLinkAtlas {
    private let link: MetalLink
    private let builder: AtlasBuilder
    let nodeCache: MetalLinkGlyphNodeCache
    var uvPairCache: TextureUVCache
    var currentAtlas: MTLTexture { builder.atlasTexture }
    
    init(_ link: MetalLink) throws {
        self.link = link
        self.uvPairCache = TextureUVCache()
        self.nodeCache = MetalLinkGlyphNodeCache(link: link)
        self.builder = try AtlasBuilder(
            link,
            textureCache: nodeCache.textureCache,
            meshCache: nodeCache.meshCache
        )
    }
}

extension MetalLinkAtlas {
    func newGlyph(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        // TODO: Can't I just reuse the constants on the nodes themselves?
        addGlyphToAtlasIfMissing(key)
        let newNode = nodeCache.create(key)
        return newNode
    }
    
    private func addGlyphToAtlasIfMissing(_ key: GlyphCacheKey) {
        guard uvPairCache[key] == nil else { return }
//        print("Adding glyph to Atlas: [\(key.glyph)]")
        do {
            let block = try builder.startAtlasUpdate()
            builder.addGlyph(key, block)
            (_, uvPairCache) = builder.finishAtlasUpdate(from: block)
        } catch {
            print(error)
        }
    }
}

extension MetalLinkAtlas {
    // XCode doesn't handle these well either
//    static let sampleAtlasGlyphs = ["ش"]
}
