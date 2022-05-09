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
    case directories = "Directories"
    case semanticCategories = "Semantic Categories"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case tappingControls = "Taps"
}

class SourceInfoPanelState: ObservableObject {
    @Published var sections: [PanelSections] = [.directories, .hoverInfo]
    @Published var error: SceneControllerError?
    
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var sourceGrid: CodeGrid?
    @Published var hoveredToken: String = ""
    @Published var searchText: String = ""
    
    private var bag = Set<AnyCancellable>()
    
    init() {
#if !TARGETING_SUI
        setupBindings()
#endif
    }
    
    func sectionControlTitle(_ section: PanelSections) -> String {
        return sections.contains(section)
            ? "Hide \(section.rawValue)"
            : "Show \(section.rawValue)"
    }
    
    func toggleSection(_ section: PanelSections) {
        if sections.contains(section) {
            sections.removeAll(where: { $0 == section })
        } else {
            sections.append(section)
        }
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
