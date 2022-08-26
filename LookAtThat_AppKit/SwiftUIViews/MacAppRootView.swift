import SwiftUI

struct MacAppRootView: View {
    @ObservedObject var library: SceneLibrary = SceneLibrary.global
    
    @State var showMultipeer: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            __METAL__body
            
            VStack {
                extras()
                HStack(alignment: .top) {
                    SourceInfoPanelView()
                }.padding(.bottom, 4.0)
                
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
        }
    }
}
