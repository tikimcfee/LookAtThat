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
    
    override func make(
        _ key: MetalLinkDepthStencilStateType,
        _ store: inout [MetalLinkDepthStencilStateType : MTLDepthStencilState]
    ) -> MTLDepthStencilState {
        switch key {
        case .Less:
            return try! MetalLinkDepthStencilState_Less(link).depthStencilState
        }
    }
}

class MetalLinkDepthStencilState_Less {
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
