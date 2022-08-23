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
    let view: CustomMTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    let input: DefaultInputReceiver
    
    lazy var textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
    
    lazy var meshLibrary = MeshLibrary(self)
    lazy var shaderLibrary = MetalLinkShaderCache(link: self)
    lazy var vertexDescriptorLibrary = VertexDescriptorLibrary(link: self)
    lazy var renderPipelineDescriptorLibrary = RenderPipelineDescriptorLibrary(link: self)
    lazy var pipelineStateLibrary = RenderPipelineStateLibrary(link: self)
    lazy var depthStencilStateLibrary = DepthStencilStateLibrary(link: self)
    
    init(view: CustomMTKView) throws {
        self.view = view
        guard let device = view.device else { throw CoreError.noMetalDevice }
        guard let queue = device.makeCommandQueue() else { throw CoreError.noCommandQueue }
        guard let library = device.makeDefaultLibrary() else { throw CoreError.noDefaultLibrary }
        self.device = device
        self.commandQueue = queue
        self.defaultLibrary = library
        self.input = DefaultInputReceiver.shared
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
    func viewportPosition(x: Float, y: Float) -> LFloat2 {
        let bounds = viewBounds
        return LFloat2(
            Float((x - bounds.x * 0.5) / (bounds.x * 0.5)),
            Float((y - bounds.y * 0.5) / (bounds.y * 0.5))
        )
    }
    
    var defaultGestureViewportPosition: LFloat2 {
        let mouseEvent = input.mousePosition
        let mouse = mouseEvent.locationInWindow
        return viewportPosition(x: Float(mouse.x), y: Float(mouse.y))
    }
    
    var viewBounds: LFloat2 {
        LFloat2(
            Float(view.bounds.width),
            Float(view.bounds.height)
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

#if os(iOS)
extension OSEvent {
    var locationInWindow: LFloat2 { LFloat2.zero }
    var deltaY: Float { 0.0 }
    var deltaX: Float { 0.0 }
}

extension Float {
    var float: Float { self }
}
#endif
