//
//  CodeGridTokenCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import BitHandling
import MetalLink

// associate tokens to sets of nodes.
// { let nodesToUpdate = tracker[someToken] }
// - given a token, return the nodes that represent it
// - use that set to highlight, move, do stuff to

//typealias CodeGridNodes = Set<GlyphNode>
public typealias CodeGridNodes = [GlyphNode]
public class CodeGridTokenCache: LockingCache<String, CodeGridNodes> {
    public override func make(
        _ key: String,
        _ store: inout [String : CodeGridNodes]
    ) -> CodeGridNodes {
        laztrace(#fileID,#function,key,store)
        
        let set = CodeGridNodes()
        return set
    }
}
