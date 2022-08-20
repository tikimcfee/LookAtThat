import SwiftUI
import SceneKit


struct MacAppRootView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global
    
    @State var showMultipeer: Bool = false
    @State var showMetal: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if showMetal {
                __METAL__body
            } else {
                __SCENE__body
            }
            
            Button("Swap Modes") {
                showMetal.toggle()
            }.padding(32.0)
        }
    }
    
    var __SCENE__body: some View {
        ZStack(alignment: .topTrailing) {
            // set focusable to work around a nil focus error
            // "This would eventually crash when the view is freed. The first responder will be set to nil"
            SceneKitRepresentableView(
                sceneView: library.sharedSceneView
            ).focusable()
            
            switch library.currentMode {
            case .source:
                VStack(alignment: .leading) {
                    extras()
                    HStack(alignment: .top) {
                        SourceInfoPanelView()
                    }.padding(.bottom, 4.0)
                }
            }
        }
    }
    
    var __METAL__body: some View {
        MetalView()
    }
    
    @ViewBuilder
    func extras() -> some View {
        HStack {
            if showMultipeer {
                MultipeerInfoView().frame(width: 256.0)
            }
            TestButtons_Debugging()
        }
    }
}
