//
//  CodePagesLSPC.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import SwiftUI
import CodeEditorView
import Combine

extension CGSize: AdditiveArithmetic {
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width,
                      height: lhs.height - rhs.height)
    }
    
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width,
                      height: lhs.height + rhs.height)
    }
}

class CodePagesPopupEditorState: ObservableObject {
    struct Files {
        var currentFile: FileKitPath?
    }
    
    struct UI {
        var rootPositionOffsetLast: CGSize = .zero
        var rootPositionOffset: CGSize = .zero
        { didSet { print(rootPositionOffset) } }
        
        var resizeOffsetLast: CGSize = .zero
        var resizeOffset: CGSize = .zero
    }
    
    @Published var text: String = "No file opened."
    @Published var position: CodeEditor.Position  = CodeEditor.Position()
    @Published var messages: Set<Located<Message>> = Set()
    
    @Published var popupEditorVisible: Bool = false
    @Published var files = Files()
    @Published var ui = UI()
    
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
        GeometryReader { reader in
            rootPositionableView
                .frame(
                    width: max(0, reader.size.width + state.ui.resizeOffset.width),
                    height: max(0, reader.size.height + state.ui.resizeOffset.height)
                )
                .offset(state.ui.rootPositionOffset)
        }
    }
    
    var rootPositionableView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox
                    Spacer()
                    resizeBox
                }
            }
            coreEditorView
            actionsView.padding(4)
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox
                    Spacer()
                    resizeBox
                }
            }
        }
    }
    
    var resizeBox: some View {
        Color.red
            .frame(width: 24.0, height: 24.0)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1,
                    coordinateSpace: .global
                ).onChanged {
                    state.ui.resizeOffset = $0.translation + state.ui.resizeOffsetLast
                }.onEnded { _ in
                    state.ui.resizeOffsetLast = state.ui.resizeOffset
                }
            )
    }
    
    var dragBar: some View {
        Color.green
            .frame(maxWidth: .infinity, maxHeight: 24.0)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1,
                    coordinateSpace: .global
                ).onChanged {
                    state.ui.rootPositionOffset = $0.translation + state.ui.rootPositionOffsetLast
                }.onEnded { _ in
                    state.ui.rootPositionOffsetLast = state.ui.rootPositionOffset
                }
            )
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
