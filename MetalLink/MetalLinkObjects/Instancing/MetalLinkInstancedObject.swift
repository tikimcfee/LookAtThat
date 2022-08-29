//
//  MetalLinkInstancedObject.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit
import Algorithms

class MetalLinkInstancedObject<InstancedNodeType: MetalLinkNode>: MetalLinkNode {
    let link: MetalLink
    var mesh: MetalLinkMesh
    
    private lazy var pipelineState: MTLRenderPipelineState
        = link.pipelineStateLibrary[.Instanced]
    
    private lazy var stencilState: MTLDepthStencilState
        = link.depthStencilStateLibrary[.Less]
    
    private var material = MetalLinkMaterial()
    
    // TODO: Use regular constants for root, not instanced
    var rootConstants = InstancedConstants(instanceID: 0) { didSet { rebuildSelf = true }}
    
    var rebuildSelf: Bool = true
    var rootState = State()
    let instanceState: InstanceState
    let instanceCache: InstancedConstantsCache
    
    var willRebuildState: Bool { instanceState.bufferCache.willRebuild }
    
    init(_ link: MetalLink, mesh: MetalLinkMesh) {
        self.link = link
        self.mesh = mesh
        self.instanceState = InstanceState(link: link)
        self.instanceCache = InstancedConstantsCache()
        super.init()
    }
    
    override func update(deltaTime: Float) {
        rootState.time += deltaTime
        updateModelConstants()
        super.update(deltaTime: deltaTime)
    }
    
    override func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        
    }
    
    func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
        // override to do stuff right before instance buffer updates
    }
}

extension MetalLinkInstancedObject {
    public func setColor(_ color: LFloat4) {
        material.color = color
        material.useMaterialColor = true
    }
}

extension MetalLinkInstancedObject {
    func updateModelConstants() {
        if rebuildSelf {
            rootConstants.modelMatrix = modelMatrix
            rebuildSelf = false
        }
        
        iterativePush()
    }
    
    private func iterativePush() {
        var constantsBufferIndex = 0
        instanceState.zipUpdate { node, constants, pointer in
            self.performJITInstanceBufferUpdate(node)
            
            pointer.pointee.modelMatrix = matrix_multiply(self.modelMatrix, node.modelMatrix)
            pointer.pointee.textureDescriptorU = constants.textureDescriptorU
            pointer.pointee.textureDescriptorV = constants.textureDescriptorV
            pointer.pointee.instanceID = constants.instanceID
            pointer.pointee.addedColor = constants.addedColor
            
            // I am ashamed I am doing this. Nodes really should just point back to buffer.
            // This solves the issue of things being out of order and rebuilt, but it creates
            // rendering timing issues. E.g., right after everything is manually built, you
            // should call an update() to get a push for the initial model constants.
            self.instanceCache.track(constant: constants, at: constantsBufferIndex)
            constantsBufferIndex += 1
        }
    }
}

extension MetalLinkInstancedObject: MetalLinkRenderable {
    func doRender(in sdp: inout SafeDrawPass) {
        guard !instanceState.nodes.isEmpty,
              let meshVertexBuffer = mesh.getVertexBuffer(),
              let constantsBuffer = instanceState.bufferCache.get()
        else { return }
        
        // Setup rendering states for next draw pass
        sdp.renderCommandEncoder.setRenderPipelineState(pipelineState)
        sdp.renderCommandEncoder.setDepthStencilState(stencilState)
        
        // Set small buffered constants and main mesh buffer
        sdp.renderCommandEncoder.setVertexBuffer(meshVertexBuffer, offset: 0, index: 0)
        sdp.renderCommandEncoder.setVertexBuffer(constantsBuffer, offset: 0, index: 2)
        
        // Update fragment shader
        // TODO: Think of something to do with fragment buffer
        sdp.renderCommandEncoder.setFragmentBytes(&material, length: MetalLinkMaterial.memStride, index: 1)
        
        // Draw the single instanced glyph mesh (see DIRTY FILTHY HACK for details).
        // Constants need to capture vertex transforms for emoji/nonstandard.
        // OR, use multiple draw calls for sizes (noooo...)
        sdp.renderCommandEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: mesh.vertexCount,
            instanceCount: instanceState.nodes.count
        )
    }
}

enum LinkInstancingError: String, Error {
    case generatorFunctionFailed
}
