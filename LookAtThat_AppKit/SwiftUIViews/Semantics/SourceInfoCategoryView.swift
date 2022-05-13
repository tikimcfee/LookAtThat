//
//  SourceInfoCategoryView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/11/22.
//

import SceneKit
import SwiftUI
import FileKit
import SwiftSyntax
import Combine

struct SourceInfoCategoryView: View {
    @EnvironmentObject var sourceState: SourceInfoPanelState
    
    var targetedInfo: CodeGridSemanticMap { sourceState.sourceInfo }
    var targetedGrid: CodeGrid? { sourceState.sourceGrid }
    
    var body: some View {
        VStack {
            HStack {
                Toggle("Show global semantics", isOn: $sourceState.categories.showGlobalMap)
                Button("Reset snapshot", action: { CodePagesController.shared.globalSemantics.snapshotDefault() })
            }.padding(4)
            
            if sourceState.categories.showGlobalMap {
                globalInfoRows.onAppear {
                    CodePagesController.shared.globalSemantics.snapshotDefault()
                }
            } else {
                targetInfoRows
            }
        }.background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
    }
    
    @ViewBuilder
    var targetInfoRows: some View {
        if let targetedGrid = targetedGrid  {
            ScrollView {
                ForEach(
                    CodePagesController.shared.globalSemantics.defaultCategories,
                    id: \.self
                ) { category in
                    if let categoryMap = targetedGrid.codeGridSemanticInfo.map(for: category), !categoryMap.isEmpty {
                        Text(category.rawValue).underline().padding(.top, 8)
                        infoRows(from: targetedGrid, categoryMap)
                    }
                }
            }.padding(4.0)
        } else {
            EmptyView()
        }
    }

    var globalInfoRows: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(
                    CodePagesController.shared.globalSemantics.categorySnapshot,
                    id: \.self
                ) { snapshotParticipant in
                    Text(snapshotParticipant.sourceGrid.fileName)
                        .underline()
                        .padding(.top, 8)
                    
                    // TODO: Make up a prettier global view
//                    LazyVStack {
//                        ForEach(
//                            CodePagesController.shared.globalSemantics.getSnapshot(category: category),
//                            id: \.grid.id
//                        ) { tuple in
//                            infoRows(from: tuple.grid, tuple.map)
//                        }
//                    }
                }
            }
        }
        .frame(minWidth: 256.0)
        .padding(4.0)
    }
    
    func infoRows(from grid: CodeGrid, _ map: AssociatedSyntaxMap) -> some View {
        List {
            ForEach(Array(map.keys), id:\.self) { (id: SyntaxIdentifier) in
                if let info = grid.codeGridSemanticInfo.semanticsLookupBySyntaxId[id] {
                    semanticInfoRow(info, grid.codeGridSemanticInfo)
                } else {
                    Text("No SemanticInfo")
                }
            }
        }
        .frame(minHeight: max(32.0, CGFloat((Float(map.count) / 3.0) * 32.0)))
        .padding(4.0)
    }
    
    @ViewBuilder
    func semanticInfoRow(_ info: SemanticInfo, _ map: CodeGridSemanticMap) -> some View {
        Text(info.referenceName)
            .font(Font.system(.caption, design: .monospaced))
            .padding(4)
            .overlay(Rectangle().stroke(Color.gray))
            .onTapGesture {
                CodePagesController.shared.selection.selected(id: info.syntaxId, in: map)
            }
    }
}
