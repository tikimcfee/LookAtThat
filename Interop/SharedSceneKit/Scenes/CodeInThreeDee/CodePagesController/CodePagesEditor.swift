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
        
        struct Offset {
            var current: CGSize = .zero
            var last: CGSize = .zero
        }
        
        enum ResizeCorner: CaseIterable {
            case topLeft
            case botLeft
            case topRight
            case botRight
        }
        
        var resizeOffets: [ResizeCorner: Offset] = {
            ResizeCorner.allCases
                .reduce(into: [ResizeCorner: Offset]()) { map, type in
                    map[type] = Offset()
                }
        }()
        
        mutating func updateResize(
            _ corner: ResizeCorner,
            _ translation: CGSize,
            _ isFinal: Bool
        ) {
            var newResizeOffset = resizeOffets[corner, default: Offset()]
            switch corner {
            case .topLeft:
                newResizeOffset.current = translation.negated() + newResizeOffset.last
                rootPositionOffset = translation + rootPositionOffsetLast
                
            case .topRight:
                newResizeOffset.current = translation.negatedHeight() + newResizeOffset.last
                rootPositionOffset.height = translation.height + rootPositionOffsetLast.height
                
            case .botLeft:
                newResizeOffset.current = translation.negatedWidth() + newResizeOffset.last
                rootPositionOffset.width = translation.width + rootPositionOffsetLast.width
                
            case .botRight:
                newResizeOffset.current = translation + newResizeOffset.last
            }
            if isFinal {
                newResizeOffset.last = newResizeOffset.current
                rootPositionOffsetLast = rootPositionOffset
            }
            resizeOffets[corner] = newResizeOffset
        }
        
        var sumOffsetWidth: CGFloat {
            resizeOffets.reduce(into: CGFloat(0.0)) { total, pair in
                total += pair.value.current.width
            }
        }
        
        var sumOffsetHeight: CGFloat {
            resizeOffets.reduce(into: CGFloat(0.0)) { total, pair in
                total += pair.value.current.height
            }
        }
        
        func offsetWidth(original: CGSize) -> CGFloat {
            let total = original.width + sumOffsetWidth
            return total
        }
        
        func offsetHeight(original: CGSize) -> CGFloat {
            let total = original.height + sumOffsetHeight
            return total
        }
        
        var rootPositionOffsetLast: CGSize = .zero
        var rootPositionOffset: CGSize = .zero
        
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
        GeometryReader { reader in
            rootPositionableView
                .frame(
                    width: max(0, state.ui.offsetWidth(original: reader.size)),
                    height: max(0, state.ui.offsetHeight(original: reader.size))
                )
                .offset(state.ui.rootPositionOffset)
        }
    }
    
    var rootPositionableView: some View {
        VStack(alignment: .trailing, spacing: 0) {
//            actionsView.padding(4)
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox(.topLeft)
                    Spacer()
                    resizeBox(.topRight)
                }
            }
            coreEditorView
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox(.botLeft)
                    Spacer()
                    resizeBox(.botRight)
                }
            }
        }
    }
    
    func resizeBox(_ target: CodePagesPopupEditorState.UI.ResizeCorner) -> some View {
        Color.red
            .frame(width: 24.0, height: 24.0)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1,
                    coordinateSpace: .global
                ).onChanged {
                    state.ui.updateResize(target, $0.translation, false)
                }.onEnded {
                    state.ui.updateResize(target, $0.translation, true)
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
