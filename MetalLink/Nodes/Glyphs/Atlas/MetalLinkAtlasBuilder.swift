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

    var map = ConcurrentDictionary<GlyphCacheKey, Pair>()
    
    subscript(_ key: GlyphCacheKey) -> Pair? {
        get { map[key] }
        set { map[key] = newValue }
    }
}

class AtlasBuilder {
    private let link: MetalLink
    private let textureCache: MetalLinkGlyphTextureCache
    private let meshCache: MetalLinkGlyphNodeMeshCache
    
    let atlasTexture: MTLTexture
    private lazy var atlasSize: LFloat2 = atlasTexture.simdSize
    
    private lazy var uvPacking = AtlasPacking<UVRect>(width: 1.0, height: 1.0)
    private lazy var vertexPacking = AtlasPacking<VertexRect>(width: atlasTexture.width, height: atlasTexture.height)
    private var uvPairCache: TextureUVCache = TextureUVCache()
    
    private let sourceOrigin = MTLOrigin()
    private var targetOrigin = MTLOrigin()
    
    init(
        _ link: MetalLink,
        textureCache: MetalLinkGlyphTextureCache,
        meshCache: MetalLinkGlyphNodeMeshCache
    ) throws {
        guard let atlasTexture = link.device.makeTexture(descriptor: Self.canvasDescriptor)
        else { throw LinkAtlasError.noTargetAtlasTexture }
        
        self.link = link
        self.textureCache = textureCache
        self.meshCache = meshCache
        self.atlasTexture = atlasTexture
        
        atlasTexture.label = "MetalLinkAtlas"
    }
}

extension AtlasBuilder {
    struct BuildBlock {
        let commandBuffer: MTLCommandBuffer
        let blitEncoder: MTLBlitCommandEncoder
        let atlasTexture: MTLTexture
        
        static func start(
            with link: MetalLink,
            targeting atlasTexture: MTLTexture
        ) throws -> BuildBlock {
            guard let commandBuffer = link.commandQueue.makeCommandBuffer(),
                  let blitEncoder = commandBuffer.makeBlitCommandEncoder()
            else { throw LinkAtlasError.noStateBuilder }
            
            let id = Self.NEXT_ID()
            commandBuffer.label = "AtlasBuilderCommands-\(id)"
            blitEncoder.label = "AtlasBuilderBlitter-\(id)"
            
            return BuildBlock(
                commandBuffer: commandBuffer,
                blitEncoder: blitEncoder,
                atlasTexture: atlasTexture
            )
        }
        
        private static var _MY_ID = 0
        private static func NEXT_ID() -> Int {
            let id = _MY_ID
            _MY_ID += 1
            return id
        }
    }
}
    
extension AtlasBuilder {
    typealias UpdatedAtlas = (
        atlas: MTLTexture,
        uvCache: TextureUVCache
    )
    
    func startAtlasUpdate() throws -> BuildBlock {
        try BuildBlock.start(with: link, targeting: atlasTexture)
    }
    
    func finishAtlasUpdate(from block: BuildBlock) -> UpdatedAtlas {
        block.blitEncoder.endEncoding()
        block.commandBuffer.commit()
        return (atlasTexture, uvPairCache)
    }
    
    func addGlyph(
        _ key: GlyphCacheKey,
        _ block: BuildBlock
    ) {
        guard let textureBundle = textureCache[key] else {
            print("Missing texture for \(key)")
            return
        }
        
        // Set Vertex and UV info for packing
        let bundleUVSize = atlasUVSize(for: textureBundle)
        let uvRect = UVRect()
        uvRect.width = bundleUVSize.x
        uvRect.height = bundleUVSize.y
        
        let vertexRect = VertexRect()
        vertexRect.width = textureBundle.texture.width
        vertexRect.height = textureBundle.texture.height
        
        // Pack it; Update origin from rect position
        uvPacking.packNextRect(uvRect)
        vertexPacking.packNextRect(vertexRect)
        targetOrigin.x = vertexRect.x
        targetOrigin.y = vertexRect.y
        
        // Ship it; Encode with current state
        encodeBlit(for: textureBundle.texture, with: block)
        
        // Compute UV corners for glyph
        let (left, top, width, height) = (
            uvRect.x, uvRect.y,
            bundleUVSize.x, bundleUVSize.y
        )

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
    
    func encodeBlit(
        for texture: MTLTexture,
        with block: BuildBlock
    ) {
        let textureSize = MTLSize(width: texture.width, height: texture.height, depth: 1)
        
        block.blitEncoder.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: sourceOrigin,
            sourceSize: textureSize,
            to: atlasTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: targetOrigin
        )
    }
}

private extension AtlasBuilder {
    func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
        let bundleSize = bundle.texture.simdSize
        return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
    }
}

extension AtlasBuilder {
    static var canvasSize = LInt2(4096, 4096)
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
