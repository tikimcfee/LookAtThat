//
//  SourceInfoPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import Combine
import SwiftUI

enum PanelSections: String, CaseIterable, Equatable, Comparable {
    case editor = "2D Editor"
    case directories = "Directories"
    case semanticCategories = "Semantic Categories"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case tappingControls = "Taps"
    case globalSearch = "Global Search"
    case windowControls = "Window Controls"
    static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
}

class SourceInfoPanelState: ObservableObject {
    struct Categories {
        var showGlobalMap: Bool = false
    }

    // Individual hovering stuff
    @Published var sourceInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    @Published var sourceGrid: CodeGrid?
    @Published var hoveredToken: String = ""
    
    // Current 'focus box' search input
    @Published var searchText: String = ""
    
    // Visible subsections
    var panelGroups = 3
    @Published private(set) var visiblePanelStates = AutoCache<PanelSections, FloatableViewMode>()
    @Published private(set) var visiblePanelSlices: [ArraySlice<PanelSections>] = []
    @Published private(set) var visiblePanels: Set<PanelSections> = [.windowControls, .directories] {
        didSet { updatePanelGroups() }
    }
    
    // Category pannel state
    @Published var categories: Categories = Categories()
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        updatePanelGroups()
        visiblePanelStates.source[.windowControls] = .displayedAsWindow
    }
}

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
extension SourceInfoPanelState {    
    func vendPanelBinding(_ panel: PanelSections) -> Binding<FloatableViewMode> {
        func makeNewBinding() -> Binding<FloatableViewMode> {
            Binding<FloatableViewMode>(
                get: {
                    self.visiblePanelStates.source[panel, default: .displayedAsSibling]
                },
                set: {
                    self.visiblePanelStates.source[panel] = $0
                }
            )
        }
        return makeNewBinding()
    }
    
    func vendPanelIsWindowBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: {
                    self.visiblePanelStates
                        .source[panel, default: .displayedAsSibling]
                     == .displayedAsWindow
                },
                set: { isSelected in
                    let newState = isSelected
                        ? FloatableViewMode.displayedAsWindow
                        : FloatableViewMode.displayedAsSibling
                    self.visiblePanelStates.source[panel] = newState
                }
            )
        }
        return makeNewBinding()
    }
    
    func vendPanelVisibleBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: { self.visiblePanels.contains(panel) },
                set: { isSelected in
                    switch isSelected {
                    case true: self.visiblePanels.insert(panel)
                    case false: self.visiblePanels.remove(panel)
                    }
                }
            )
        }
        return makeNewBinding()
    }
}

private extension SourceInfoPanelState {
    func updatePanelGroups() {
        guard !visiblePanels.isEmpty else {
            visiblePanelSlices = []
            return
        }
        let sortedPanelList = Array(visiblePanels).sorted(by: <)
        visiblePanelSlices = sortedPanelList
            .slices(sliceSize: panelGroups)
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
