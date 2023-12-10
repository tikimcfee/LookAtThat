//
//  AppDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import UIKit
import SwiftUI
import SwiftGlyphs

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
                    GlobalInstances.defaultRenderer.renderDelegate = GlobalInstances.swiftGlyphsRoot
                }
                .onDisappear {
                    URL.dumpAndDescopeAllKnownBookmarks()
                }

            // Soon...
//            CubeARView()
        }
     }
}
