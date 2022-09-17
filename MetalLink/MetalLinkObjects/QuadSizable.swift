//
//  QuadSizable.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/16/22.
//

import Foundation

protocol QuadSizable: AnyObject {
    var node: MetalLinkNode { get }
    var quad: MetalLinkQuadMesh { get set }
}

extension QuadSizable {
    var quadWidth: Float {
        get { quad.width }
        set {
            quad.width = newValue
//            BoundsCaching.ClearRoot(node)
        }
    }
    
    var quadHeight: Float {
        get { quad.height }
        set {
            quad.height = newValue
//            BoundsCaching.ClearRoot(node)
        }
    }
}
