//
//  MetalLinkObject.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class MetalLinkObject: MetalLinkNode {
    var mesh: MetalLinkMesh
    let pipelineState: MTLRenderPipelineState
    var state = State()
    var constants = Constants()
    
    init(_ link: MetalLink, mesh: MetalLinkMesh) throws {
        self.pipelineState = link.pipelineStateLibrary[.BasicPipelineState]
        self.mesh = mesh
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)        
        updateModelConstants()
    }
}

extension MetalLinkObject {
    func updateModelConstants() {
        // Pull matrix from node position
        constants.modelMatrix = modelMatrix
    }
}

extension MetalLinkObject {
    struct Constants: MemoryLayoutSizable {
        var modelMatrix = matrix_identity_float4x4
    }
    
    class State {
        var time: Float = 0
    }
}

extension MetalLinkObject: MetalLinkRenderable {
    func doRender(in sdp: inout SafeDrawPass) {
        guard let meshVertexBuffer = mesh.getVertexBuffer() else { return }
        
        // Set buffer into device memory space; buffer(0) in shader functions.
        sdp.renderCommandEncoder.setVertexBytes(&constants, length: Constants.memSize, index: 1)
        sdp.renderCommandEncoder.setRenderPipelineState(pipelineState)
        sdp.renderCommandEncoder.setVertexBuffer(meshVertexBuffer, offset: 0, index: 0)
        sdp.renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertexCount)
    }
}
