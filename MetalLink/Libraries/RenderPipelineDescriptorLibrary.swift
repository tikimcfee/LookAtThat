//
//  DescriptorPipelineLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

protocol RenderPipelineDescriptor {
    var name: String { get }
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor { get }
}

enum MetalLinkDescriptorPipeline {
    case BasicPipelineDescriptor
    case Instanced
}

class RenderPipelineDescriptorLibrary: LockingCache<MetalLinkDescriptorPipeline, RenderPipelineDescriptor> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        switch key {
        case .BasicPipelineDescriptor:
            return Basic(link)
        case .Instanced:
            return Instanced(link)
        }
    }
}

// MARK: - Descriptors

extension RenderPipelineDescriptorLibrary {
    struct Basic: RenderPipelineDescriptor {
        var name = "Basic RenderPipelineDescriptor"
        var renderPipelineDescriptor: MTLRenderPipelineDescriptor
        
        init(_ link: MetalLink) {
            let vertexFunction = link.shaderLibrary[.BasicVertex]
            let vertexDescriptor = link.vertexDescriptorLibrary[.Basic]
            let fragmentFunction = link.shaderLibrary[.BasicFragment]
            
            self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = link.view.colorPixelFormat
            renderPipelineDescriptor.colorAttachments[1].pixelFormat = MetalLinkPickingTexture.Config.pixelFormat // add pixel format to allow both picking and instancing
            renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            renderPipelineDescriptor.label = name
        }
    }
}

extension RenderPipelineDescriptorLibrary {
    struct Instanced: RenderPipelineDescriptor {
        var name = "Instanced RenderPipelineDescriptor"
        var renderPipelineDescriptor: MTLRenderPipelineDescriptor
        
        init(_ link: MetalLink) {
            let vertexFunction = link.shaderLibrary[.InstancedVertex]
            let vertexDescriptor = link.vertexDescriptorLibrary[.Instanced]
            let fragmentFunction = link.shaderLibrary[.InstancedFragment]
            
            self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = link.view.colorPixelFormat
            renderPipelineDescriptor.colorAttachments[1].pixelFormat = MetalLinkPickingTexture.Config.pixelFormat
            renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            renderPipelineDescriptor.label = name
        }
    }
}
