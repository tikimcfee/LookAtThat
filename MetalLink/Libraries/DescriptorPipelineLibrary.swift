//
//  DescriptorPipelineLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkDescriptorPipeline {
    case BasicPipelineDescriptor
    
    func make(_ link: MetalLink) -> RenderPipelineDescriptor {
        switch self {
        case .BasicPipelineDescriptor:
            return Basic_RenderPipelineDescriptor(link)
        }
    }
}

protocol RenderPipelineDescriptor {
    var name: String { get }
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor { get }
}

struct Basic_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name = "Basic RenderPipelineDescriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor
    init(_ link: MetalLink) {
        let vertexFunction = link.shaderLibrary[.BasicVertex]?.function
        let vertexDescriptor = link.descriptorLibrary[.BasicDescriptor].descriptor
        let fragmentFunction = link.shaderLibrary[.BasicFragment]?.function
        
        self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = link.view.colorPixelFormat
    }
}

private class DescriptorPipelineCache: LockingCache<MetalLinkDescriptorPipeline, RenderPipelineDescriptor> {
    let link: MetalLink
    init(_ link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        key.make(link)
    }
}

class DescriptorPipelineLibrary {
    let link: MetalLink
    
    private lazy var pipelineCache = DescriptorPipelineCache(link)
    
    init(link: MetalLink) {
        self.link = link
    }
    
    subscript(_ pipeline: MetalLinkDescriptorPipeline) -> RenderPipelineDescriptor {
        pipelineCache[pipeline]
    }
}
