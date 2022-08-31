//
//  CodePagesLSPC.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import SwiftUI
import CodeEditorView
import Combine

struct CodePagesPopupEditor: View {
    @State var state: CodePagesPopupEditorState
    @State var position: CodeEditor.Position = CodeEditor.Position()
    @State var messages: Set<Located<Message>> = Set()
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @ViewBuilder
    var body: some View {
        coreEditorView
    }
    
    var coreEditorView: some View {
        CodeEditor(
            text: $state.text,
            position: $position,
            messages: $messages,
            language: .swift,
            layout: .init(showMinimap: false)
        )
        .frame(minWidth: 128.0, minHeight: 64.0)
        .environment(
            \.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight
        )
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
