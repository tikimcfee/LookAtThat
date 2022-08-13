//
//  MetalLinkNodeBitmapCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import Foundation

class MetalLinkGlyphNodeBitmapCache: LockingCache<GlyphCacheKey, BitmapImages?> {
    let builder = GlyphBuilder()
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        builder.makeBitmaps(key)
    }
}
