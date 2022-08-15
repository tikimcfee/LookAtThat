//
//  DescriptorLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkVertexComponent {
    case BasicDescriptor
    case InstancedDescriptor
}

protocol VertexDescriptorComponent {
    var name: String { get }
    var descriptor: MTLVertexDescriptor { get }
    
    var attributeIndex: Int { get }
    var bufferIndex: Int { get }
    var layoutIndex: Int { get }
}

class VertexDescriptorComponentLibrary: LockingCache<MetalLinkVertexComponent, VertexDescriptorComponent> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        switch key {
        case .BasicDescriptor:
            return Basic_VertexComponent()
        case .InstancedDescriptor:
            return Instanced_VertexComponent()
        }
    }
}

// MARK: Basics

struct Basic_VertexComponent: VertexDescriptorComponent {
    var name = "Basic Vertex Component"
    let descriptor = MTLVertexDescriptor()
    var attributeIndex: Int = 0
    var attributeOffset: Int = 0
    var bufferIndex: Int = 0
    var layoutIndex: Int = 0
    
    init() {
        // Vertex Position
        descriptor.attributes[attributeIndex].format = .float3
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = 0
        attributeIndex += 1
        attributeOffset += LFloat3.memSize
        
        // Color
        descriptor.attributes[attributeIndex].format = .float4
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = attributeOffset
        attributeIndex += 1
        attributeOffset += LFloat4.memSize
        
        // Texture Coordinate
        descriptor.attributes[attributeIndex].format = .float2
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = attributeOffset
        attributeIndex += 1
        attributeOffset += LFloat2.memSize
        
        // Layout
        descriptor.layouts[layoutIndex].stride = Vertex.memStride
        descriptor.layouts[layoutIndex].stepFunction = .perVertex
        descriptor.layouts[layoutIndex].stepRate = 1
    }
}

// MARK: Instanced

struct Instanced_VertexComponent: VertexDescriptorComponent {
    var name = "Instanced Vertex Component"
    let descriptor = MTLVertexDescriptor()
    var attributeIndex: Int = 0
    var attributeOffset: Int = 0
    var bufferIndex: Int = 0
    var layoutIndex: Int = 0
    
    init() {
        // Vertex Position
        descriptor.attributes[attributeIndex].format = .float3
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = 0
        attributeIndex += 1
        attributeOffset += LFloat3.memSize
        
        // UV Texture Index
        descriptor.attributes[attributeIndex].format = .uint
        descriptor.attributes[attributeIndex].bufferIndex = bufferIndex
        descriptor.attributes[attributeIndex].offset = attributeOffset
        attributeIndex += 1
        attributeOffset += UInt.memSize
        
        // Layout
        descriptor.layouts[layoutIndex].stride = Vertex.memStride
        descriptor.layouts[layoutIndex].stepFunction = .perVertex
        descriptor.layouts[layoutIndex].stepRate = 1
    }
}
