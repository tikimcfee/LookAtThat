//
//  DepthStencilStateLibrary.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit

enum MetalLinkDepthStencilStateType {
    case Less
}

class DepthStencilStateLibrary: LockingCache<MetalLinkDepthStencilStateType, MTLDepthStencilState> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        switch key {
        case .Less:
            return try! Less(link).depthStencilState
        }
    }
}

extension DepthStencilStateLibrary {
    class Less {
        var depthStencilState: MTLDepthStencilState
        
        init(_ link: MetalLink) throws {
            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.isDepthWriteEnabled = true
            depthStencilDescriptor.depthCompareFunction = .less
            depthStencilDescriptor.label = "MetalLink Depth Stencil"
            guard let state = link.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            else { throw CoreError.noStencilDescriptor }
            self.depthStencilState = state
        }
    }

}
