import SwiftUI
import MetalLink

struct MacAppRootView: View {
    @State var showMultipeer: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            GlobalInstances.createDefaultMetalView()
            
            SourceInfoPanelView()
        }
    }
    
    @ViewBuilder
    func extras() -> some View {
        EmptyView()
    }
}
