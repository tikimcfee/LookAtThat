//  ATTRIBUTION TO:
//  [Created by Szymon Błaszczyński on 26/08/2021.]
// https://gist.githubusercontent.com/buahaha/19b27170e629276606ab2e057823de70/raw/a8c45e38988dc3654fb41ecec5411cef7849f3b5/MetalView.swift

import Foundation
import MetalKit
import SwiftUI

struct MetalView: NSUIViewRepresentable {
    var mtkView: CustomMTKView
    
    init() throws {
        self.mtkView = GlobalInstances.rootCustomMTKView
    }
    
    #if os(iOS)
    func makeUIView(context: Context) -> some UIView {
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    #elseif os(macOS)
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> CustomMTKView {
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }
    
    func updateNSView(_ nsView: CustomMTKView, context: NSViewRepresentableContext<MetalView>) {
        
    }
    #endif
    
    func makeCoordinator() -> Coordinator {
        try! Coordinator(self, mtkView: mtkView)
    }
}

import Combine
extension MetalView {
    class Coordinator {
        var parent: MetalView
        

        var renderer: MetalLinkRenderer
        
        init(_ parent: MetalView, mtkView: CustomMTKView) throws {
            self.parent = parent
            
            let link = GlobalInstances.defaultLink
            guard let renderer = try? MetalLinkRenderer(link: link)
            else { throw CoreError.noMetalDevice }
            
            self.renderer = renderer
            
            mtkView.keyDownReceiver = link.input
            mtkView.positionReceiver = link.input
            
//            print("-- Metal Gesture Recognizers --")
//            print("This will disable some view events by default, like 'drag'")
//            mtkView.addGestureRecognizer(link.input.gestureShim.tapGestureRecognizer)
//            mtkView.addGestureRecognizer(link.input.gestureShim.magnificationRecognizer)
//            mtkView.addGestureRecognizer(link.input.gestureShim.panRecognizer)
//            print("-------------------------------")
            
            mtkView.delegate = renderer
            mtkView.framebufferOnly = false
            mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            mtkView.drawableSize = mtkView.frame.size
            mtkView.enableSetNeedsDisplay = true
        }
    }
}

