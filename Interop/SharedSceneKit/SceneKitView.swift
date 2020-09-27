import SceneKit
import Foundation
import SwiftUI

public struct SceneKitView: NSUIRepresentable {

    let sceneView: SCNView
    let currentScene: SceneType

    #if os(OSX)
    public func makeNSView(context: Context) -> SCNView {
        print("==== Returning SceneKitView ====")
        return sceneView
    }

    public func updateNSView(_ nsView: SCNView, context: Context) {
        print("++++ Updating SceneKitView ++++")
        sceneView.scene = SceneLibrary.global.currentController.scene
    }
    #elseif os(iOS)
    public func makeUIView(context: NSUIPreview) -> SCNView {
        print("==== Returning SceneKitView ====")
        return sceneView
    }

    public func updateUIView(_ uiView: SCNView, context: NSUIPreview) {
        print("++++ Updating SceneKitView ++++")
        sceneView.scene = SceneLibrary.global.currentController.scene
    }
    #endif
}
