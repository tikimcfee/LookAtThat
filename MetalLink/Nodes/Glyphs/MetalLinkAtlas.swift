//
//  MetalLinkAtlas.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/12/22.
//

import MetalKit

class MetalLinkAtlas {
    internal let link: MetalLink
    let texture: MTLTexture
    
    init(_ link: MetalLink) throws {
        self.link = link
        
        guard let atlas = Self.buildAtlas(link) else {
            throw MetalGlyphError.noTextures
        }
        
        self.texture = atlas
    }
}

extension MetalLinkAtlas: MetalLinkReader {
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
    
    static var block = """
    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    1234567890!@#$%^&*()
    []\\;',./{}|:"<>?
    """.components(separatedBy: .newlines).joined()
    
    static func buildAtlas(_ link: MetalLink) -> MTLTexture? {
        guard let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
              let atlasTexture = link.device.makeTexture(descriptor: canvasDescriptor)
        else { return nil }
        atlasTexture.label = "MetalLinkAtlas"
        
        // draw in rows
        let atlasSize = atlasTexture.simdSize
        let sourceOrigin = MTLOrigin()
        var targetOrigin = MTLOrigin()
        var lineTop: Int = 0
        var lineBottom: Int = 0
        var uvOffsetTop: Float = .zero
        var uvOffset: LFloat2 = .zero
        
        func updateOriginsAfterCopy(
            from bundle: MetalLinkGlyphTextureCache.Bundle,
            size bundleUVSize: LFloat2
        ) {
//            print("(\(bundle.texture.width), \(bundle.texture.height) -> (\(lineTop), \(lineBottom))")
            if bundle.textureIndex > 0 && bundle.textureIndex % (Self.glyphCount - 1) == 0 {
                targetOrigin.x = 0
                targetOrigin.y = lineBottom
                lineTop = lineBottom

                uvOffset.x = 0
                uvOffset.y += bundleUVSize.y
                uvOffsetTop = uvOffset.y
//                print("dropLine")
            } else {
                targetOrigin.x += bundle.texture.width
                lineBottom = max(lineBottom, lineTop + bundle.texture.height)
                
                uvOffset.x += bundleUVSize.x
                uvOffset.y = max(uvOffset.y, uvOffsetTop + bundleUVSize.y)
            }
//            let testMesh = link.meshes[.Quad] as! MetalLinkQuadMesh
//            testMesh.updateUVs(uvTopRight, uvTopLeft, uvBottomLeft, uvBottomRight)
            
//            print(testMesh.vertices)
//            print("--> (\(lineTop), \(lineBottom))")
//            print("uv: \(uvOffset)")
        }
        
        func atlasUVSize(for bundle: MetalLinkGlyphTextureCache.Bundle) -> LFloat2 {
            let bundleSize = bundle.texture.simdSize
            return LFloat2(bundleSize.x / atlasSize.x, bundleSize.y / atlasSize.y)
        }
        
        func addGlyph(_ key: GlyphCacheKey) {
            guard let textureBundle = link.linkNodeCache.textureCache[key] else {
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
            
            // Grab UV top left before updating; grab it again for right side
            let bundleUVSize = atlasUVSize(for: textureBundle)
            
            let uvTopLeft = uvOffset
            updateOriginsAfterCopy(from: textureBundle, size: bundleUVSize)
            let uvBottomRight = LFloat2(uvOffset.x, uvOffsetTop + bundleUVSize.y)
            let uvBottomLeft = LFloat2(uvTopLeft.x, uvBottomRight.y)
            let uvTopRight = LFloat2(uvBottomRight.x, uvTopLeft.y)
            
            link.linkNodeCache.meshCache[key]?.updateUVs(
                topRight: uvTopRight,
                topLeft: uvTopLeft,
                bottomLeft: uvBottomLeft,
                bottomRight: uvBottomRight
            )
        }
        
        let colors: [NSUIColor] = [
            .red, .green, .blue, .brown, .orange,
            .cyan, .magenta, .purple, .yellow, .systemMint,
            .systemPink, .systemTeal
        ]
        
        for color in colors {
            Self.block.map { GlyphCacheKey(String($0), color) }
                .forEach { addGlyph($0) }
        }
        
        addGlyph(GlyphCacheKey("\n", .red))
        
        blitEncoder.endEncoding()
        commandBuffer.commit()
        
        print("Atlas ready: \(atlasTexture.width) x \(atlasTexture.height)")
        return atlasTexture
    }
}
