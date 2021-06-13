//
//  WordColorCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation

class WordColorCache: LockingCache<String, NSUIColor> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        return NSUIColor(
            displayP3Red: CGFloat(Float.random(in: 0...1)),
            green: CGFloat(Float.random(in: 0...1)),
            blue: CGFloat(Float.random(in: 0...1)),
            alpha: 1.0
        )
    }
}
