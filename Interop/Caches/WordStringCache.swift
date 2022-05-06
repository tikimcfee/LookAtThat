//
//  WordStringCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

class WordStringCache: LockingCache<String, SizedText> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let (word, color) = ("\(key)", NSUIColor.white)
        let textGeometry = SCNText(string: word, extrusionDepth: WORD_EXTRUSION_SIZE)
        textGeometry.font = kDefaultSCNTextFont
        textGeometry.firstMaterial?.diffuse.contents = color
        let sizedText = (textGeometry, textGeometry, String(key).fontedSize)
        return sizedText
    }
}
