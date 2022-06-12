//
//  MetalRenderer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//

import Foundation
import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    let metalDevice: MTLDevice
    let commandQueue: MTLCommandQueue
    let mtkView: MTKView
    var state = State()
    
    init(device: MTLDevice,
         commandQueue: MTLCommandQueue,
         mtkView: MTKView) {
        self.metalDevice = device
        self.commandQueue = commandQueue
        self.mtkView = mtkView
        super.init()
        
        loadResources()
        buildPipeline()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        doTestClearingDraw(in: view)
    }
    
    func doTestClearingDraw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let renderPipeline = state.renderPipeline,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: passDescriptor
              )
        else {
            print("draw(in:) error creating queue and command buffer")
            return
        }
        
        commandEncoder.setRenderPipelineState(renderPipeline)
        
        let modelMatrix = float4x4(
            rotationAbout: float3(0, 1, 0),
            by: -Float.pi / 6
        ) *  float4x4(scaleBy: 2)
        
        let viewMatrix = float4x4(
            translationBy: float3(0, -3, -20)
        )
        let modelViewMatrix = viewMatrix * modelMatrix
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = float4x4(
            perspectiveProjectionFov: Float.pi / 3,
            aspectRatio: aspectRatio,
            nearZ: 0.1,
            farZ: 100
        )
        
        var uniforms = Uniforms(
            modelViewMatrix: modelViewMatrix,
            projectionMatrix: projectionMatrix
        )
        commandEncoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.size,
            index: 1
        )
        
        for mesh in state.meshes {
            guard let vertexBuffer = mesh.vertexBuffers.first
            else { continue }
            
            commandEncoder.setVertexBuffer(vertexBuffer.buffer,
                                           offset: vertexBuffer.offset,
                                           index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension MetalRenderer {
    class State {
        var meshes: [MTKMesh] = []
        var currentLibrary: MTLLibrary?
        var renderPipeline: MTLRenderPipelineState?
        
        lazy var convertedMTKVertexDescriptor: MTLVertexDescriptor? = {
            do {
                return try MTKMetalVertexDescriptorFromModelIOWithError(
                    rootMDLVertexDescriptor
                )
            } catch {
                print(error)
                return nil
            }
        }()
        
        lazy var rootMDLVertexDescriptor: MDLVertexDescriptor = {
            var vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[0] = MDLVertexAttribute(
                name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0
            )
            vertexDescriptor.attributes[1] = MDLVertexAttribute(
                name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0
            )
            vertexDescriptor.attributes[2] = MDLVertexAttribute(
                name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0
            )
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(
                stride: MemoryLayout<Float>.size * 8
            )
            return vertexDescriptor
        }()
    }
}

private extension MetalRenderer {
    var testTeapotObj: URL? {
        Bundle.main.url(forResource: "teapot", withExtension: "obj")
    }
    
    func loadResources() {
        print("----------------")
        guard let testTeapotObj = testTeapotObj else {
            print("No teapot.")
            return
        }
        
        let bufferAllocator = MTKMeshBufferAllocator(device: metalDevice)
        let asset = MDLAsset(
            url: testTeapotObj,
            vertexDescriptor: state.rootMDLVertexDescriptor,
            bufferAllocator: bufferAllocator
        )
        state.meshes = generateMTKMeshes(from: asset)
        print("----------------")
    }
    
    func buildPipeline() {
        state.currentLibrary = metalDevice.makeDefaultLibrary()
        guard let library = state.currentLibrary else {
            print("No library created.")
            return
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = state.convertedMTKVertexDescriptor
        
        do {
            state.renderPipeline = try metalDevice.makeRenderPipelineState(
                descriptor: pipelineDescriptor
            )
        } catch {
            print("Could not create render pipeline state object: \(error)")
        }
    }
    
    func generateMTKMeshes(from asset: MDLAsset) -> [MTKMesh] {
        do {
            let (_, newMeshes) = try MTKMesh.newMeshes(asset: asset, device: metalDevice)
            return newMeshes
        } catch {
            print("Could not extract meshes from Model I/O asset", error)
            return []
        }
    }
}

// MARK: - Uniforms.swift<>RootShaders
import simd

struct Uniforms {
    var modelViewMatrix: float4x4
    var projectionMatrix: float4x4
}
