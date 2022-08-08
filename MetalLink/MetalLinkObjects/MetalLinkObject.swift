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
    
    init(_ link: MetalLink, mesh: MetalLinkMesh) throws {
        self.pipelineState = link.pipelineStateLibrary[.BasicPipelineState]
        self.mesh = mesh
    }
}

extension MetalLinkObject: MetalLinkRenderable {
    func doRender(in sdp: inout SafeDrawPass) {
        guard let meshVertexBuffer = mesh.getVertexBuffer() else { return }
        
        // Set buffer into device memory space; buffer(0) in shader functions.
        sdp.renderCommandEncoder.setRenderPipelineState(pipelineState)
        sdp.renderCommandEncoder.setVertexBuffer(meshVertexBuffer, offset: 0, index: 0)
        sdp.renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertexCount)
    }
}
