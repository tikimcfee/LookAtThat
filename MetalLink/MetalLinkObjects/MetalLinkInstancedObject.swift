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
            .bindMemory(to: InstancedConstants.self, capacity: instancedConstants.count)
        
        zip(instancedNodes, instancedConstants).forEach { node, constants in
            self.performJITInstanceBufferUpdate(node)
            pointer.pointee.modelMatrix = matrix_multiply(self.modelMatrix, node.modelMatrix)
            pointer.pointee.textureDescriptorU = constants.textureDescriptorU
            pointer.pointee.textureDescriptorV = constants.textureDescriptorV
            pointer = pointer.advanced(by: 1)
        }
    }
    
    private func multiThreadedPush() {
        let chunks = instancedNodes.count / 4
        guard chunks > 1 else {
            iterativePush()
            return
        }
        
        let pointer = modelConstantsBuffer
            .contents()
            .bindMemory(to: InstancedConstants.self, capacity: instancedConstants.count)
        
        let group = DispatchGroup() // Just throw threads at it, Ivan. Sure.
        instancedNodes
            .chunks(ofCount: chunks)
            .forEach { chunk in
                group.enter()
                WorkerPool.shared.nextConcurrentWorker().async {
                    var index = chunk.startIndex
                    chunk.forEach { node in
                        self.performJITInstanceBufferUpdate(node)
                        
                        let constants = self.instancedConstants[index]
                        pointer[index].modelMatrix = matrix_multiply(self.modelMatrix, node.modelMatrix)
                        pointer[index].textureDescriptorU = constants.textureDescriptorU
                        pointer[index].textureDescriptorV = constants.textureDescriptorV
                        pointer[index] = constants
                        
                        index += 1
                    }
                    group.leave()
                }
            }
        group.wait()
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
