//
//  SourceInfoPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import Combine
import SwiftUI

enum PanelSections: String, CaseIterable, Equatable {
    case editor = "2D Editor"
    case directories = "Directories"
    case semanticCategories = "Semantic Categories"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case tappingControls = "Taps"
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
}

class SourceInfoPanelState: ObservableObject {
    struct Categories {
        var showGlobalMap: Bool = false
    }
    
    @Published var error: SceneControllerError?
    
    // Individual hovering stuff
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var sourceGrid: CodeGrid?
    @Published var hoveredToken: String = ""
    
    // Current 'focus box' search input
    @Published var searchText: String = ""
    
    // Visible subsections
    @Published var panels: Set<PanelSections> = [.directories]
    
    // Category pannel state
    @Published var categories: Categories = Categories()
    
    private var bag = Set<AnyCancellable>()
    
    init() {
#if !TARGETING_SUI
        setupBindings()
#endif
    }
    
    func show(_ panel: PanelSections) -> Bool {
        panels.contains(panel)
    }
    
    func vendBinding(_ panel: PanelSections) -> Binding<Bool> {
        // Don't cache bindings!
        // This is weird, but the bindings must be recreated
        // in current view flow. This is likely from me doing
        // weird things with FloatableView.
        // Seriously, maybe just WindowGroup? But it REALLY looks...
        // just eww right now.
        
        // This is also popping up in the editor itself, which isn't
        // immediately updating it's view text; it only refreshes
        // when the view is focused again.
        
        // Gosh darn it fine I'll try WindowGroups soon.
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: { self.panels.contains(panel) },
                set: { isSelected in
                    switch isSelected {
                    case true: self.panels.insert(panel)
                    case false: self.panels.remove(panel)
                    }
                }
            )
        }
        return makeNewBinding()
    }
    
    func setupBindings() {
        CodePagesController.shared.hover.$state
            .receive(on: DispatchQueue.main)
            .sink {
                self.hoveredToken = $0.hoveredTokenId ?? self.hoveredToken
                self.sourceInfo = $0.hoveredInfo
                self.sourceGrid = $0.hoveredGrid
            }
            .store(in: &bag)
    }
}
