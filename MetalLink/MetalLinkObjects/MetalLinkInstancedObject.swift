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
    
    var state = State()
    var constants = InstancedConstants() { didSet { rebuildSelf = true }}
    var rebuildSelf: Bool = true
    
    var instancedNodes: [InstancedNodeType] = [] { didSet { pushModelConstants = true }}
    var instancedConstants: [InstancedConstants] = [] { didSet { pushModelConstants = true }}
    
    private var modelConstantsBuffer: MTLBuffer
    var pushModelConstants: Bool = true
    
    init(_ link: MetalLink,
         mesh: MetalLinkMesh,
         instances: () -> [InstancedNodeType]) throws {
        self.link = link
        self.mesh = mesh
        (self.modelConstantsBuffer,
         self.instancedNodes,
         self.instancedConstants) = try Self.setupNodeBuffers(using: instances, link)
        super.init()
    }
    
    override func update(deltaTime: Float) {
        state.time += deltaTime
        updateModelConstants()
        super.update(deltaTime: deltaTime)
    }
    
    func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
        // override to do stuff right before instance buffer updates
    }
}

private extension MetalLinkInstancedObject {
    static func setupNodeBuffers(
        using generator: () -> [InstancedNodeType],
        _ link: MetalLink
    ) throws -> (
        MTLBuffer,
        [InstancedNodeType],
        [InstancedConstants]
    ) {
        let instances = generator()
        let instanceConstants = instances.map { _ in InstancedConstants() }
        
        let count = instances.count
        let buffer = try createBuffers(link, instanceCount: count)
        
        return (buffer, instances, instanceConstants)
    }
    
    static func createBuffers(_ link: MetalLink, instanceCount: Int) throws -> MTLBuffer {
        guard let buffer = link.device.makeBuffer(
            length: InstancedConstants.memStride(of: instanceCount),
            options: []
        ) else { throw CoreError.noBufferAvailable }
        buffer.label = "InstancedConstants"
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
            constants.modelMatrix = modelMatrix
            rebuildSelf = false
        }
        
        if pushModelConstants {
            pushConstantsBuffer()
            pushModelConstants = false
        }
    }
    
    func pushConstantsBuffer() {
        iterativePush()
//        multiThreadedPush()
    }
    
    private func iterativePush() {
        var pointer = modelConstantsBuffer
            .contents()
            .bindMemory(to: InstancedConstants.self, capacity: instancedNodes.count)
        
        zip(instancedNodes, instancedConstants).forEach { node, constants in
            pointer.pointee.modelMatrix = node.modelMatrix
            pointer.pointee.color = constants.color
            pointer.pointee.textureIndex = constants.textureIndex
            pointer = pointer.advanced(by: 1)
        }
    }
    
    private func multiThreadedPush() {
        let pointer = modelConstantsBuffer
            .contents()
            .bindMemory(to: InstancedConstants.self, capacity: instancedNodes.count)
        
        let group = DispatchGroup() // Just throw threads at it, Ivan. Sure.
        instancedNodes
            .chunks(ofCount: instancedNodes.count / 4)
            .forEach { chunk in
                group.enter()
                WorkerPool.shared.nextConcurrentWorker().async {
                    var index = chunk.startIndex
                    chunk.forEach { node in
                        self.performJITInstanceBufferUpdate(node)
                        let constants = self.instancedConstants[index]
                        pointer[index].modelMatrix = matrix_multiply(self.modelMatrix, node.modelMatrix)
                        pointer[index].color = constants.color
                        pointer[index].textureIndex = constants.textureIndex
                        index += 1
                    }
                    group.leave()
                }
            }
        group.wait()
    }
}

extension MetalLinkInstancedObject {
    struct InstancedConstants: MemoryLayoutSizable {
        var modelMatrix = matrix_identity_float4x4
        var color = LFloat4.zero
        var textureIndex = TextureIndex.zero
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
            instanceCount: instancedNodes.count
        )
    }
}

enum LinkInstancingError: String, Error {
    case generatorFunctionFailed
}
