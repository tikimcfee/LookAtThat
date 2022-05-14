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
    
    public func negated() -> CGSize {
        CGSize(width: width * -1, height: height * -1)
    }
    
    public func negatedWidth() -> CGSize {
        CGSize(width: width * -1, height: height)
    }
    
    public func negatedHeight() -> CGSize {
        CGSize(width: width, height: height * -1)
    }
}

class CodePagesPopupEditorState: ObservableObject {
    enum RootMode {
        case idol
        case editing(grid: CodeGrid, path: FileKitPath)
    }
    
    struct UI {
        enum Mode {
            case floating
            case asSibling
        }
        
        var mode: Mode = .asSibling
    }
    
    @Published var text: String = "No file opened."
    @Published var position: CodeEditor.Position  = CodeEditor.Position()
    @Published var messages: Set<Located<Message>> = Set()
    
    @Published var popupEditorVisible: Bool = false
    @Published var rootMode = RootMode.idol
    @Published var ui = UI()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $rootMode.sink(receiveValue: { mode in
            self.onRootModeChange(mode: mode)
        }).store(in: &cancellables)
    }
    
    fileprivate func onRootModeChange(mode: RootMode) {
        switch mode {
        case .idol:
            print("Editor idling")
        case .editing(_, let path):
            load(path: path)
        }
    }
    
    fileprivate func load(path toLoad: FileKitPath) {
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
    
    @ViewBuilder
    var body: some View {
        switch state.ui.mode {
        case .asSibling:
            rootSiblingGeometryReader
        case .floating:
            coreEditorView
        }
    }
    
    var rootSiblingGeometryReader: some View {
        coreEditorView
            .modifier(DragSizableModifer())
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
//                print("\n\n\t\tFile open disabled for now; render grid first and click: \(url)\n\n")
                guard let path = FileKitPath(url: url) else {
                    print("Could not load path: \(url)")
                    return
                }
                state.load(path: path) // TODO: add an interaction to render the grid if it's not already visible
            case let .failure(error):
                print(error)
            }
        }
#endif
    }
    
}
