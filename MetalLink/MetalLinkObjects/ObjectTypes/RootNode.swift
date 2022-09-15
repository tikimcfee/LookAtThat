//
//  RootNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
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
        constants.projectionMatrix = camera.projectionMatrix
        constants.totalGameTime += deltaTime
        super.update(deltaTime: deltaTime)
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setVertexBytes(&constants, length: SceneConstants.memStride, index: 1)
        
        super.render(in: &sdp)
    }
}
