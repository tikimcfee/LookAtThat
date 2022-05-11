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
//    @Published var sections: [PanelSections] = [.directories, .hoverInfo]
    @Published var error: SceneControllerError?
    
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var sourceGrid: CodeGrid?
    @Published var hoveredToken: String = ""
    @Published var searchText: String = ""
    @Published var panels: Set<PanelSections> = [.directories, .hoverInfo]
    
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
