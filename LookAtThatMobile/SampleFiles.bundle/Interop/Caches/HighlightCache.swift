//
//  HighlightCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

class HighlightCache: LockingCache<SCNGeometry, SCNGeometry> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let highlighted = key.deepCopy()
        highlighted.firstMaterial?.diffuse.contents = NSUIColor.red
        store[highlighted] = key // reverse lookup to get back the original color
        return highlighted
    }
}
