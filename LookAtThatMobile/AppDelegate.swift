//
//  AppDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import UIKit
import SwiftUI
import SwiftGlyph

@main
struct AppDelegate: App {
    
    var body: some Scene {
        WindowGroup(id: "glyphee") {
            MobileAppRootView()
                .environmentObject(MultipeerConnectionManager.shared)
                .onAppear {
                    // Set initial state on appearance
                    GlobalInstances.fileBrowser.loadRootScopeFromDefaults()
                    GlobalInstances.gridStore.gridInteractionState.setupStreams()
                    GlobalInstances.defaultRenderer.renderDelegate = GlobalInstances.swiftGlyphRoot
                }
                .onDisappear {
                    URL.dumpAndDescopeAllKnownBookmarks()
                }

            // Soon...
//            CubeARView()
        }
     }
}
