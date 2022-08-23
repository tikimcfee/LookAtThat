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
    case Basic
    case Instanced
}

class RenderPipelineStateLibrary: LockingCache<MetalLinkRenderPipelineState, RenderPipelineState> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> RenderPipelineState {
        switch key {
        case .Basic:
            return try! Basic(link)
        case .Instanced:
            return try! Instanced(link)
        }
    }
    
    subscript(_ pipelineState: MetalLinkRenderPipelineState) -> MTLRenderPipelineState {
        self[pipelineState].renderPipelineState
    }
}

// MARK: - States

extension RenderPipelineStateLibrary {
    struct Basic: RenderPipelineState {
        var name = "Basic RenderPipelineState"
        var renderPipelineState: MTLRenderPipelineState
        init(_ link: MetalLink) throws {
            self.renderPipelineState = try link.device.makeRenderPipelineState(
                descriptor: link.renderPipelineDescriptorLibrary[.BasicPipelineDescriptor].renderPipelineDescriptor
            )
        }
    }
}

extension RenderPipelineStateLibrary {
    struct Instanced: RenderPipelineState {
        var name = "Instanced RenderPipelineState"
        var renderPipelineState: MTLRenderPipelineState
        init(_ link: MetalLink) throws {
            self.renderPipelineState = try link.device.makeRenderPipelineState(
                descriptor: link.renderPipelineDescriptorLibrary[.Instanced].renderPipelineDescriptor
            )
        }
    }
}
