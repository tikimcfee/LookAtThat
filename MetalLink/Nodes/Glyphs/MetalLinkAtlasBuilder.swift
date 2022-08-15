//
//  MetalLinkAtlasBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

typealias TextureUVCache = [GlyphCacheKey: TextureUVPair]
struct TextureUVPair {
    let u: LFloat4
    let v: LFloat4
}

class AtlasBuilder {
    private let link: MetalLink
    private let textureCache: MetalLinkGlyphTextureCache
    private let meshCache: MetalLinkGlyphNodeMeshCache
    private let commandBuffer: MTLCommandBuffer
    private let blitEncoder: MTLBlitCommandEncoder
    
    private let atlasPointer = AtlasPointer()
    private let atlasTexture: MTLTexture
    private var uvPairCache: TextureUVCache = [:]
    
    private lazy var atlasSize: LFloat2 = {
        atlasTexture.simdSize
    }()
    
    init(
        _ link: MetalLink,
        textureCache: MetalLinkGlyphTextureCache,
        meshCache: MetalLinkGlyphNodeMeshCache
    ) throws {
        guard let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
              let atlasTexture = link.device.makeTexture(descriptor: Self.canvasDescriptor)
        else { throw LinkAtlasError.noStateBuilder }
        
        self.link = link
        self.textureCache = textureCache
        self.meshCache = meshCache
        self.commandBuffer = commandBuffer
        self.blitEncoder = blitEncoder
        self.atlasTexture = atlasTexture
        
        commandBuffer.label = "AtlasBuilderCommands"
        blitEncoder.label = "AtlasBuilderBlitter"
        atlasTexture.label = "MetalLinkAtlas"
    }
    
    func endAndCommitEncoding() -> (
        atlas: MTLTexture,
        uvCache: TextureUVCache
    ) {
        blitEncoder.endEncoding()
        commandBuffer.commit()
        
        return (atlasTexture, uvPairCache)
    }
}

extension AtlasBuilder {
    func addGlyph(_ key: GlyphCacheKey) {
//        print("Adding glyph: \(key.glyph), red=\(key.foreground == NSUIColor.red)")
        
        guard let textureBundle = textureCache[key] else {
            print("Missing texture for \(key)")
            return
        }
        
        let glyph = textureBundle.texture
        let size = MTLSize(width: glyph.width, height: glyph.height, depth: 1)
        
        blitEncoder.copy(
            from: textureBundle.texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: atlasPointer.sourceOrigin,
            sourceSize: size,
            to: atlasTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: atlasPointer.targetOrigin
        )
        let bundleUVSize = atlasUVSize(for: textureBundle)
        let boundingBox = atlasPointer.advance(from: textureBundle, size: bundleUVSize)
        let (left, top, width, height) = (boundingBox.x, boundingBox.y, boundingBox.z, boundingBox.w)
        
        let topLeft = LFloat2(left, top)
        let bottomLeft = LFloat2(left, top + height)
        let topRight = LFloat2(left + width, top)
        let bottomRight = LFloat2(left + width, top + height)
        
        uvPairCache[key] = TextureUVPair(
            u: LFloat4(topRight.x, topLeft.x, bottomLeft.x, bottomRight.x),
            v: LFloat4(topRight.y, topLeft.y, bottomLeft.y, bottomRight.y)
        )

//        print("---------------")
//        print("post update: \(key.glyph)")
//        print("---------------")
    }
    
    func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
        let bundleSize = bundle.texture.simdSize
        return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
    }
}

extension AtlasBuilder {
    static var glyphCount: Int = 64
    static var glyphSizeEstimate = LInt2(15, 25) // about (13, 23)
    static var canvasSize = LInt2(glyphSizeEstimate.x * glyphCount, glyphSizeEstimate.y * glyphCount)
    static var canvasDescriptor: MTLTextureDescriptor = {
        let glyphDescriptor = MTLTextureDescriptor()
        glyphDescriptor.storageMode = .private
        glyphDescriptor.textureType = .type2D
        glyphDescriptor.pixelFormat = .rgba8Unorm
        
        // TODO: Optimized behavior clears 'empty' backgrounds
        // We don't want this: spaces count, and they're colored.
        // Not sure what we lose with this.. but we'll see.
        glyphDescriptor.allowGPUOptimizedContents = false
        
        glyphDescriptor.width = canvasSize.x
        glyphDescriptor.height = canvasSize.y
        return glyphDescriptor
    }()
}

class AtlasPointer {
    private typealias Bundle = MetalLinkGlyphTextureCache.Bundle
    
    private let maxWidthGlyphIndex = AtlasBuilder.glyphCount - 1
    
    private class UV {
        var maxBottom: Float = .zero
        var offset: LFloat2 = .zero
    }
    
    private class Vertex {
        var lineTop: Int = 0
        var lineBottom: Int = 0
    }
    
    let sourceOrigin = MTLOrigin()
    var targetOrigin = MTLOrigin()
    
    private let uv = UV()
    private let vertex = Vertex()
    
    func advance(
        from bundle: MetalLinkGlyphTextureCache.Bundle,
        size uvSize: LFloat2
    ) -> LFloat4 {
        let newLine = bundle.textureIndex > 0
                   && bundle.textureIndex % maxWidthGlyphIndex == 0
        
        var bounds = LFloat4()
        bounds.z = uvSize.x
        bounds.w = uvSize.y

        if newLine {
            // Move to next line;
            targetOrigin.x = 0
            targetOrigin.y = vertex.lineBottom
            vertex.lineTop = vertex.lineBottom
            
            // Update offsets
            bounds.x = 0
            bounds.y = uv.maxBottom
            
            uv.offset.x = 0
            uv.offset.y = uv.maxBottom
            uv.maxBottom = uv.offset.y
        } else {
            // Place directly to right of last position
            targetOrigin.x += bundle.texture.width
            vertex.lineBottom = max(vertex.lineBottom, vertex.lineTop + bundle.texture.height)
            
            bounds.x = uv.offset.x
            bounds.y = uv.offset.y
            
            uv.offset.x += uvSize.x
//            uv.offset.y = max(uv.maxBottom, uvSize.y)
            uv.maxBottom = max(uv.maxBottom, uv.offset.y + uvSize.y)
        }
        
        return bounds
        /* (left, top, width, height) */
//        return LFloat4(
//            uvStartOffset.x,
//            uv.maxBottom,
//            bundleUVSize.x,
//            bundleUVSize.y
//        )
    }
}
