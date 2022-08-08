//
//  SafeDrawPass.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

struct SafeDrawPass {
    let renderPassDescriptor: MTLRenderPassDescriptor
    let renderCommandEncoder: MTLRenderCommandEncoder
    let commandBuffer: MTLCommandBuffer
    
    static func wrap(_ link: MetalLink) -> SafeDrawPass? {
        guard let renderPassDescriptor = link.view.currentRenderPassDescriptor,
              let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return nil
        }
        
        return SafeDrawPass(
            renderPassDescriptor: renderPassDescriptor,
            renderCommandEncoder: renderCommandEncoder,
            commandBuffer: commandBuffer
        )
    }
}
