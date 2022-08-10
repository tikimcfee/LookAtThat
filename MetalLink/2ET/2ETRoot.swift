//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Combine
import MetalKit

class RootNode: MetalLinkNode, MetalLinkReader {
    let camera: DebugCamera
    var link: MetalLink { camera.link }
    
    var constants = SceneConstants()
    var cancellables = Set<AnyCancellable>()
    
    init(_ camera: DebugCamera) {
        self.camera = camera
        super.init()
    }
    
    override func update(deltaTime: Float) {
        constants.viewMatrix = camera.viewMatrix
        super.update(deltaTime: deltaTime)
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setVertexBytes(&constants, length: SceneConstants.memStride, index: 1)
        super.render(in: &sdp)
    }
}

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    lazy var root = RootNode(
        DebugCamera(link: link)
    )
    
    init(link: MetalLink) throws {
        self.link = link
        try setup()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        root.update(deltaTime: 1.0 / Float(link.view.preferredFramesPerSecond))
        root.render(in: &sdp)
    }
}

extension TwoETimeRoot {
    func setup() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let (min, max) = (-10, 10)
        let length = (min..<max)
        let count = Float(length.count)
        let halfCount = count / 2.0 // iterate from left to right, left/right symmetry
        for x in length {
            let x = Float(x)
            for y in length {
                let y = Float(y)
                
                let node = try ArrowNode(link)
                node.position = LFloat3(
                    (x + 0.5) / halfCount,
                    (y + 0.5) / halfCount,
                    1
                )
                node.scale = LFloat3(repeating: 1 / count)
                root.add(child: node)
            }
        }
    }
}

class ArrowNode: MetalLinkObject, MetalLinkReader {
    init(_ link: MetalLink) throws {
        try super.init(link, mesh: link.meshes[.Triangle])
    }
    
    override func update(deltaTime: Float) {
        updatePointer()
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
