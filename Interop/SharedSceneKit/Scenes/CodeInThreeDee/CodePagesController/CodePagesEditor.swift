//
//  CodePagesLSPC.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import SwiftUI
import CodeEditorView
import Combine

class CodePagesPopupEditorState: ObservableObject {
    struct Files {
        var currentFile: FileKitPath?
    }
    
    @Published var text: String = "No file opened."
    @Published var position: CodeEditor.Position  = CodeEditor.Position()
    @Published var messages: Set<Located<Message>> = Set()
    
    @Published var centerOffset = CGPoint(x: 0, y: 0)
    @Published var topLeftOffset = CGPoint(x: 0, y: 0)
    
    @Published var files = Files()
    @Published var popupEditorVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $files.sink(receiveValue: { files in
            self.load(files: files)
        }).store(in: &cancellables)
    }
    
    private func load(files: Files) {
        guard let toLoad = files.currentFile else { return }
        print("Loading editor file: \(toLoad.fileName)")
        let maybeText = try? String(contentsOf: toLoad.url)
        print("Loaded text count: \(maybeText?.count ?? -1)")
        guard let newText = maybeText else { return }
        self.text = newText
    }
}

struct CodePagesPopupEditor: View {
    @ObservedObject var state: CodePagesPopupEditorState
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    var body: some View {
//        GeometryReader { reader in
//            coreEditorView
//                .position(x: reader.size.width / 2.0 + state.centerOffset.x,
//                          y: reader.size.height / 2.0 + state.centerOffset.y)
//        }
        ZStack(alignment: .topTrailing) {
            coreEditorView
            actionsView
                .padding(4)
        }
    }
    
    var coreEditorView: some View {
        CodeEditor(
            text: $state.text,
            position: $state.position,
            messages: $state.messages,
            language: .swift,
            layout: .init(showMinimap: false)
        ).environment(
            \.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight
        )
    }
    
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
                state.files.currentFile = FileKitPath(url: url)
            case let .failure(error):
                print(error)
            }
        }
#endif
    }
    
}
