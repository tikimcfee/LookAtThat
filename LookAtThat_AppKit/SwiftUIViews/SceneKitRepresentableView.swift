import SceneKit
import Foundation
import SwiftUI

public struct SceneKitRepresentableView: NSViewRepresentable {

    let sceneView: SCNView

    public func makeNSView(context: Context) -> SCNView {
//        print("==== Returning SceneKitView ====")
        DispatchQueue.main.async { // wait till next event cycle
            sceneView.window?.makeFirstResponder(sceneView)
        }
        return sceneView
    }

    public func updateNSView(_ nsView: SCNView, context: Context) {
//        print("++++ Updating SceneKitView ++++")
        sceneView.scene = SceneLibrary.global.currentController.scene
    }
}
