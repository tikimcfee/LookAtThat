//
//  MetalLinkReader.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/29/22.
//

import Foundation
import MetalKit
import Combine

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
    func convertToDrawablePosition(windowX x: Float, windowY y: Float) -> LFloat2 {
        let drawableSize = link.viewDrawableFloatSize
        let viewSize = link.viewPercentagePosition(x: x, y: y)
        return LFloat2(
            viewSize.x * drawableSize.x,
            drawableSize.y - viewSize.y * drawableSize.y
        )
    }
    
    func viewportPosition(x: Float, y: Float) -> LFloat2 {
        let bounds = viewBounds
        return LFloat2(
            Float((x - bounds.x * 0.5) / (bounds.x * 0.5)),
            Float((y - bounds.y * 0.5) / (bounds.y * 0.5))
        )
    }
    
    func viewPercentagePosition(x: Float, y: Float) -> LFloat2 {
        LFloat2(
            x / Float(view.bounds.width),
            y / Float(view.bounds.height)
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
        let size = viewDrawableFloatSize
        return size.x / size.y
    }
    
    var viewDrawableFloatSize: LFloat2 {
        LFloat2(
            Float(view.drawableSize.width),
            Float(view.drawableSize.height)
        )
    }
    
    var viewDrawableRoundSize: LInt2 {
        LInt2(
            Int(view.drawableSize.width),
            Int(view.drawableSize.height)
        )
    }
    
    var defaultOrthographicProjection: simd_float4x4 {
        view.defaultOrthographicProjection
    }
}
