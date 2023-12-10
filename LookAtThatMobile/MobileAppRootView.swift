//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import MetalLinkResources
import SwiftGlyphs
import BitHandling

private extension MobileAppRootView {
    var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
}

struct MobileAppRootView : View {
    enum Tab {
        case metalView
        case actions
    }
    
    @State var showGitFetch = false
    @State var showFileBrowser = false
    @State var showActions = false
    
    @State var tab: Tab = .metalView
    
    @StateObject var browserState = FileBrowserViewState()
    
    var body: some View {
        splitView
    }
    
    private var splitView: some View {
        ZStack(alignment: .bottomTrailing) {
            GlobalInstances.createDefaultMetalView()
            
            AppStatusView(status: GlobalInstances.appStatus)
            
            controlsButton
                .padding()
        }
        .sheet(isPresented: $showGitFetch) {
            GitHubClientView()
        }
        .sheet(isPresented: $showFileBrowser) {
            FileBrowserView(browserState: browserState)
        }
        .sheet(isPresented: $showActions) {
            actionsContent
                .presentationDetents([.medium])
        }
    }
    
    var controlsButton: some View {
        Image(systemName: "gearshape.fill")
            .renderingMode(.template)
            .foregroundStyle(.red.opacity(0.8))
            .padding()
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { showActions.toggle() }
    }
    
    var actionsContent: some View {
        List {
            button(
                "Download from GitHub",
                "square.and.arrow.down.fill"
            ) { showGitFetch.toggle() }
            
            button(
                "Browse files in [\(browserState.files.first?.path.lastPathComponent ?? "..")]]",
                ""
            ) { showFileBrowser.toggle() }
            
            
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
    }
    
    func button(
        _ text: String,
        _ image: String,
        _ action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                HStack {
                    Text(text)
                    Image(systemName: image)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MobileAppRootView()
    }
}
#endif
