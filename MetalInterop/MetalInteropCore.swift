//
//  MetalInteropCore.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//

import Foundation
import MetalKit
import SwiftUI

extension MetalView {
    private static let defaultMTKView: MTKView = MTKView()
    static func makeFromDefault() -> MetalView {
        MetalView(mtkView: defaultMTKView)
    }
}

class MetalAlloyCore {
    static var core: MetalAlloyCore = MetalAlloyCore()
    
    private init() {
        
    }
    
    func generateDevice() -> (MTLDevice, MTLCommandQueue)? {
        guard let newDevice = MTLCreateSystemDefaultDevice(),
              let commandQueue = newDevice.makeCommandQueue()
        else {
            print("Could not create MetalDevice")
            return nil
        }
        return (newDevice, commandQueue)
    }
    
    func generateRenderer() -> AlloyRenderer? {
        guard let (device, queue) = generateDevice() else {
            return nil
        }
        
        return AlloyRenderer(
            device: device,
            commandQueue: queue
        )
    }
}

class AlloyRenderer: NSObject, MTKViewDelegate {
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
