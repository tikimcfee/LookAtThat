//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI
import ARKit

struct MobileAppRootView : View {
    @State var showInfoView = false
    var body: some View {
        return ZStack(alignment: .bottomTrailing) {
            ARKitRepresentableView(
                arView: SceneLibrary.global.sharedSceneView
            ).edgesIgnoringSafeArea(.all)

            Button(action: { showInfoView = true }) {
                Text("📶").padding()
            }
        }.sheet(isPresented: $showInfoView) {
            MultipeerInfoView().environmentObject(MultipeerConnectionManager.shared)
        }
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

struct ARKitRepresentableView: UIViewRepresentable {

    let arView: ARSCNView
    let delegate = ARViewDelegate()
    
    func makeUIView(context: Context) -> ARSCNView {

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                               ARSCNDebugOptions.showWorldOrigin]
        arView.autoenablesDefaultLighting  = true
        arView.delegate = delegate
        arView.scene = SceneLibrary.global.currentController.scene
        arView.session.run(config)

        let testBox = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.25)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        testBox.materials = [material]
        let testBoxNode = SCNNode(geometry: testBox)
        testBoxNode.categoryBitMask = HitTestType.codeSheet

        let parentNode = SCNNode()
        parentNode.addChildNode(testBoxNode)
        parentNode.position = SCNVector3Make(0, 0, -0.2)

        arView.scene.rootNode.addChildNode(parentNode)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {

    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MobileAppRootView()
    }
}
#endif