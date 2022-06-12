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
    let commandQUeue: MTLCommandQueue
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.metalDevice = device
        self.commandQUeue = commandQueue
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
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
