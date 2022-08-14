//
//  MetalLinkAtlas.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/12/22.
//

import MetalKit

enum LinkAtlasError: Error {
    case noStateBuilder
}

class MetalLinkAtlas {
    private let link: MetalLink
    private let nodeCache: MetalLinkGlyphNodeCache
    
    let texture: MTLTexture
    
    init(_ link: MetalLink) throws {
        self.link = link
        self.nodeCache = MetalLinkGlyphNodeCache(link: link)
        let builder = try AtlasBuilder(
            link,
            textureCache: nodeCache.textureCache, // wait.. this works!?
            meshCache: nodeCache.meshCache        // is it... allowing self usage.. because it knows atlasCache is initialized?
        
        )
        self.texture = MetalLinkAtlas.buildSampleAtlas(builder: builder)
    }
}

extension MetalLinkAtlas {
    static var sampleBlock = """
    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    1234567890!@#$%^&*()
    []\\;',./{}|:"<>?
    """.components(separatedBy: .newlines).joined()

    static func buildSampleAtlas(
        builder: AtlasBuilder
    ) -> MTLTexture {
        let colors: [NSUIColor] = [
            .red, .green, .blue, .brown, .orange,
            .cyan, .magenta, .purple, .yellow, .systemMint,
            .systemPink, .systemTeal
        ]
        
        for color in colors {
            for character in sampleBlock {
                let key = GlyphCacheKey(String(character), color)
                builder.addGlyph(key)
            }
        }
        
        builder.endAndCommitEncoding()
        print("Atlas ready: \(builder.atlasSize.x) x \(builder.atlasSize.y)")
        
        return builder.atlasTexture
    }
}
