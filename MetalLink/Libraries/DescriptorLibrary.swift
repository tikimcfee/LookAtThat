//
//  DescriptorLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class VertexDescriptorComponentLibrary {
    let link: MetalLink
    
    private var vertexDescriptors = [MetalLinkVertexComponent: VertexDescriptorComponent]()
    
    init(link: MetalLink) {
        self.link = link
    }
    
    subscript(_ component: MetalLinkVertexComponent) -> VertexDescriptorComponent {
        if let descriptor = vertexDescriptors[component] { return descriptor }
        let newDescriptor = component.descriptorComponent
        vertexDescriptors[component] = newDescriptor
        return newDescriptor
    }
}

