//
//  RenderPipelineStateLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

protocol RenderPipelineState {
    var name: String { get }
    var renderPipelineState: MTLRenderPipelineState { get }
}

enum MetalLinkRenderPipelineState {
    case BasicPipelineState
}


class PipelineStateLibrary: LockingCache<MetalLinkRenderPipelineState, RenderPipelineState> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> RenderPipelineState {
        switch key {
        case .BasicPipelineState:
            return try! Basic_RenderPipelineState(link)
        }
    }
    
    subscript(_ pipelineState: MetalLinkRenderPipelineState) -> MTLRenderPipelineState {
        self[pipelineState].renderPipelineState
    }
}

// MARK: - States

struct Basic_RenderPipelineState: RenderPipelineState {
    var name = "Basic RenderPipelineState"
    var renderPipelineState: MTLRenderPipelineState
    init(_ link: MetalLink) throws {
        self.renderPipelineState = try link.device.makeRenderPipelineState(
            descriptor: link.pipelineLibrary[.BasicPipelineDescriptor].renderPipelineDescriptor
        )
    }
}
