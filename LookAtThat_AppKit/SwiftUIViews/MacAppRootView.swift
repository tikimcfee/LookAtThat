import SwiftUI
import SceneKit

let __MAC_APP_TEST_METAL = true

struct MacAppRootView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global
    
    @State var showMultipeer: Bool = false

    var body: some View {
        if __MAC_APP_TEST_METAL {
            __METAL__body
        } else {
            __SCENE__body
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
