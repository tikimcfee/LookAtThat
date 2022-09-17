//
//  BackgroundQuad.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/14/22.
//

import Foundation

class BackgroundQuad: MetalLinkObject, QuadSizable {
    var quad: MetalLinkQuadMesh
    var node: MetalLinkNode { self }
    
    override var hasIntrinsicSize: Bool { true }
    
    override var contentSize: LFloat3 {
        LFloat3(scale.x * 2, scale.y * 2, 1)
    }
    
    override var contentOffset: LFloat3 {
        LFloat3(-scale.x, scale.y, 0)
    }
    
    init(_ link: MetalLink) {
        self.quad = MetalLinkQuadMesh(link)
        super.init(link, mesh: quad)
    }
    
    override func doRender(in sdp: inout SafeDrawPass) {
        super.doRender(in: &sdp)
    }
}
