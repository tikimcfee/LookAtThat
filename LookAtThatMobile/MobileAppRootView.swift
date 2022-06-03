//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI
import ARKit

// TODO: Use this to make an iPad Layout
// seriously search is so easy.. dragging editing window
// .. SUI is legit fantastic.
// GlyphXR?
func idiom() {
    switch UIDevice.current.userInterfaceIdiom {
    case .phone:
        break
    case .pad:
        break
    case .mac:
        break
    default:
        break
    }
}

struct MobileAppRootView : View {
    @State var showInfoView = false
    @State var showGitFetch = false
    
    var body: some View {
        return ZStack(alignment: .bottomTrailing) {
            ARKitRepresentableView(
                arView: SceneLibrary.global.sharedSceneView
            ).edgesIgnoringSafeArea(.all)

            VStack(alignment: .trailing) {
                HStack {
                    Button(action: { showInfoView = true }) {
                        Text("📶").padding()
                    }
                    
                    Button(action: { showGitFetch = true }) {
                        Text("Fetch GitHub").padding()
                    }
                }
                TestButtons_Debugging()
                FileBrowserView()
                    .frame(maxHeight: 192.0)
            }
        }
        .sheet(isPresented: $showGitFetch) {
            GitHubClientView()
        }
        .sheet(isPresented: $showInfoView) {
            MultipeerInfoView()
                .environmentObject(MultipeerConnectionManager.shared)
        }
    }
}

class ARViewDelegate: NSObject, ARSCNViewDelegate {
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
        config.planeDetection = [.horizontal, .vertical]
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                               ARSCNDebugOptions.showWorldOrigin]
        arView.autoenablesDefaultLighting  = true
        arView.delegate = delegate
        arView.scene = SceneLibrary.global.currentController.scene
        arView.session.run(config)
        
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
