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
    var quadSize: LFloat2 {
        get { LFloat2(x: quad.width, y: quad.height) }
        set { quad.setSize(newValue) }
    }
    
    var quadWidth: Float {
        get { quad.width }
    }
    
    var quadHeight: Float {
        get { quad.height }
    }
}
