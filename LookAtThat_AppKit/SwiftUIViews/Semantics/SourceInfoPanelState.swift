//
//  SourceInfoPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import Combine
import SwiftUI

enum PanelSections: CaseIterable, Equatable {
    case directories
    case semanticCategories
    case hoverInfo
    case tracingInfo
}

class SourceInfoPanelState: ObservableObject {
    @Published var sections: [PanelSections] = PanelSections.allCases
    @Published var error: SceneControllerError?
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var hoveredToken: String = ""
    @Published var searchText: String = ""
    
    private var bag = Set<AnyCancellable>()
    
    var searchBinding: Binding<String> {
        SceneLibrary.global.codePagesController
            .codeGridParser
            .query
            .searchBinding.binding
    }
    
    init() {
#if !TARGETING_SUI
        setupBindings()
#endif
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
        
        SceneLibrary.global.codePagesController.hoverInfoStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch (event) {
                case (.some(let info)):
                    self.sourceInfo = info
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}
