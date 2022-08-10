//
//  MetalLinkCamera.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit
import Combine

enum MetalLinkCameraType {
    case Debug
}

protocol MetalLinkCamera {
    var type: MetalLinkCameraType { get }
    var position: LFloat3 { get set }
    var projectionMatrix: matrix_float4x4 { get }
}

class DebugCamera: MetalLinkCamera, KeyboardPositionSource, MetalLinkReader {
    let type: MetalLinkCameraType = .Debug
    
    private lazy var currentProjection = matrix_cached_float4x4(update: self.buildProjectionMatrix)
    private lazy var currentView = matrix_cached_float4x4(update: self.buildViewMatrix)
    
    var position: LFloat3 = .zero { didSet {
        currentProjection.dirty()
        currentView.dirty()
    } }
    
    let worldUp: LFloat3 = LFloat3(0, 1, 0)
    let worldRight: LFloat3 = LFloat3(1, 0, 0)
    let worldFront: LFloat3 = LFloat3(0, 0, -1)
    
    let link: MetalLink
    let interceptor = KeyboardInterceptor()
    private var cancellables = Set<AnyCancellable>()
    
    init(link: MetalLink) {
        self.link = link
        interceptor.positionSource = self
        
        interceptor.positions.$totalOffset.sink { total in
            self.position = (total / 100)
        }.store(in: &cancellables)
        
        link.input.sharedKeyEvent.sink { event in
            self.interceptor.onNewKeyEvent(event)
        }.store(in: &cancellables)
    }
}

extension DebugCamera {
    var projectionMatrix: matrix_float4x4 {
        currentProjection.get()
    }
    
    var viewMatrix: matrix_float4x4 {
        currentView.get()
    }
    
    private func buildProjectionMatrix() -> matrix_float4x4 {
        matrix_float4x4.init(
            perspectiveProjectionFov: Float.pi / 2.0,
            aspectRatio: viewAspectRatio,
            nearZ: 0.1,
            farZ: 1000
        )
    }
    
    private func buildViewMatrix() -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.translate(vector: -position)
        return matrix
    }
}
