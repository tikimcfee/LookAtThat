//
//  WorldFocusView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import SwiftUI

struct WorldFocusView: View {
    @ObservedObject var focus: WorldGridFocusController
    
    var body: some View {
        focusList
    }
    
    @ViewBuilder
    var focusList: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(focus.focusableGrids, id: \.targetGrid.id) { relationship in
                    HStack {
                        Text(relationship.direction.rawValue)
                        Spacer().frame(width: 32)
                        Text(relationship.targetGrid.fileName)
                    }
                    .padding()
                }
            }
        }
//        .frame(minWidth: 640, minHeight: 320)
        .padding()
        .border(.gray, width: 1.0)
    }
}

struct WorldFocusView_Previews: PreviewProvider {
    static var testFocus: WorldGridFocusController {
        WorldGridFocusController(
            link: GlobalInstances.defaultLink,
            camera: GlobalInstances.debugCamera,
            editor: GlobalInstances.gridStore.editor
        )
    }
    
    static var previews: some View {
        WorldFocusView(
            focus: testFocus
        )
    }
}
