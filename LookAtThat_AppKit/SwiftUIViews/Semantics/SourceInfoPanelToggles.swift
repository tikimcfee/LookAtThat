//
//  SourceInfoPanelToggles.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/15/22.
//

import SwiftUI

struct SourceInfoPanelToggles: View {
    @ObservedObject var state: SourceInfoPanelState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            VStack(alignment: .leading) {
                ForEach(PanelSections.sorted, id: \.self) { section in
                    sectionRow(section)
                    Divider()
                }
            }
        }
        .fixedSize()
        .padding()
    }
    
    @ViewBuilder
    func sectionRow(_ section: PanelSections) -> some View {
        HStack {
            Text("\(section.rawValue)")
                .frame(minWidth: 160.0, alignment: .leading)
            dockControl(section)
            visibilityControl(section)
        }
    }
    
    @ViewBuilder
    func dockControl(_ section: PanelSections) -> some View {
        Toggle("Window", isOn: state.vendPanelIsWindowBinding(section))
    }
    
    @ViewBuilder
    func visibilityControl(_ section: PanelSections) -> some View {
        switch section {
        case .windowControls:
            Spacer()
        default:
            Toggle("Visible", isOn: state.vendPanelVisibleBinding(section))
        }
    }
}

struct SourceInfoPanelToggles_Preview: PreviewProvider {
    static let state = SourceInfoPanelState()
    static var previews: some View {
        return SourceInfoPanelToggles(state: state)
    }
}
