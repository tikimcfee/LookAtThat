import SwiftUI

struct MacAppRootView: View {
    @State var showMultipeer: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MetalView()
            
            VStack {
                extras()
                HStack(alignment: .top) {
                    SourceInfoPanelView()
                }.padding(.bottom, 4.0)
                
            }
        }
    }
    
    @ViewBuilder
    func extras() -> some View {
        EmptyView()
    }
}
