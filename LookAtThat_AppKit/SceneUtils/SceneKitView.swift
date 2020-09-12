import SceneKit
import Foundation

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
        sceneController.sceneView.backgroundColor = NSUIColor.gray
        return sceneController.sceneView
    }

    public func updateUIView(_ uiView: SCNView, context: NSUIPreview) {

    }
    #endif
}
