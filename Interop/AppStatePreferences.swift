//
//  AppStatePreferences.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/26/22.
//

import Foundation
import BitHandling

extension AppStatePreferences {
    var panelStates: CodableAutoCache<PanelSections, FloatableViewMode>? {
        get { _getEncoded(.panelStates) }
        set { _setEncoded(newValue, .panelStates) }
    }
    
    var visiblePanels: Set<PanelSections>? {
        get { _getEncoded(.panelSections) }
        set { _setEncoded(newValue, .panelSections) }
    }
}
