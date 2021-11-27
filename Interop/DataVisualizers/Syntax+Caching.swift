//
//  Syntax+Caching.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax


struct SyntaxCacheItem {
    let nodeEnum: SyntaxEnum
}

class SyntaxCache: LockingCache<Syntax, SyntaxCacheItem> {
    override func make(
        _ key: Syntax,
        _ store: inout [Syntax : SyntaxCacheItem]
    ) -> SyntaxCacheItem {
        return SyntaxCacheItem(
            nodeEnum: key.as(SyntaxEnum.self)
        )
    }
}

extension Syntax {
    private static let syntaxCache: SyntaxCache = SyntaxCache()
    
    var cachedType: SyntaxEnum {
        Self.syntaxCache[self].nodeEnum
    }
}
