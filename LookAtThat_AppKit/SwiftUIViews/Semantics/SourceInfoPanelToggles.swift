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
        VStack(alignment: .leading) {
            ForEach(PanelSections.sorted, id: \.self) { section in
                HStack {
                    Toggle(section.rawValue, isOn: state.vendPanelVisibleBinding(section))
                    Toggle("Windowed", isOn: state.vendPanelIsWindowBinding(section))
                }
            }
        }
        .fixedSize()
        .padding()
    }
}
