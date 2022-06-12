//  ATTRIBUTION TO:
//  [Created by Szymon Błaszczyński on 26/08/2021.]
// https://gist.githubusercontent.com/buahaha/19b27170e629276606ab2e057823de70/raw/a8c45e38988dc3654fb41ecec5411cef7849f3b5/MetalView.swift

import Foundation
import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    typealias NSViewType = MTKView
    var mtkView: MTKView
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mtkView: mtkView)
    }
}

extension MetalView {
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice?
        var metalCommandQueue: MTLCommandQueue?
        
        init(_ parent: MetalView, mtkView: MTKView) {
            self.parent = parent
            if let (device, queue) = Self.generateDevice() {
                mtkView.device = device
                self.metalDevice = device
                self.metalCommandQueue = queue
            }
            super.init()
            configureInitial(mtkView: mtkView)
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let metalDevice = metalDevice,
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
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.3, 0.5, 1)
            
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
}

private extension MetalView.Coordinator {
    static func generateDevice() -> (MTLDevice, MTLCommandQueue)? {
        guard let newDevice = MTLCreateSystemDefaultDevice(),
              let commandQueue = newDevice.makeCommandQueue()
        else {
            print("Could not create MetalDevice")
            return nil
        }
        return (newDevice, commandQueue)
    }
    
    func configureInitial(mtkView: MTKView) {
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
    }
}
