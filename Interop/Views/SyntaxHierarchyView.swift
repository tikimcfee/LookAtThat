//
//  SyntaxHierarchyView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/8/22.
//

import SwiftUI

struct SyntaxHierarchyView: View {
    @State var lastState: PickingState?
    var hoveredId: String { lastState?.nodeSyntaxID ?? "" }
    
    var body: some View {
        hoveredNodeInfoView(hoveredId)
            .onReceive(
                GlobalInstances.gridStore.semanticsController
                    .$lastState
                    .subscribe(on: RunLoop.main)
                    .receive(on: RunLoop.main),
                perform: {
                    lastState = $0
                }
            )
    }
    
    func hoveredNodeInfoView(_ hoveredId: String) -> some View {
        VStack {
            Text("\(sourceGridName)")
                .bold()
                .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(enumeratedParents(of: hoveredId), id: \.0) { index, semantics in
                        semanticRow(semantics: semantics)
                            .padding(.trailing, Double(index) * 1.667)
                    }
                }
                .padding(4.0)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
            }
        }
        .frame(
            minWidth: 256.0, maxWidth: 296.0,
            minHeight: 128.0
        )
        .padding(4.0)
    }
    
    func semanticRow(semantics: SemanticInfo) -> some View {
        VStack(alignment: .leading) {
            HStack {
                if isSelected(info: semantics) {
                    Text("* ").font(.title)
                }
                VStack(alignment: .leading) {
                    Text(semantics.syntaxTypeName)
                        .font(.caption)
                        .underline()
                    Text(semantics.referenceName)
                        .font(.caption)
                }
            }
        }
        .padding([.horizontal], 8.0)
        .padding([.vertical], 4.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .border(Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0), width: 1.0)
        .background(backgroundColor(info: semantics)) // needed to fill tap space on macOS
        .onTapGesture {
//            withAnimation {
                didTapRow(semantics: semantics)
//            }
        }
    }
}

extension SyntaxHierarchyView {
    func didTapRow(semantics: SemanticInfo) {
        print("Not implemented: \(#function)")
    }
}

extension SyntaxHierarchyView {
    var sourceGrid: CodeGrid? {
        lastState?.targetGrid
    }
    var sourceInfo: SemanticInfoMap {
        sourceGrid?.semanticInfoMap ?? SemanticInfoMap()
    }
    var sourceGridName: String {
        sourceGrid.map
            { "\($0.fileName)" }
            ?? "No target grid"
    }
    
    func enumeratedParents(of id: String) -> [EnumeratedSequence<[SemanticInfo]>.Element] {
        return Array(sourceInfo.parentList(id).enumerated())
    }
    
    func backgroundColor(info: SemanticInfo) -> Color {
        return isSelected(info: info)
            ? Color(red: 0.1, green: 0.3, blue: 0.2, opacity: 0.8)
            : Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8)
    }
    
    func isSelected(info: SemanticInfo) -> Bool {
        print("Not implemented: \(#file):\(#function)")
        return false
    }
}
