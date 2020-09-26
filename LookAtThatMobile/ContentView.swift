//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI
import ARKit

struct ContentView : View {
    var body: some View {
        return MultipeerInfoView()
//        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

class ARViewDelegate: NSObject, ARSCNViewDelegate {
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        return nil
//    }

    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {

    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

    }
}

struct ARViewContainer: UIViewRepresentable {

    let scene = SCNScene()
    let delegate = ARViewDelegate()
    
    func makeUIView(context: Context) -> ARSCNView {
        
        let arView = ARSCNView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                               ARSCNDebugOptions.showWorldOrigin]
        arView.autoenablesDefaultLighting  = true
        arView.delegate = delegate
        arView.scene = scene
        arView.session.run(config)

        let scnBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.025)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        scnBox.materials = [material]

        let scnNode = SCNNode(geometry: scnBox)
        scnNode.position = SCNVector3Make(0, 0, -0.2)
        scene.rootNode.addChildNode(scnNode)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
