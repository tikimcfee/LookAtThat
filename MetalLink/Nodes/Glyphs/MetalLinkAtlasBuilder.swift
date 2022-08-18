//
//  MetalLinkAtlasBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

class TextureUVCache {
    struct Pair {
        let u: LFloat4
        let v: LFloat4
    }

    var map = [GlyphCacheKey: Pair]()
    
    subscript(_ key: GlyphCacheKey) -> Pair? {
        get { map[key] }
        set { map[key] = newValue }
    }
}

class AtlasBuilder {
    private let link: MetalLink
    private let textureCache: MetalLinkGlyphTextureCache
    private let meshCache: MetalLinkGlyphNodeMeshCache
    private let commandBuffer: MTLCommandBuffer
    private let blitEncoder: MTLBlitCommandEncoder
    private var uvPairCache: TextureUVCache = TextureUVCache()
    
    private let atlasTexture: MTLTexture
    private lazy var atlasPointer = AtlasPointer(atlasTexture)
    private lazy var atlasSize: LFloat2 = atlasTexture.simdSize
    
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
}

extension AtlasBuilder {
    func addGlyph(_ key: GlyphCacheKey) {
        guard let textureBundle = textureCache[key] else {
            print("Missing texture for \(key)")
            return
        }
        
        // Grab UV info, and allow check to update offsets
        let bundleUVSize = atlasUVSize(for: textureBundle)
        atlasPointer.willEncode(bundle: textureBundle, size: bundleUVSize)
        
        // Encode with current state
        encodeBlit(for: textureBundle.texture)
        
        // Update next proposed draw position and UV offsets
        let boundingBox = atlasPointer.updateBlitOffsets(from: textureBundle, size:  bundleUVSize)
        let (left, top, width, height) = (boundingBox.x, boundingBox.y, boundingBox.z, boundingBox.w)

        // Create UV pair matching glyph's texture position
        let topLeft = LFloat2(left, top)
        let bottomLeft = LFloat2(left, top + height)
        let topRight = LFloat2(left + width, top)
        let bottomRight = LFloat2(left + width, top + height)
        
        // You will see this a lot:
        // (x = left, y = top, z = width, w = height)
        uvPairCache[key] = TextureUVCache.Pair(
            u: LFloat4(topRight.x, topLeft.x, bottomLeft.x, bottomRight.x),
            v: LFloat4(topRight.y, topLeft.y, bottomLeft.y, bottomRight.y)
        )
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

private extension AtlasBuilder {
    func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
        let bundleSize = bundle.texture.simdSize
        return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
    }
    
    func encodeBlit(for texture: MTLTexture) {
        let textureSize = MTLSize(width: texture.width, height: texture.height, depth: 1)
        blitEncoder.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: atlasPointer.sourceOrigin,
            sourceSize: textureSize,
            to: atlasTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: atlasPointer.targetOrigin
        )
    }
}

extension AtlasBuilder {
    static var canvasSize = LInt2(5024, 5024)
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

    // TODO: Use a 'last bounds' for these to make sure we translate
    // relative to that. This is only working because all the glyphs
    // have the same size.
    private class UV {
        var uvBottom: Float = .zero
        var placementOffset: LFloat2 = .zero
        var placedFirst = false
    }
    
    private class Vertex {
        var vertexBottom: Int = 0
    }
    
    let sourceOrigin = MTLOrigin()
    var targetOrigin = MTLOrigin()
    
    private let uv = UV()
    private let vertex = Vertex()
    private let target: MTLTexture
    
    init(_ target: MTLTexture) {
        self.target = target
    }
    
    // Do line breaks / bottom positioning before draw.
    // Easy way to make sure the next drawn glyph and
    // UV's are reset if they don't fit current bounds.
    func willEncode(
        bundle: MetalLinkGlyphTextureCache.Bundle,
        size uvSize: LFloat2
    ) {
        let willDrawOutOfBounds = targetOrigin.x + bundle.texture.width >= target.width
        if  willDrawOutOfBounds {
            targetOrigin.x = 0
            targetOrigin.y = vertex.vertexBottom
            vertex.vertexBottom += bundle.texture.height
            
            uv.placementOffset.x = 0
            uv.placementOffset.y = uv.uvBottom
        }
        
        uv.uvBottom = max(uv.uvBottom, uv.placementOffset.y + uvSize.y)
        vertex.vertexBottom = max(vertex.vertexBottom, targetOrigin.y + bundle.texture.height)
    }
    
    // Bounds defines rectangular region.
    // targetOrigin defines top-left position of copy.
    func updateBlitOffsets(
        from bundle: MetalLinkGlyphTextureCache.Bundle,
        size uvSize: LFloat2
    ) -> LFloat4 {
        var newGlyphUVBounds = LFloat4()
        newGlyphUVBounds.z = uvSize.x // z == width
        newGlyphUVBounds.w = uvSize.y // w == height
        newGlyphUVBounds.y = uv.placementOffset.y
        
        // Don't update _new_ offsets if this is the first draw.
        // We want our first offsets to be 0. Subsequent calls
        // will get the proper left-x position.
        // Not pretty, but it works.
        if uv.placedFirst {
            let nextUVOffsetX = uvSize.x + uv.placementOffset.x
            newGlyphUVBounds.x = nextUVOffsetX
            uv.placementOffset.x += uvSize.x
        } else {
            uv.placedFirst = true
        }
        
        targetOrigin.x += bundle.texture.width
        
        return newGlyphUVBounds
    }
}


