import SwiftUI
import MetalLink
import SwiftGlyphs

struct MacAppRootView: View {
    @State var showMultipeer: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            GlobalInstances.createDefaultMetalView()
            
            SourceInfoPanelView()
            
            VStack(alignment: .leading) {
                Button("Preload Glyph Atlas") {
                    GlobalInstances.defaultAtlas.preload()
                }
                
                Button("Save Glyph Atlas") {
                    GlobalInstances.defaultAtlas.save()
                }
                
                Button("Reset (delete) atlas") {
                    GlobalInstances.resetAtlas()
                }
            }
            .padding(4)
        }
    }
    
    @ViewBuilder
    func extras() -> some View {
        EmptyView()
    }
}
