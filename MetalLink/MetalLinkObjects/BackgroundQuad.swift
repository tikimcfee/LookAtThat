//
//  BackgroundQuad.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/14/22.
//

import Foundation

class BackgroundQuad: MetalLinkObject, ContentSizing {
    let quad: MetalLinkQuadMesh
    
    var contentWidth: Float { quad.width }
    var contentHeight: Float { quad.height }
    var contentDepth: Float { 1 }
    var offset: LFloat3 {
        LFloat3(-contentWidth / 2.0, contentHeight / 2.0, 0)
    }
    
    init(_ link: MetalLink) {
        self.quad = MetalLinkQuadMesh(link)
        super.init(link, mesh: quad)
    }
}
