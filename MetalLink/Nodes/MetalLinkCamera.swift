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
    
    func moveCameraLocation(_ dX: Float, _ dY: Float, _ dZ: Float)
}

extension MetalLinkCamera {
    func moveCameraLocation(_ delta: LFloat3) {
        moveCameraLocation(delta.x, delta.y, delta.z)
    }
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
    
    var worldUp: LFloat3 { LFloat3(0, 1, 0) }
    var worldRight: LFloat3 { LFloat3(1, 0, 0) }
    var worldFront: LFloat3 { LFloat3(0, 0, -1) }
    
    let link: MetalLink
    let interceptor = KeyboardInterceptor()
    private var cancellables = Set<AnyCancellable>()
    
    enum ScrollLock: String, CaseIterable, Identifiable, Hashable {
        var id: Self { self }
        case horizontal
        case vertical
        case transverse
    }
    var holdingOption: Bool = false
    var startRotate: Bool = false
    
    var scrollLock: Set<ScrollLock> = []
    var notBlockingFromScroll: Bool { scrollLock.isEmpty }
    
    init(link: MetalLink) {
        self.link = link
        bindToLink()
        bindToInterceptor()
    }
    
    func bindToLink() {
        link.input.sharedKeyEvent.sink { event in
            self.interceptor.onNewKeyEvent(event)
        }.store(in: &cancellables)
        
        link.input.sharedMouseDown.sink { event in
            guard self.notBlockingFromScroll else { return }
            
            print("mouse down")
            self.startRotate = true
        }.store(in: &cancellables)
        
        link.input.sharedMouseUp.sink { event in
            guard self.notBlockingFromScroll else { return }
            
            print("mouse up")
            
            self.startRotate = false
        }.store(in: &cancellables)
        
        #if os(macOS)
        link.input.sharedScroll.sink { event in
            let sensitivity: Float = default_MovementSpeed
            let sensitivityModified = default_ModifiedMovementSpeed
            
            let speedModified = self.interceptor.state.currentModifiers.contains(.shift)
            let inOutModifier = self.interceptor.state.currentModifiers.contains(.option)
            let multiplier = speedModified ? sensitivityModified : sensitivity
            
            var dX: Float { -event.scrollingDeltaX.float * multiplier }
            var dY: Float { inOutModifier ? 0 : event.scrollingDeltaY.float * multiplier }
            var dZ: Float { inOutModifier ? -event.scrollingDeltaY.float * multiplier : 0 }
            
            let delta = LFloat3(
                self.scrollLock.contains(.horizontal) ? 0.0 : dX,
                self.scrollLock.contains(.vertical) ? 0.0 : dY,
                self.scrollLock.contains(.transverse) ? 0.0 : dZ
            )
            
            self.interceptor.positions.travelOffset = delta
        }.store(in: &cancellables)
        #endif
        
        link.input.sharedMouse.sink { event in
            guard self.startRotate else { return }
            
            
            self.interceptor.positions.rotationDelta.y = event.deltaX.float / 5
            self.interceptor.positions.rotationDelta.x = event.deltaY.float / 5
        }.store(in: &cancellables)
    }
    
    func bindToInterceptor() {
        interceptor.positionSource = self
        
        interceptor.positions.$travelOffset.sink { total in
            var total = total
            if self.scrollLock.contains(.horizontal) { total.x = 0 }
            if self.scrollLock.contains(.vertical)   { total.y = 0 }
            if self.scrollLock.contains(.transverse) { total.z = 0 }
            
            self.moveCameraLocation(total / 100)
        }.store(in: &cancellables)
        
        interceptor.positions.$rotationDelta.sink { total in
            guard self.notBlockingFromScroll else { return }
            
            self.rotation += (total / 100)
        }.store(in: &cancellables)
    }
}

extension DebugCamera {
    func moveCameraLocation(_ dX: Float, _ dY: Float, _ dZ: Float) {
        var initialDirection = LFloat3(dX, dY, dZ)
        var rotationTransform = simd_mul(
            simd_quatf(angle: rotation.x, axis: X_AXIS),
            simd_quatf(angle: rotation.y, axis: Y_AXIS)
        )
        rotationTransform = simd_mul(
            rotationTransform,
            simd_quatf(angle: rotation.z, axis: Z_AXIS))
        
        initialDirection = simd_act(rotationTransform.inverse, initialDirection)
        position += initialDirection
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
            farZ: 5000
        )
//        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
//        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
//        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        return matrix
    }
    
    private func buildViewMatrix() -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        matrix.translate(vector: -position)
        return matrix
    }
}
