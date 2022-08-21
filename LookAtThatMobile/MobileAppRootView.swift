//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI

#if os(iOS)
import ARKit
#endif

let __MOBILE_APP_TEST_METAL = true

private extension MobileAppRootView {
    static var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
    static var keyEvent: OSEvent {
        get { receiver.lastKeyEvent }
        set { receiver.lastKeyEvent  = newValue }
    }
}

struct MobileAppRootView : View {
    @State var showInfoView = false
    @State var showGitFetch = false
    
    @State var touchStart: CGPoint? = nil
    
    private let delta = CGFloat(20)
    
    var body: some View {
        if __MOBILE_APP_TEST_METAL {
            __MetalBody__
        } else {
            __ARKitBody__
        }
    }
    
    var __MetalBody__: some View {
        ZStack(alignment: .topLeading) {
            MetalView()
            
            #if os(macOS)
            Spacer()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray)
            #endif
            
            if let touch = touchStart {
                Circle()
                    .foregroundColor(Color.red)
                    .frame(width: 32, height: 32)
                    .offset(x: touch.x - 16, y: touch.y - 16)
                    .shadow(color: .red, radius: 3.0)
            }
        }.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { change in
                    if touchStart == nil { touchStart = change.startLocation }
                    
                    #if os(iOS)
                    if change.translation.width < -delta {
                        Self.keyEvent = .RightDragKeyup
                        Self.keyEvent = .LeftDragKeydown
                    } else {
                        Self.keyEvent = .LeftDragKeyup
                    }
                    
                    
                    if change.translation.width > delta {
                        Self.keyEvent = .LeftDragKeyup
                        Self.keyEvent = .RightDragKeydown
                    } else {
                        Self.keyEvent = .RightDragKeyup
                    }
                    
                    if change.translation.height < -delta {
                        Self.keyEvent = .UpDragKeyup
                        Self.keyEvent = .DownDragKeydown
                    } else {
                        Self.keyEvent = .DownDragKeyup
                    }
                    
                    if change.translation.height > delta {
                        Self.keyEvent = .DownDragKeyup
                        Self.keyEvent = .UpDragKeydown
                    } else {
                        Self.keyEvent = .UpDragKeyup
                    }
                    #endif
                }
                .onEnded { _ in
                    touchStart = nil
                    
                    #if os(iOS)
                    Self.keyEvent = .UpDragKeyup
                    Self.keyEvent = .DownDragKeyup
                    Self.keyEvent = .LeftDragKeyup
                    Self.keyEvent = .RightDragKeyup
                    Self.keyEvent = .InDragKeyup
                    Self.keyEvent = .OutDragKeyup
                    #endif
                }
        )
    }
    
    var __ARKitBody__: some View {
        return ZStack(alignment: .bottomTrailing) {
#if os(iOS)
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
#endif
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

#if os(iOS)
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
#endif

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MobileAppRootView()
    }
}
#endif
