import SwiftUI
import SceneKit

struct MacAppRootView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global
    
    @State var showMultipeer: Bool = false

    var body: some View {
        return ZStack(alignment: .topTrailing) {
            SceneKitRepresentableView(
                sceneView: library.sharedSceneView
            ).focusable() // set focusable to work around a nil focus error
                          // "This would eventually crash when the view is freed. The first responder will be set to nil"
            
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
