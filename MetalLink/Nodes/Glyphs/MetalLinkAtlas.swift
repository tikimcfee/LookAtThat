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
    let nodeCache: MetalLinkGlyphNodeCache
    
    init(_ link: MetalLink) {
        self.link = link
        self.nodeCache = MetalLinkGlyphNodeCache(link: link)
    }
    
    private var sampleTexture: MTLTexture?
    func getSampleAtlas() -> MTLTexture? {
        if let texture = sampleTexture { return texture }
        guard let builder = makeBuilder() else { return nil }
        print("Making atlas")
        self.sampleTexture = MetalLinkAtlas.buildSampleAtlas(builder: builder)
        return sampleTexture
    }
}

extension MetalLinkAtlas {
    func newGlyph(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        nodeCache.create(key)
    }
}

private extension MetalLinkAtlas {
    func makeBuilder() -> AtlasBuilder? {
        do {
            return try AtlasBuilder(
                link,
                textureCache: nodeCache.textureCache,
                meshCache: nodeCache.meshCache
            )
        } catch {
            print(error)
            return nil
        }
    }
}

private extension MetalLinkAtlas {
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
