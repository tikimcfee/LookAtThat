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
    let nodeCache: MetalLinkGlyphNodeCache
    var uvPairCache = TextureUVCache()
    
    init(_ link: MetalLink) {
        self.link = link
        self.nodeCache = MetalLinkGlyphNodeCache(link: link)
    }
    
    private var sampleTexture: MTLTexture?
    func getSampleAtlas() -> MTLTexture? {
        if let texture = sampleTexture { return texture }
        guard let builder = makeBuilder() else { return nil }
        
        print("Making atlas")
        MetalLinkAtlas.buildSampleAtlas(builder: builder)
        (sampleTexture, uvPairCache) = builder.endAndCommitEncoding()
        
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

extension MetalLinkAtlas {
    static let sampleAtlasGlyphs = """
    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    1234567890 -_+=/
    !@#$%^&*()[]\\;',./{}|:"<>?
    """.components(separatedBy: .newlines).joined()
    
    static let sampleAtlasColors: [NSUIColor] = [
        .red, .green, .blue, .brown, .orange,
        .cyan, .magenta, .purple, .yellow,
        .systemPink, .systemTeal
    ]
    
    static let allSampleGlyphs = sampleAtlasColors
        .flatMap { color in
            sampleAtlasGlyphs.map { character in
                GlyphCacheKey(String(character), color)
            }
        }

    static func buildSampleAtlas(
        builder: AtlasBuilder
    ) {
        allSampleGlyphs.forEach {
            builder.addGlyph($0)
        }
    }
}
