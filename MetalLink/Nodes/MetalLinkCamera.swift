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

protocol MetalLinkCamera: AnyObject {
    var type: MetalLinkCameraType { get }
    var position: LFloat3 { get set }
    var rotation: LFloat3 { get set }
    var projectionMatrix: matrix_float4x4 { get }
    
    var worldUp: LFloat3 { get }
    var worldRight: LFloat3 { get }
    var worldFront: LFloat3 { get }
}

class DebugCamera: MetalLinkCamera, KeyboardPositionSource, MetalLinkReader {
    let type: MetalLinkCameraType = .Debug
    
    private lazy var currentProjection = matrix_cached_float4x4(update: self.buildProjectionMatrix)
    private lazy var currentView = matrix_cached_float4x4(update: self.buildViewMatrix)
    
    var position: LFloat3 = .zero { didSet {
        currentProjection.dirty()
        currentView.dirty()
    } }
    
    var rotation: LFloat3 = .zero { didSet {
        currentProjection.dirty()
        currentView.dirty()
    } }
    
    var worldUp: LFloat3 { LFloat3(0, 1, 0) * rotation.x }
    var worldRight: LFloat3 { LFloat3(1, 0, 0) * rotation.z }
    var worldFront: LFloat3 { LFloat3(0, 0, -1) * rotation.y }
    
    let link: MetalLink
    let interceptor = KeyboardInterceptor()
    private var cancellables = Set<AnyCancellable>()
    
    var startRotate: Bool = false
    
    init(link: MetalLink) {
        self.link = link
        interceptor.positionSource = self
        
        interceptor.positions.$totalOffset.sink { total in
            self.position = (total / 100)
        }.store(in: &cancellables)
        
        interceptor.positions.$rotationOffset.removeDuplicates().sink { total in
            self.rotation = (total / 100)
        }.store(in: &cancellables)
        
        link.input.sharedKeyEvent.sink { event in
            self.interceptor.onNewKeyEvent(event)
        }.store(in: &cancellables)
        
        link.input.sharedMouseDown.sink { event in
            print("mouse down")
            self.startRotate = true
        }.store(in: &cancellables)

        link.input.sharedMouseUp.sink { event in
            print("mouse up")
            self.startRotate = false
        }.store(in: &cancellables)
        
        link.input.sharedMouse.sink { event in
            guard self.startRotate else { return }
            self.interceptor.positions.rotationOffset.y += event.deltaX.float / 5
            self.interceptor.positions.rotationOffset.x += event.deltaY.float / 5
        }.store(in: &cancellables)
        
        #if os(macOS)
        
        #endif
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
        let matrix = matrix_float4x4.init(
            perspectiveProjectionFov: Float.pi / 3.0,
            aspectRatio: viewAspectRatio,
            nearZ: 0.1,
            farZ: 1000
        )
//        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
//        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
//        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        return matrix
    }
    
    private func buildViewMatrix() -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.translate(vector: -position)
        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        return matrix
    }
}
