//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

class MetalLinkNode {
    private var renderable: MetalLinkRenderable? {
        self as? MetalLinkRenderable
    }
    
    func render(in sdp: inout SafeDrawPass) {
        renderable?.doRender(in: &sdp)
    }
}
