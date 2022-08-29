//
//  MetalLink.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Foundation
import MetalKit
import Combine

class MetalLink {
    let view: CustomMTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    let input: DefaultInputReceiver
    
    lazy var textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
    
    // TODO: Move these classes into a hierarchy
    // They all use MetalLink._library to fetch, and could be fields instead
    lazy var meshLibrary = MeshLibrary(self)
    lazy var shaderLibrary = MetalLinkShaderCache(link: self)
    lazy var vertexDescriptorLibrary = VertexDescriptorLibrary(link: self)
    lazy var renderPipelineDescriptorLibrary = RenderPipelineDescriptorLibrary(link: self)
    lazy var pipelineStateLibrary = RenderPipelineStateLibrary(link: self)
    lazy var depthStencilStateLibrary = DepthStencilStateLibrary(link: self)
    
    lazy var pickingTexture = MetalLinkPickingTexture(link: self)
    private lazy var sizeSubject = PassthroughSubject<CGSize, Never>()
    private(set) lazy var sizeSharedUpdates = sizeSubject.share()
    
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

extension MetalLink {
    func onSizeChange(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        sizeSubject.send(size)
    }
}

// MetalLink reads itself lol
extension MetalLink: MetalLinkReader {
    var link: MetalLink { self }
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
