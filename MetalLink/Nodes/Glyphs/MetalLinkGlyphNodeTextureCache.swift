//
//  MetalLinkGlyphNodeTextureCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

private struct Size: Hashable, Equatable {
    let width: Int
    let height: Int
    init(_ bitmaps: BitmapImages) {
        self.width = bitmaps.requestedCG.width
        self.height = bitmaps.requestedCG.height
    }
    var text: String { "(\(width), \(height))" }
}

class MetalLinkGlyphTextureCache: LockingCache<GlyphCacheKey, MetalLinkGlyphTextureCache.Bundle?> {
    let link: MetalLink
    let bitmapCache: MetalLinkGlyphNodeBitmapCache
    private var sizes = Set<Size>()

    init(link: MetalLink) {
        self.link = link
        self.bitmapCache = MetalLinkGlyphNodeBitmapCache()
        super.init()
    }
    
    private var _makeTextureIndex: TextureIndex = 0
    private func nextTextureIndex() -> TextureIndex {
        let index = _makeTextureIndex
        _makeTextureIndex += 1
        return index
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        guard let bitmaps = bitmapCache[key]
        else { return nil }
        reportSize(Size(bitmaps))
        
        guard let glyphTexture = try? link.textureLoader.newTexture(
            cgImage: bitmaps.requestedCG,
            options: [.textureStorageMode: MTLStorageMode.private.rawValue]
        ) else { return nil}
        
        return Bundle(texture: glyphTexture, textureIndex: nextTextureIndex())
    }
    
    private func reportSize(_ size: Size) {
        let (inserted, _) = sizes.insert(size)
        if inserted {
            print("New glyph size reported: ", size.text)
        }
    }
}

extension MetalLinkGlyphTextureCache {
    struct Bundle: Equatable {
        let texture: MTLTexture
        let textureIndex: TextureIndex
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(textureIndex)
        }
        
        static func == (_ l: Bundle, _ r: Bundle) -> Bool {
            l.textureIndex == r.textureIndex
        }
    }
}
