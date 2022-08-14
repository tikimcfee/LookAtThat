//
//  MetalLinkAtlasBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

class AtlasBuilder {
    let sourceOrigin = MTLOrigin()
    var targetOrigin = MTLOrigin()
    var lineTop: Int = 0
    var lineBottom: Int = 0
    var uvOffsetTop: Float = .zero
    var uvOffset: LFloat2 = .zero
    
    let maxWidthGlyphIndex = AtlasBuilder.glyphCount - 1
    
    let textureCache: MetalLinkGlyphTextureCache
    let meshCache: MetalLinkGlyphNodeMeshCache
    let commandBuffer: MTLCommandBuffer
    let blitEncoder: MTLBlitCommandEncoder
    let atlasTexture: MTLTexture
    lazy var atlasSize: LFloat2 = {
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
        
        self.textureCache = textureCache
        self.meshCache = meshCache
        self.commandBuffer = commandBuffer
        self.blitEncoder = blitEncoder
        self.atlasTexture = atlasTexture
        
        commandBuffer.label = "AtlasBuilderCommands"
        blitEncoder.label = "AtlasBuilderBlitter"
        atlasTexture.label = "MetalLinkAtlas"
    }
    
    func endAndCommitEncoding() {
        blitEncoder.endEncoding()
        commandBuffer.commit()
    }
}

extension AtlasBuilder {
    func addGlyph(_ key: GlyphCacheKey) {
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
            sourceOrigin: sourceOrigin,
            sourceSize: size,
            to: atlasTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: targetOrigin
        )
        let bundleUVSize = atlasUVSize(for: textureBundle)
        
        advanceUVOffsets(from: textureBundle, size: bundleUVSize)
        let uvTopLeft = uvOffset
        let uvBottomRight = LFloat2(uvOffset.x, uvOffsetTop + bundleUVSize.y)
        let uvBottomLeft = LFloat2(uvTopLeft.x, uvBottomRight.y)
        let uvTopRight = LFloat2(uvBottomRight.x, uvTopLeft.y)
        
        meshCache[key]?.updateUVs(
            topRight: uvTopRight,
            topLeft: uvTopLeft,
            bottomLeft: uvBottomLeft,
            bottomRight: uvBottomRight
        )
    }
    
    func advanceUVOffsets(
        from bundle: MetalLinkGlyphTextureCache.Bundle,
        size bundleUVSize: LFloat2
    ) {
        if bundle.textureIndex > 0 && bundle.textureIndex % maxWidthGlyphIndex == 0 {
            // Move to next line;
            targetOrigin.x = 0
            targetOrigin.y = lineBottom
            lineTop = lineBottom
            
            uvOffset.x = 0
            uvOffset.y += bundleUVSize.y
            uvOffsetTop = uvOffset.y
        } else {
            // Place directly to right of last position
            targetOrigin.x += bundle.texture.width
            lineBottom = max(lineBottom, lineTop + bundle.texture.height)
            
            uvOffset.x += bundleUVSize.x
            uvOffset.y = max(uvOffset.y, uvOffsetTop + bundleUVSize.y)
        }
    }
    
    func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
        let bundleSize = bundle.texture.simdSize
        return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
    }
}

extension AtlasBuilder {
    static var glyphCount: Int = 64
    static var glyphSizeEstimate = LInt2(14, 24) // about (13, 23)
    static var canvasSize = LInt2(glyphSizeEstimate.x * glyphCount, glyphSizeEstimate.y * glyphCount)
    static var canvasDescriptor: MTLTextureDescriptor = {
        let glyphDescriptor = MTLTextureDescriptor()
        glyphDescriptor.textureType = .type2D
        glyphDescriptor.pixelFormat = .rgba8Unorm
        glyphDescriptor.width = canvasSize.x
        glyphDescriptor.height = canvasSize.y
        return glyphDescriptor
    }()
}
