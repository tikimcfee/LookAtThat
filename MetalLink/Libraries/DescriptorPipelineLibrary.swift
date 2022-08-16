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

class DescriptorPipelineLibrary: LockingCache<MetalLinkDescriptorPipeline, RenderPipelineDescriptor> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        switch key {
        case .BasicPipelineDescriptor:
            return Basic_RenderPipelineDescriptor(link)
        case .Instanced:
            return Instanced_RenderPipelineDescriptor(link)
        }
    }
}

// MARK: - Descriptors

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
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    }
}

struct Instanced_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name = "Instanced RenderPipelineDescriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor
    init(_ link: MetalLink) {
        let vertexFunction = link.shaderLibrary[.InstancedVertex]?.function
        let vertexDescriptor = link.descriptorLibrary[.InstancedDescriptor].descriptor
        let fragmentFunction = link.shaderLibrary[.InstancedFragment]?.function
        
        self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = link.view.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    
        // TODO: Enable alpha blending with textures.. _somehow_
//        p.colorAttachments[0].isBlendingEnabled = true
//        p.colorAttachments[0].rgbBlendOperation = .add
//        p.colorAttachments[0].alphaBlendOperation = .add
//        p.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
//        p.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
//        p.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
//        p.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    }
}
