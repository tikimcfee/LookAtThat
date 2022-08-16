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
    // Have mercy I just want to do some testing
    static let defaultInputReceiver = DefaultInputReceiver()
    
    let view: CustomMTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    
    lazy var textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
    
    lazy var meshes = MeshLibrary(self)
    lazy var shaderLibrary = ShaderLibrary(link: self)
    lazy var descriptorLibrary = VertexDescriptorComponentLibrary(link: self)
    lazy var pipelineLibrary = DescriptorPipelineLibrary(link: self)
    lazy var pipelineStateLibrary = PipelineStateLibrary(link: self)
    lazy var depthStencilStateLibrary = DepthStencilStateLibrary(link: self)
    
    let input = MetalLink.defaultInputReceiver
    
    init(view: CustomMTKView) throws {
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
    var view: CustomMTKView { link.view }
    var device: MTLDevice { link.device }
    var library: MTLLibrary { link.defaultLibrary }
    var commandQueue: MTLCommandQueue { link.commandQueue }
    var currentDrawable: CAMetalDrawable? { view.currentDrawable }
    
    var input: DefaultInputReceiver { link.input }
}

extension MetalLinkReader {
    var defaultGestureViewportPosition: LFloat2 {
        let mouse = input.mousePosition
        let size = view.bounds
        return LFloat2(
            Float((mouse.x - size.width * 0.5) / (size.width * 0.5)),
            Float((mouse.y - size.height * 0.5) / (size.height * 0.5))
        )
    }
    
    var viewAspectRatio: Float {
        let size = viewDrawableSize
        return size.x / size.y
    }
    
    var viewDrawableSize: LFloat2 {
        LFloat2(
            Float(view.drawableSize.width),
            Float(view.drawableSize.height)
        )
    }
    
    var defaultOrthographicProjection: simd_float4x4 {
        view.defaultOrthographicProjection
    }
}
