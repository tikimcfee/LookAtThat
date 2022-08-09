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
    func update(deltaTime: Float)
}

extension MetalLinkCamera {
    var viewMatrix: matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.translate(vector: -position)
        return matrix
    }
}

class DebugCamera: MetalLinkCamera {
    var type: MetalLinkCameraType = .Debug
    var position: LFloat3 = .zero
    
    let link: MetalLink
    private var cancellables = Set<AnyCancellable>()
    
    init(link: MetalLink) {
        self.link = link
        link.input.sharedKeyEvent.sink { event in
            
        }.store(in: &cancellables)
    }
    
    func handleKeyEvent(_ event: NSEvent) {
        
    }
    
    func update(deltaTime: Float) {
        
    }
}
