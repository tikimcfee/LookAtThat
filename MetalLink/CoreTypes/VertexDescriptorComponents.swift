//
//  SampleComponents.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkVertexComponent {
    case BasicDescriptor
    
    var descriptorComponent: VertexDescriptorComponent {
        switch self {
        case .BasicDescriptor:
            return Basic_VertexComponent()
        }
    }
}

protocol VertexDescriptorComponent {
    var name: String { get }
    var descriptor: MTLVertexDescriptor { get }
    
    var attributeIndex: Int { get }
    var bufferIndex: Int { get }
    var layoutIndex: Int { get }
}

struct Basic_VertexComponent: VertexDescriptorComponent {
    var name = "Basic Vertex Component"
    let descriptor = MTLVertexDescriptor()
    var attributeIndex: Int = 0
    var bufferIndex: Int = 0
    var layoutIndex: Int = 0
    
    init() {
        // Vertex Position
        descriptor.attributes[attributeIndex].format = .float3
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = 0
        attributeIndex += 1
        
        // Color
        descriptor.attributes[attributeIndex].format = .float4
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = LFloat3.memSize
        
        // Layout
        descriptor.layouts[layoutIndex].stride = Vertex.memStride
        descriptor.layouts[layoutIndex].stepFunction = .perVertex
        descriptor.layouts[layoutIndex].stepRate = 1
    }
}
