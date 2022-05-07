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
    @Published var sections: [PanelSections] = [.directories]
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
        SceneLibrary.global.codePagesController.hoverStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink {
                self.hoveredToken = $0
            }
            .store(in: &bag)
        
        Publishers.CombineLatest(SceneLibrary.global.codePagesController.hoverInfoStream,
                                 SceneLibrary.global.codePagesController.hoverGridStream)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { tupleEvent in
                self.sourceInfo = tupleEvent.0 ?? self.sourceInfo
                self.sourceGrid = tupleEvent.1
            }
            .store(in: &bag)
    }
}
