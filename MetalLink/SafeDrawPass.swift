//
//  SafeDrawPass.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class SafeDrawPass {
    private static var reusedPassContainer: SafeDrawPass?
    
    var renderPassDescriptor: MTLRenderPassDescriptor
    var renderCommandEncoder: MTLRenderCommandEncoder
    var commandBuffer: MTLCommandBuffer
        
    private init(
        renderPassDescriptor: MTLRenderPassDescriptor,
        renderCommandEncoder: MTLRenderCommandEncoder,
        commandBuffer: MTLCommandBuffer
    ) {
        self.renderPassDescriptor = renderPassDescriptor
        self.renderCommandEncoder = renderCommandEncoder
        self.commandBuffer = commandBuffer
    }
}

extension SafeDrawPass {
    static func wrap(_ link: MetalLink) -> SafeDrawPass? {
        guard let renderPassDescriptor = link.view.currentRenderPassDescriptor
        else {
            return nil
        }
        
        // TODO:
        // setup a start/stop for descriptor updates.
        // look at other implementations of engines.
        // or... use one... ...  .
        link.glyphPickingTexture.updateDescriptor(renderPassDescriptor)
        link.gridPickingTexture.updateDescriptor(renderPassDescriptor)
        
        guard let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return nil
        }
        
        if let container = reusedPassContainer {
            container.renderPassDescriptor = renderPassDescriptor
            container.renderCommandEncoder = renderCommandEncoder
            container.commandBuffer = commandBuffer
            return container
        } else {
            let container = SafeDrawPass(
                renderPassDescriptor: renderPassDescriptor,
                renderCommandEncoder: renderCommandEncoder,
                commandBuffer: commandBuffer
            )
            reusedPassContainer = container
            return container
        }
    }
}
