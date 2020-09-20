import SceneKit
import Foundation
import SwiftUI

public struct SceneKitView: NSUIRepresentable {

    let sceneController: MainSceneController

    #if os(OSX)
    public func makeNSView(context: Context) -> SCNView {
        return sceneController.sceneView
    }

    public func updateNSView(_ nsView: SCNView, context: Context) {

    }
    #elseif os(iOS)
    public func makeUIView(context: NSUIPreview) -> SCNView {
        return sceneController.sceneView
    }

    public func updateUIView(_ uiView: SCNView, context: NSUIPreview) {

    }
    #endif
}
