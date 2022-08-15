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
    private let sourceOrigin = MTLOrigin()
    private var targetOrigin = MTLOrigin()
    private var lineTop: Int = 0
    private var lineBottom: Int = 0
    private var uvOffsetTop: Float = .zero
    private var uvOffset: LFloat2 = .zero
    
    private let maxWidthGlyphIndex = AtlasBuilder.glyphCount - 1
    
    private let link: MetalLink
    private let textureCache: MetalLinkGlyphTextureCache
    private let meshCache: MetalLinkGlyphNodeMeshCache
    private let commandBuffer: MTLCommandBuffer
    private let blitEncoder: MTLBlitCommandEncoder
    
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
        print("Adding glyph: \(key.glyph), red=\(key.foreground == NSUIColor.red)")
        
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
        let boundingBox = advanceUVOffsets(from: textureBundle, size: bundleUVSize)
        let (left, top, width, height) = (boundingBox.x, boundingBox.y, boundingBox.z, boundingBox.w)
        
        let topLeft = LFloat2(left, top)
        let bottomLeft = LFloat2(left, top + height)
        let topRight = LFloat2(left + width, top)
        let bottomRight = LFloat2(left + width, top + height)
        
        uvPairCache[key] = TextureUVPair(
            u: LFloat4(topRight.x, topLeft.x, bottomLeft.x, bottomRight.x),
            v: LFloat4(topRight.y, topLeft.y, bottomLeft.y, bottomRight.y)
        )

        print("---------------")
        print("post update: \(key.glyph)")
        print("---------------")
    }
    
    func advanceUVOffsets(
        from bundle: MetalLinkGlyphTextureCache.Bundle,
        size bundleUVSize: LFloat2
    ) -> LFloat4 {
        let uvStartOffset = uvOffset
        let newLine = bundle.textureIndex > 0
            && bundle.textureIndex % maxWidthGlyphIndex == 0
        
        if newLine {
            // Move to next line;
            targetOrigin.x = 0
            targetOrigin.y = lineBottom
            lineTop = lineBottom
            
            // Update offsets
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
        
        /* (left, top, width, height) */
        return LFloat4(
            uvStartOffset.x,
            uvOffsetTop,
            bundleUVSize.x,
            bundleUVSize.y
        )
    }
    
    func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
        let bundleSize = bundle.texture.simdSize
        return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
    }
}

extension AtlasBuilder {
    static var glyphCount: Int = 64
    static var glyphSizeEstimate = LInt2(14, 24) // about (13, 23)
    static var canvasSize = LInt2(glyphSizeEstimate.x * glyphCount, glyphSizeEstimate.y * 32)
    static var canvasDescriptor: MTLTextureDescriptor = {
        let glyphDescriptor = MTLTextureDescriptor()
        glyphDescriptor.storageMode = .private
        glyphDescriptor.textureType = .type2D
        glyphDescriptor.pixelFormat = .rgba8Unorm
        glyphDescriptor.width = canvasSize.x
        glyphDescriptor.height = canvasSize.y
        return glyphDescriptor
    }()
}
