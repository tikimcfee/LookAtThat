//
//  CodePagesEditorState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/17/22.
//

import SwiftUI
import Combine

class CodePagesPopupEditorState: ObservableObject {
    enum RootMode {
        case idol
        case editing(grid: CodeGrid, path: URL)
    }
    
    struct UI {
        
    }
    
    @Published var text: String = "No file opened."
    @Published var popupEditorVisible: Bool = false
    @Published var rootMode = RootMode.idol
    @Published var ui = UI()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $rootMode.sink(receiveValue: { mode in
            self.onRootModeChange(mode: mode)
        }).store(in: &cancellables)
    }
    
    func onRootModeChange(mode: RootMode) {
        switch mode {
        case .idol:
            print("Editor idling")
        case .editing(_, let path):
            load(path: path)
        }
    }
    
    func load(path toLoad: URL) {
        print("Loading editor file: \(toLoad.fileName)")
        let maybeText = try? String(contentsOf: toLoad)
        print("Loaded text count: \(maybeText?.count ?? -1)")
        guard let newText = maybeText else { return }
        self.text = newText
    }
}
