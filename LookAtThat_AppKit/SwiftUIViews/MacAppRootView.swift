import SwiftUI

struct MacAppRootView: View {
    @State var showMultipeer: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let metal = __METAL__body {
                metal
            } else {
                EmptyView()
            }
            
            VStack {
                extras()
                HStack(alignment: .top) {
                    SourceInfoPanelView()
                }.padding(.bottom, 4.0)
                
            }
        }
    }
    
    var __METAL__body: MetalView? {
        do {
            return try MetalView()
        } catch {
            print(error)
            return nil
        }
        
    }
    
    @ViewBuilder
    func extras() -> some View {
        EmptyView()
    }
}
