//
//  CodePagesARRenderer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import ARHeadsetKit
import Metal

class MyRenderer: CustomRenderer {
    unowned let renderer: MainRenderer
    
    required init(renderer: MainRenderer, library: MTLLibrary!) {
        self.renderer = renderer
    }
    
    func updateResources() {
        let object = ARObject(shapeType: .cone,
                              position: [0.0, 0.0, 0.0],
                              scale: [0.2, 0.2, 0.2])
        
        centralRenderer.render(object: object)
    }
    
    func drawGeometry(renderEncoder: ARMetalRenderCommandEncoder) {
        
    }
}
