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
                Toggle(section.rawValue, isOn: state.vendBinding(section))
            }
        }
        .fixedSize()
        .padding()
    }
}
