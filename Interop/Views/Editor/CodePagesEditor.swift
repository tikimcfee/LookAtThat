//
//  CodePagesLSPC.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import SwiftUI
import Combine
import BitHandling

struct CodePagesPopupEditor: View {
    @State var state: CodePagesPopupEditorState
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @ViewBuilder
    var body: some View {
        coreEditorView
    }
    
    var coreEditorView: some View {
        Text("Sorry, no editing for now.")
    }
    
    @ViewBuilder
    var actionsView: some View {
        HStack {
            Button("[x] Close", action: { state.popupEditorVisible = false })
            Button("[o] Open", action: { openAction() })
        }
    }
    
    func openAction() {
#if os(OSX)
        openFile { fileReslt in
            switch fileReslt {
            case let .success(url):
//                print("\n\n\t\tFile open disabled for now; render grid first and click: \(url)\n\n")
                state.load(path: url) // TODO: add an interaction to render the grid if it's not already visible
            case let .failure(error):
                print(error)
            }
        }
#endif
    }
    
}
