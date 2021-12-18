//
//  TestButtonsView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SwiftUI

struct TestButtons_Debugging: View {
#if os(iOS)
    var body: some View {
        HStack {
            Button(action: toggleBoundingBoxes) {
                Text("🔳")
            }
            Button(action: dumpLogs) {
                Text("LZT")
            }
            Button(action: resetScene) {
                Text("Reset")
            }
        }
    }

#elseif os(macOS)
    var body: some View {
        HStack {
            Text("Debugging").padding()
            Button(action: toggleBoundingBoxes) {
                Text("Toggle bounds")
            }
            Button(action: dumpLogs) {
                Text("Dump LaZTrace")
            }
            Button(action: resetScene) {
                Text("Reset scene")
            }
//            Button(action: dictionaryDemo) {
//                Text("Dictionary demo")
//            }
//            Button(action: sourceDemo) {
//                Text("Source demo")
//            }
        }
    }
#endif

    
    private func dictionaryDemo() {
        SceneLibrary.global.dictionary()
    }
    
    private func sourceDemo() {
        SceneLibrary.global.codePages()
    }
    
    private func toggleBoundingBoxes() {
        SceneLibrary.global.currentController.toggleBoundingBoxes()
    }
    
    private func resetScene() {
        SceneLibrary.global.currentController.resetScene()
    }
    
    private func dumpLogs() {
        lazdump()
    }
}
