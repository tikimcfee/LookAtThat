//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI

#if os(iOS)
import ARKit
#endif
import MetalLink
import MetalLinkResources
import SwiftGlyphs

private extension MobileAppRootView {
    var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
}

struct MobileAppRootView : View {
    
    @State var showGitFetch = false
    @State var showFileBrowser = false
    
    @StateObject var browserState = FileBrowserViewState()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GlobalInstances.createDefaultMetalView()
            
            VStack(alignment: .trailing) {
                AppStatusView(status: GlobalInstances.appStatus)
                
                Spacer()
                
                button(
                    "Download from GitHub",
                    "square.and.arrow.down.fill"
                ) { showGitFetch.toggle() }
                
                button(
                    "Browse files in [\(browserState.files.first?.path.lastPathComponent ?? "..")]]",
                    ""
                ) { showFileBrowser.toggle() }
            }
            .padding()
        }
        .sheet(isPresented: $showGitFetch) {
            GitHubClientView()
        }
        .sheet(isPresented: $showFileBrowser) {
            FileBrowserView(browserState: browserState)
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
