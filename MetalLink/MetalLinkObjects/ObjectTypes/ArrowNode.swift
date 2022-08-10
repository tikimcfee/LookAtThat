//
//  ArrowNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit

class ArrowNode: MetalLinkObject, MetalLinkReader {
    init(_ link: MetalLink) throws {
        try super.init(link, mesh: link.meshes[.Triangle])
    }
    
    override func update(deltaTime: Float) {
        //        updatePointer()
        super.update(deltaTime: deltaTime)
    }
    
    func updatePointer() {
        let gesturePosition = defaultGestureViewportPosition
        rotation.z = -atan2f(
            gesturePosition.x - position.x,
            gesturePosition.y - position.y
        )
    }
}
