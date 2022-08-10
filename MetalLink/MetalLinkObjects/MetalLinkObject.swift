//
//  MetalLinkObject.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class MetalLinkObject: MetalLinkNode {
    let link: MetalLink
    
    var mesh: MetalLinkMesh
    let pipelineState: MTLRenderPipelineState
    
    var state = State()
    var constants = Constants()
    private var material = MetalLinkMaterial()
    
    init(_ link: MetalLink, mesh: MetalLinkMesh) throws {
        self.link = link
        self.pipelineState = link.pipelineStateLibrary[.BasicPipelineState]
        self.mesh = mesh
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)        
        updateModelConstants()
    }
}

extension MetalLinkObject {
    public func setColor(_ color: LFloat4) {
        material.color = color
        material.useMaterialColor = true
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
        
        // Setup rendering states for next draw pass
        sdp.renderCommandEncoder.setRenderPipelineState(pipelineState)
        sdp.renderCommandEncoder.setDepthStencilState(link.depthStencilStateLibrary[.Less])
        
        // Set small <4kb buffered constants and main mesh buffer
        sdp.renderCommandEncoder.setVertexBuffer(meshVertexBuffer, offset: 0, index: 0)
        sdp.renderCommandEncoder.setVertexBytes(&constants, length: Constants.memSize, index: 2)
        
        // Update fragment shader
        sdp.renderCommandEncoder.setFragmentBytes(&material, length: MetalLinkMaterial.memStride, index: 1)
        
        // Do the draw
        sdp.renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertexCount)
    }
}
