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
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
//        doDefaultDraw(in: view)
    }
    
    func doDefaultDraw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandQueue = metalDevice.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor
        else {
            print("draw(in:) error creating queue and command buffer")
            return
        }
        
        // Forwards the drawable texture to the descriptor?
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.2, 0.4, 1)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: passDescriptor
        ) else {
            print("could not create command encoder")
            return
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension MetalRenderer {
    class State {
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
        
        private lazy var rootMDLVertexDescriptor: MDLVertexDescriptor = {
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
        
        
        
        print("----------------")
    }
}
