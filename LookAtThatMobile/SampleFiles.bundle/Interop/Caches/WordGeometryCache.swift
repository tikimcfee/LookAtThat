//
//  WordGeometryCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

class WordGeometryCache: LockingCache<Character, SizedText> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let (word, color) =
            key.isWhitespace
            ? (" ",     NSUIColor.clear)
            : ("\(key)", NSUIColor.white) // SCNText doesn't like some Characters
        
        let textGeometry = SCNText(string: word, extrusionDepth: WORD_EXTRUSION_SIZE)
        textGeometry.font = kDefaultSCNTextFont
        textGeometry.firstMaterial?.diffuse.contents = color
        
        let sizedText = (textGeometry, String(key).fontedSize)
        return sizedText
    }
}
