//
//  Syntax+Caching.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax

class SyntaxCache {
    private var cache = NSMutableDictionary()
    subscript(key: Syntax) -> SyntaxEnum {
        get {
            if let item = cache[key.hashValue] as? SyntaxEnum {
                return item
            }
            let item = key.as(SyntaxEnum.self)
            cache[key.hashValue] = item
            return item
        }
        set { cache[key.hashValue] = newValue }
    }
}
