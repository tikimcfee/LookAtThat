//
//  SourceInfoPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import Combine
import SwiftUI

enum PanelSections: String, CaseIterable, Equatable, Comparable, Codable {
    case editor = "2D Editor"
    case directories = "Directories"
    case semanticCategories = "Semantic Categories"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case globalSearch = "Global Search"
    case windowControls = "Window Controls"
    case appStatusInfo = "App Status Info"
    case gridStateInfo = "Grid State Info"
    case githubTools = "GitHub Tools"
    case focusState = "Focus State"
    case wordInput = "Word Input"
    static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
}

class SourceInfoPanelState: ObservableObject {
    // Category pannel state
    struct Categories {
        var expandedGrids = Set<CodeGrid.ID>()
    }
    @Published var categories: Categories = Categories()

    // Visible subsections
    @Published private(set) var visiblePanelStates = CodableAutoCache<PanelSections, FloatableViewMode>() {
        didSet {
            savePanelWindowStates()
        }
    }
    
    @Published private(set) var visiblePanels: Set<PanelSections> {
        didSet {
            savePanelStates()
            updatePanelSlices()
        }
    }
    
    var panelGroups = 3
    @Published private(set) var visiblePanelSlices: [ArraySlice<PanelSections>] = []
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        self.visiblePanels = AppStatePreferences.shared.visiblePanels
            ?? [.windowControls, .directories, .appStatusInfo]
        self.visiblePanelStates = AppStatePreferences.shared.panelStates
            ?? {
                var states = CodableAutoCache<PanelSections, FloatableViewMode>()
                states.source[.windowControls] = .displayedAsWindow
                states.source[.directories] = .displayedAsWindow
                states.source[.appStatusInfo] = .displayedAsWindow
                return states
            }()
        
        setupBindings()
        updatePanelSlices()
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
    func isWindow(_ panel: PanelSections) -> Bool {
        visiblePanelStates.source[panel] == .displayedAsWindow
    }
    
    func isVisible(_ panel: PanelSections) -> Bool {
        visiblePanels.contains(panel)
    }
    
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
    func updatePanelSlices() {
        guard !visiblePanels.isEmpty else {
            visiblePanelSlices = []
            return
        }
        let sortedPanelList = Array(visiblePanels).sorted(by: <)
        visiblePanelSlices = sortedPanelList
            .slices(sliceSize: panelGroups)
    }
    
    func savePanelStates() {
        AppStatePreferences.shared.visiblePanels = visiblePanels
    }
    
    func savePanelWindowStates() {
        AppStatePreferences.shared.panelStates = visiblePanelStates
    }
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
