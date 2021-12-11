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
    @State var showFileBrowser = false
    
    var body: some View {
        return ZStack(alignment: .bottomTrailing) {
            ARKitRepresentableView(
                arView: SceneLibrary.global.sharedSceneView
            ).edgesIgnoringSafeArea(.all)

            VStack {
                Button(action: { showInfoView = true }) {
                    Text("📶").padding()
                }
                Button(action: { renderTest() }) {
                    Text("📜").padding()
                }
            }
        }.sheet(isPresented: $showInfoView) {
            MultipeerInfoView()
                .environmentObject(MultipeerConnectionManager.shared)
        }.sheet(isPresented: $showFileBrowser) {
            MultipeerInfoView()
                .environmentObject(MultipeerConnectionManager.shared)
        }
    }
    
    var sampleFilesUrl: URL {
        let bundleName = "SampleFiles.bundle"
        let mainBundlePath = Bundle.main.bundlePath
        let sampleFilesUrl = FileKitPath(mainBundlePath).url.appendingPathComponent(bundleName)
        return sampleFilesUrl
    }
    
    var sampleFilesKitPath: FileKitPath? {
        FileKitPath(url: sampleFilesUrl)
    }
    
    func renderTest() {
        
        guard let sampleFilesPath = sampleFilesKitPath else {
            return
        }
        
        SceneLibrary.global
            .codePagesController
            .onNewFileStreamEvent(.newMultiCommandRecursiveAll(
                sampleFilesPath,
                .allChildrenInNewPlane
            ))
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
