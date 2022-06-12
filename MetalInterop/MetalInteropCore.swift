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
    
    func generateRenderer() -> MetalRenderer? {
        guard let (device, queue) = generateDevice() else {
            return nil
        }
        
        return MetalRenderer(
            device: device,
            commandQueue: queue
        )
    }
}
