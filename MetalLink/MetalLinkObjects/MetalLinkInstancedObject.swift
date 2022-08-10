//
//  MetalLinkInstancedObject.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit

class MetalLinkInstancedObject: MetalLinkNode {
    let link: MetalLink
    var mesh: MetalLinkMesh
    
    private lazy var pipelineState: MTLRenderPipelineState
        = link.pipelineStateLibrary[.Instanced]
    
    private lazy var stencilState: MTLDepthStencilState
        = link.depthStencilStateLibrary[.Less]
    
    var state = State()
    var constants = Constants() { didSet { rebuildSelf = true }}
    var rebuildSelf: Bool = true
    private var material = MetalLinkMaterial()
    
    var instances: [MetalLinkNode] = [] { didSet { rebuildBuffer = true }}
    private var modelConstants: [Constants] = [] { didSet { rebuildBuffer = true }}
    private var modelConstantsBuffer: MTLBuffer
    private var rebuildBuffer: Bool = true
    
    init(_ link: MetalLink,
         mesh: MetalLinkMesh,
         initialCount: Int) throws {
        self.link = link
        self.mesh = mesh
        
        (self.instances, self.modelConstants) = Self.generateInstances(count: initialCount)
        self.modelConstantsBuffer = try Self.createBuffers(link, instanceCount: initialCount)
        
        super.init()
    }
    
    override func update(deltaTime: Float) {
        updateModelConstants()
        super.update(deltaTime: deltaTime)
    }
}

private extension MetalLinkInstancedObject {
    static func generateInstances(count: Int) -> ([MetalLinkNode], [Constants]) {
        var instances: [MetalLinkNode] = []
        var modelConstants: [Constants] = []
        for _ in 0..<count {
            modelConstants.append(.init())
            instances.append(.init())
        }
        return (instances, modelConstants)
    }
    
    static func createBuffers(_ link: MetalLink, instanceCount: Int) throws -> MTLBuffer {
        guard let buffer = link.device.makeBuffer(
            length: Constants.memStride(of: instanceCount),
            options: []
        ) else { throw CoreError.noBufferAvailable }
        return buffer
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
            rebuildSelf = false
            constants.modelMatrix = modelMatrix
        }
        
//        if rebuildBuffer {
            rebuildBuffer = false
            pushConstantsBuffer()
//        }
    }
    
    func pushConstantsBuffer() {
        var pointer = modelConstantsBuffer
            .contents()
            .bindMemory(to: Constants.self, capacity: instances.count)
        
        for instance in instances {
            pointer.pointee.modelMatrix = instance.modelMatrix
            pointer = pointer.advanced(by: 1)
        }
    }
}

extension MetalLinkInstancedObject {
    struct Constants: MemoryLayoutSizable {
        var modelMatrix = matrix_identity_float4x4
    }
    
    class State {
        var time: Float = 0
    }
}

extension MetalLinkInstancedObject: MetalLinkRenderable {
    func doRender(in sdp: inout SafeDrawPass) {
        guard let meshVertexBuffer = mesh.getVertexBuffer() else { return }
        
        // Setup rendering states for next draw pass
        sdp.renderCommandEncoder.setRenderPipelineState(pipelineState)
        sdp.renderCommandEncoder.setDepthStencilState(stencilState)
        
        // Set small <4kb buffered constants and main mesh buffer
        sdp.renderCommandEncoder.setVertexBuffer(meshVertexBuffer, offset: 0, index: 0)
        sdp.renderCommandEncoder.setVertexBuffer(modelConstantsBuffer, offset: 0, index: 2)
        
        // Update fragment shader
        sdp.renderCommandEncoder.setFragmentBytes(&material, length: MetalLinkMaterial.memStride, index: 1)
        
        // Do the draw
        sdp.renderCommandEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: mesh.vertexCount,
            instanceCount: instances.count
        )
    }
}

