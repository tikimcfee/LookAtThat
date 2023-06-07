//
//  SemanticInfoMap+Sorting.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/28/22.
//

import Foundation
import MetalLink

extension SemanticInfoMap {
    func sortTopLeft(_ left: MetalLinkNode, _ right: MetalLinkNode) -> Bool {
        return left.position.y > right.position.y
        && left.position.x < right.position.x
    }
    
    func sortTuplesTopLeft(
        _ left: (SemanticInfo, SortedNodeSet),
        _ right: (SemanticInfo, SortedNodeSet)
    ) -> Bool {
        guard let left = left.1.first else { return false }
        guard let right = right.1.first else { return true }
        return sortTopLeft(left, right)
    }
}
