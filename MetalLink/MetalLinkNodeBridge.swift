//
//  MetalLinkNodeBridge.swift
//  LookAtThat_AppKit
//
//  Original code found at: https://stackoverflow.com/questions/37697939/metal-shader-with-scenekit-scnprogram
//  Wrapped by Ivan Lugo on 8/7/22.
//

import MetalKit
import SceneKit

class MetalLinkNodeBridge {
    lazy var defaultSceneProgram: SCNProgram = makeDefaultSceneProgram()
    
    private func makeDefaultSceneProgram() -> SCNProgram {
        let program = SCNProgram()
        program.vertexFunctionName = MetalLinkDefaultSceneNodeVertexName_Q
        program.fragmentFunctionName = MetalLinkDefaultSceneNodeFragmentName_Q
        return program
    }
    
    func attachedDefaultSceneProgram(_ node: SCNNode) {
        guard let material = node.geometry?.firstMaterial else {
            print("Node has no geometry for program: \(node.name ?? "no_name")")
            return
        }
        material.program = defaultSceneProgram
    }
}
