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
    static var glyphCount: Float = 128
    static var glyphSizeEstimate = LFloat2(14.0, 24.0) // about (13, 23)
    static var canvasSize = LInt2(glyphSizeEstimate * glyphCount)
    static var canvasDescriptor: MTLTextureDescriptor = {
        let glyphDescriptor = MTLTextureDescriptor()
        glyphDescriptor.textureType = .type2D
        glyphDescriptor.pixelFormat = .rgba8Unorm
        glyphDescriptor.width = canvasSize.x
        glyphDescriptor.height = canvasSize.y
        return glyphDescriptor
    }()
    
    static func buildAtlas(_ link: MetalLink) -> MTLTexture? {
        guard let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
              let atlasTexture = link.device.makeTexture(descriptor: canvasDescriptor)
        else { return nil }
        atlasTexture.label = "MetalLinkAtlas"
        
        print("Atlas ready: \(atlasTexture.width) x \(atlasTexture.height)")
        
        let block = """
        ABCDEFGHIJKLMNOPQRSTUVWXYZ
        abcdefghijklmnopqrstuvwxyz
        1234567890!@#$%^&*()
        []\\;',./{}|:"<>?
        """.components(separatedBy: .newlines).joined()
        
        let sourceOrigin = MTLOrigin()
        var targetOrigin = MTLOrigin()
        
        // draw in rows
        var lineTop: Int = 0
        var lineBottom: Int = 0
        
        func updateOriginsAfterCopy(from bundle: MetalLinkGlyphTextureCache.Bundle) {
//            print("(\(bundle.texture.width), \(bundle.texture.height) -> (\(lineTop), \(lineBottom))")
            if bundle.textureIndex > 0 && bundle.textureIndex % 127 == 0 {
                targetOrigin.x = 0
                targetOrigin.y = lineBottom
                lineTop = lineBottom
//                print("dropLine")
            } else {
                targetOrigin.x += bundle.texture.width
                lineBottom = max(lineBottom, lineTop + bundle.texture.height)
            }
//            print("--> (\(lineTop), \(lineBottom))")
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
            
            updateOriginsAfterCopy(from: textureBundle)
        }
        
        let colors: [NSUIColor] = [
            .red, .green, .blue, .brown, .orange,
            .cyan, .magenta, .purple, .yellow, .systemMint,
            .systemPink, .systemTeal
        ]
        
        for color in colors {
            block.map { GlyphCacheKey(String($0), color) }
                .forEach { addGlyph($0) }
        }
        
        addGlyph(GlyphCacheKey("\n", .red))
        
        blitEncoder.endEncoding()
        commandBuffer.commit()
        
        print("Atlas Created")
        return atlasTexture
    }
}
