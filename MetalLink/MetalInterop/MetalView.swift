//  ATTRIBUTION TO:
//  [Created by Szymon Błaszczyński on 26/08/2021.]
// https://gist.githubusercontent.com/buahaha/19b27170e629276606ab2e057823de70/raw/a8c45e38988dc3654fb41ecec5411cef7849f3b5/MetalView.swift

import Foundation
import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    typealias NSViewType = MTKView
    var mtkView: MTKView
    
    init() {
        mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
//        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mtkView: mtkView)
    }
}

extension MetalView {
    class Coordinator {
        var parent: MetalView
        
        var link: MetalLink?
        var renderer: MetalLinkRenderer?
        
        init(_ parent: MetalView, mtkView: MTKView) {
            self.parent = parent
            self.link = try? MetalLink(view: mtkView)
            self.renderer = try? MetalLinkRenderer(view: mtkView)
            
            mtkView.delegate = renderer
            mtkView.framebufferOnly = false
            mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            mtkView.drawableSize = mtkView.frame.size
            mtkView.enableSetNeedsDisplay = true
        }
    }
}

