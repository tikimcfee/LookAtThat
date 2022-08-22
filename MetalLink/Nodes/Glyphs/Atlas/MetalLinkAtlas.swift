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
    
    private var _sampleTexture: MTLTexture?
    func getSampleAtlas() -> MTLTexture? {
        if let texture = _sampleTexture { return texture }
        
        print("Making sample atlas")
        do {
            let block = try builder.startAtlasUpdate()
            Self.allSampleGlyphs.forEach { glyph in
                builder.addGlyph(glyph, block) // TODO: make the block the insert call point?
            }
            (_sampleTexture, uvPairCache) = builder.finishAtlasUpdate(from: block)
            return _sampleTexture
        } catch {
            print(error)
            return _sampleTexture
        }
    }
}

extension MetalLinkAtlas {
    func newGlyph(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        addGlyphToAtlasIfMissing(key)
        return nodeCache.create(key)
    }
    
    private func addGlyphToAtlasIfMissing(_ key: GlyphCacheKey) {
        guard uvPairCache[key] == nil else { return }
        print("Adding glyph to Atlas: [\(key.glyph)]")
        do {
            let block = try builder.startAtlasUpdate()
            builder.addGlyph(key, block)
            (_sampleTexture, uvPairCache) = builder.finishAtlasUpdate(from: block)
        } catch {
            print(error)
        }
    }
}

extension MetalLinkAtlas {
    static let sampleAtlasGlyphs = """
    ABCDEFGHIJ🥸KLMNOPQRSTUVWXYZ
    abcdefghijkl🤖mnopqrstuvwxyz
    12345🙀67890 -_+=/👾
    !@#$%^&*()[]\\;',./{}|:"<>?
    """.components(separatedBy: .newlines).joined()
    
//    static let sampleAtlasGlyphs = ["ش"]
    
    static let sampleAtlasColors: [NSUIColor] = [
        .red, .green, .blue, .brown, .orange,
        .cyan, .magenta, .purple, .yellow,
        .systemPink, .systemTeal, .gray
    ]
    
    static let allSampleGlyphs = sampleAtlasColors
        .flatMap { color in
            sampleAtlasGlyphs.map { character in
                GlyphCacheKey(String(character), color)
            }
        }
}
