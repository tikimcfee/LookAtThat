//
//  MetalLink.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Foundation
import MetalKit

class MetalLink {
    let view: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    
    lazy var shaderLibrary = ShaderLibrary(link: self)
    lazy var descriptorLibrary = VertexDescriptorComponentLibrary(link: self)
    lazy var pipelineLibrary = DescriptorPipelineLibrary(link: self)
    lazy var pipelineStateLibrary = PipelineStateLibrary(link: self)
    
    init(view: MTKView) throws {
        self.view = view
        guard let device = view.device else { throw CoreError.noMetalDevice }
        guard let queue = device.makeCommandQueue() else { throw CoreError.noCommandQueue }
        guard let library = device.makeDefaultLibrary() else { throw CoreError.noDefaultLibrary }
        self.device = device
        self.commandQueue = queue
        self.defaultLibrary = library
    }
}

protocol MetalLinkReader {
    var link: MetalLink { get }
}

extension MetalLinkReader {
    var view: MTKView { link.view }
    var device: MTLDevice { link.device }
    var library: MTLLibrary { link.defaultLibrary }
    var commandQueue: MTLCommandQueue { link.commandQueue }
    var currentDrawable: CAMetalDrawable? { view.currentDrawable }
    
    var viewDrawableSize: SIMD2<Float> {
        SIMD2<Float>(
            Float(view.drawableSize.width),
            Float(view.drawableSize.height)
        )
    }
    
    var defaultOrthographicProjection: simd_float4x4 {
        view.defaultOrthographicProjection
    }
}
