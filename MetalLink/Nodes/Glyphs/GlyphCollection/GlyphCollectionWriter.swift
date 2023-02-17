//
//  GlyphCollectionWriter.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/14/22.
//

import Foundation

struct GlyphCollectionWriter {
    private static let locked_worker = DispatchQueue(label: "WriterWritingWritely", qos: .userInteractive)
    
    let target: GlyphCollection
    var linkAtlas: MetalLinkAtlas { target.linkAtlas }
    
    // TODO: Add a 'render all of this' function to avoid
    // potentially recreating the buffer hundreds of times.
    // Buffer *should* only reset when the texture is called,
    // but that's a fragile guarantee.
    func addGlyph(
        _ key: GlyphCacheKey,
        _ action: (GlyphNode, inout InstancedConstants) -> Void
    ) {
        Self.locked_worker.sync {
            doAddGlyph(key, action)
        }
    }
    
    private func doAddGlyph(
        _ key: GlyphCacheKey,
        _ action: (GlyphNode, inout InstancedConstants) -> Void
    ) {
        guard let newGlyph = linkAtlas.newGlyph(key) else {
            print("No glyph for", key)
            return
        }
        
        newGlyph.parent = target
        target.instanceState.appendToState(
            node: newGlyph
        )
        
        do {
            try target.instanceState.makeAndUpdateConstants { constants in
                if let cachedPair = linkAtlas.uvPairCache[key] {
                    constants.textureDescriptorU = cachedPair.u
                    constants.textureDescriptorV = cachedPair.v
                } else {
                    print("--------------")
                    print("MISSING UV PAIR")
                    print("\(key.glyph)")
                    print("--------------")
                }
                
                target.instanceState.instanceIdNodeLookup[constants.instanceID] = newGlyph
                newGlyph.meta.instanceBufferIndex = constants.arrayIndex
                newGlyph.meta.instanceID = constants.instanceID
                target.renderer.insert(newGlyph, &constants)
                action(newGlyph, &constants)
            }
        } catch {
            print(error)
            return
        }
    }
}
