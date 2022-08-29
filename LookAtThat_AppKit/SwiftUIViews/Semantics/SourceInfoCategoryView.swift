//
//  SourceInfoCategoryView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/11/22.
//

import SwiftUI
import SwiftSyntax
import Combine

struct SourceInfoCategoryView: View {
    @EnvironmentObject var sourceState: SourceInfoPanelState
    
    @State var targetedInfo: SemanticInfoMap = .init()
    @State var targetedGrid: CodeGrid?
    
    private var global: CodeGridGlobalSemantics { SceneLibrary.global.codePagesController.globalSemantics }
    
    var body: some View {
        VStack {
            HStack {
                Toggle("Show global semantics", isOn: $sourceState.categories.showGlobalMap)
                Button("Reset snapshot", action: {
                    global.snapshotDefault()
                })
            }.padding(4)
            
            if sourceState.categories.showGlobalMap {
                globalInfoRows
            } else {
                targetInfoRows
            }
        }
        .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
        .onReceive(sourceState.$sourceGrid, perform: { grid in
            targetedGrid = grid
        })
        .onReceive(sourceState.$sourceInfo, perform: { info in
            targetedInfo = info
        })
        .onAppear {
            global.snapshotDefault()
        }
        .frame(width: 384.0)
    }
    
    @ViewBuilder
    var targetInfoRows: some View {
        if let targetedGrid = targetedGrid  {
            ScrollView {
                makeInfoRowGroup(
                    for: global.defaultCategories,
                    in: targetedGrid
                )
            }.padding(4.0)
        } else {
            EmptyView()
        }
    }

    var globalInfoRows: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(
                    global.categorySnapshot,
                    id: \.self
                ) { snapshotParticipant in
                    VStack {
                        Text(snapshotParticipant.sourceGrid.fileName)
                            .underline()
                            .padding(.top, 8)
                        
                        // TODO: Use a tab view for categories, they're enumerable.
                        List {
                            makeInfoRowGroup(
                                for: snapshotParticipant.queryCategories,
                                in: snapshotParticipant.sourceGrid
                            )
                        }
                        .frame(height: 256.0)
                    }
                    .padding(4.0)
                }
            }
        }
        .padding(4.0)
    }
    
    func makeInfoRowGroup(
        for categories: [SemanticInfoMap.Category],
        in targetGrid: CodeGrid
    ) -> some View {
        ForEach(categories, id: \.self) { category in
            if let categoryMap = targetGrid.semanticInfoMap.map(for: category), !categoryMap.isEmpty {
                Text(category.rawValue).underline().padding(.top, 8)
                infoRows(from: targetGrid, categoryMap)
            }
        }
    }
    
    func infoRows(from grid: CodeGrid, _ map: AssociatedSyntaxMap) -> some View {
        List {
            ForEach(Array(map.keys), id:\.self) { (id: SyntaxIdentifier) in
                if let info = grid.semanticInfoMap.semanticsLookupBySyntaxId[id] {
                    semanticInfoRow(info, grid)
                } else {
                    Text("No SemanticInfo")
                }
            }
        }
        .frame(minHeight: max(96.0, CGFloat((Float(map.count) / 3.0) * 64.0)))
        .padding(4.0)
    }
    
    func semanticInfoRow(_ info: SemanticInfo, _ grid: CodeGrid) -> some View {
        Text(info.referenceName)
            .font(Font.system(.caption, design: .monospaced))
            .padding(4)
            .overlay(Rectangle().stroke(Color.gray))
            .onTapGesture {
                print("Not implemented: \(#file):\(#function), tap")
            }
    }
}
