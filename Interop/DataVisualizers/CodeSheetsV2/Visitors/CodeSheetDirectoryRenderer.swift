//
//  CodeSheetDirectoryRenderer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

class CodeSheetDirectoryRenderer {
    lazy var directorySheet: CodeSheet = {
        CodeSheet()
            .backgroundColor(NSUIColor.black)
            .apply {
                $0.containerNode.position.z = -300
            }
    }()
    
    @discardableResult
    init(render results: [ParsingState], in sceneState: SceneState) {
        render(results, in: sceneState)
    }
    
    private func render(_ results: [ParsingState], in sceneState: SceneState) {
        results.forEach { result in
            
            // Makes the root node face the camera. Doesn't work as well as it sounds.
            //            let lookAtCamera = SCNLookAtConstraint(target: sceneState.cameraNode)
            //            lookAtCamera.localFront = SCNVector3Zero.translated(dZ: 1.0)
            //            pair.1.containerNode.constraints = [lookAtCamera]
            
            result.sheet.containerNode.position =
                SCNVector3Zero.translated(
                    dX: nextX + result.sheet.halfLengthX,
                    //                    dY: -pair.1.halfLengthY - nextY,
                    dY: nextY - result.sheet.halfLengthY,
                    dZ: nextZ
                )
            directorySheet.containerNode.addChildNode(result.sheet.containerNode)
        }
        directorySheet.sizePageToContainerNode(pad: 20.0)
        
        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(directorySheet.containerNode)
        }
    }
    
    
    // Placement calculations
    
    var lastChild: SCNNode? { directorySheet.containerNode.childNodes.last }
    var lastChildLengthX: VectorFloat { lastChild?.lengthX ?? 0.0 }
    var lastChildLengthY: VectorFloat { lastChild?.lengthY ?? 0.0 }
    
    var x = VectorFloat(-16.0)
    var nextX: VectorFloat {
        x += lastChildLengthX + 16
        return x
    }
    
    var y = VectorFloat(0.0)
    var nextY: VectorFloat {
        y += 0
        return y
    }
    
    var z = VectorFloat(15.0)
    var nextZ: VectorFloat {
        z += 0
        return z
    }
}

