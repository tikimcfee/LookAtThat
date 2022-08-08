//
//  RenderPipelineStateLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkRenderPipelineState {
    case BasicPipelineState
    
    func make(_ link: MetalLink) -> RenderPipelineState {
        switch self {
        case .BasicPipelineState:
            return try! Basic_RenderPipelineState(link)
        }
    }
}

protocol RenderPipelineState {
    var name: String { get }
    var renderPipelineState: MTLRenderPipelineState { get }
}

struct Basic_RenderPipelineState: RenderPipelineState {
    var name = "Basic RenderPipelineState"
    var renderPipelineState: MTLRenderPipelineState
    init(_ link: MetalLink) throws {
        self.renderPipelineState = try link.device.makeRenderPipelineState(
            descriptor: link.pipelineLibrary[.BasicPipelineDescriptor].renderPipelineDescriptor
        )
    }
}

class PipelineStateLibrary {
    let link: MetalLink
    
    private var pipelineStates = [MetalLinkRenderPipelineState: RenderPipelineState]()
    
    init(link: MetalLink) {
        self.link = link
    }
    
    subscript(_ pipelineState: MetalLinkRenderPipelineState) -> MTLRenderPipelineState {
        if let pipelineState = pipelineStates[pipelineState] {
            return pipelineState.renderPipelineState
        }
        
        let newState = pipelineState.make(link)
        pipelineStates[pipelineState] = newState
        return newState.renderPipelineState
    }
}


