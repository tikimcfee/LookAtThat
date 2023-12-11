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
import SwiftGlyph
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
    
    var fileButtonName: String {
        if showFileBrowser {
            return "Hide"
        } else {
            return "\(browserState.files.first?.path.lastPathComponent ?? "No Files Selected")"
        }
    }
    
    private var splitView: some View {
        ZStack(alignment: .bottomTrailing) {
            GlobalInstances.createDefaultMetalView()
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showGitFetch) {
            GitHubClientView()
        }
        .sheet(isPresented: $showActions) {
            actionsContent
                .presentationDetents([.medium])
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            bottomSafeArea
        }
        .safeAreaInset(edge: .top) {
            topSafeArea
        }
        
    }
    var topSafeArea: some View {
        VStack(alignment: .trailing, spacing: 0) {
            AppStatusView(status: GlobalInstances.appStatus)
            controlsButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
    
    var bottomSafeArea: some View {
        VStack(alignment: .trailing, spacing: 0) {
            button(fileButtonName, "") {
                withAnimation(.snappy(duration: 0.333)) {
                    showFileBrowser.toggle()
                }
            }
            .zIndex(1)
            
            if showFileBrowser {
                browserPopup
                    .zIndex(2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var browserPopup: some View {
        VStack(alignment: .trailing, spacing: 0) {
            button(
                "Download from GitHub",
                "square.and.arrow.down.fill"
            ) {
                showGitFetch.toggle()
            }
            .padding(.top, 8)
            
            FileBrowserView(browserState: browserState)
                .frame(maxHeight: 320)
                .padding(.top, 8)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .bottom)
        ))
    }
    
    var controlsButton: some View {
        Image(systemName: "gearshape.fill")
            .renderingMode(.template)
            .foregroundStyle(.red.opacity(0.8))
            .padding(6)
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { showActions.toggle() }
    }
    
    var actionsContent: some View {
        List {
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
                    if !image.isEmpty {
                        Image(systemName: image)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        VStack {
            MobileAppRootView()
                .foregroundStyle(Color.primaryForeground)
        }
            
    }
}
#endif
