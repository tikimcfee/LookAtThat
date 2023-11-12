//
//  GlobalSearchView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/1/22.
//

import SwiftUI
import Combine
import MetalLink

class GlobalSearchViewState: ObservableObject {
    @Published var filterText = ""
    
    @Published var foundGrids = [CodeGrid]()
    @Published var missedGrids = [CodeGrid]()
    
    var bag = Set<AnyCancellable>()
    
    init() {
        $filterText.removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { streamInput in
                self.startSearch(for: streamInput)
            }.store(in: &bag)
    }
}

extension GlobalSearchViewState {
    func startSearch(for input: String) {
        GlobalInstances.gridStore.searchContainer.search(input) { task in
            print("Filter completion reported: \(input)")
            
            DispatchQueue.main.async {
                self.foundGrids = task.searchLayout.values
                self.missedGrids = task.missedGrids.values
            }
            
//            GlobalInstances.gridStore.editor.applyAllUpdates(
//                sizeSortedAdditions: task.searchLayout.values,
//                sizeSortedMissing: task.missedGrids.values
//            )
        }
    }
}

struct GlobalSearchView: View {
    @StateObject var searchState = GlobalSearchViewState()
    @State var searchScrollLock = Set<DebugCamera.ScrollLock>()
    
    var body: some View {
        VStack(alignment: .leading) {
            searchInput
            HStack {
                scrollLocks
                randomGlobalButtons
            }
            gridListColumns
        }.onChange(of: searchScrollLock) {
            GlobalInstances.debugCamera.scrollLock = $0
        }
        .padding()
        .fixedSize()
    }
    
    @ViewBuilder
    var gridListColumns: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Matches")
                foundGrids
            }
            VStack(alignment: .leading) {
                Text("Misses")
                missedGrids
            }
        }
        .padding()
        .border(.gray)
    }
    
    var foundGrids: some View {
        gridList(searchState.foundGrids)
    }
    
    var missedGrids: some View {
        gridList(searchState.missedGrids)
    }
    
    func gridList(_ grids: [CodeGrid]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(grids) { grid in
                    gridButton(grid)
                    Divider()
                }
            }
        }
        .frame(width: 256.0, height: 196.0)
        .border(.gray)
    }
    
    @ViewBuilder
    func gridButton(_ grid: CodeGrid) -> some View {
        Text(grid.fileName)
            .onTapGesture {
                selectGrid(grid)
            }
    }
    
    func selectGrid(_ grid: CodeGrid) {
        // It looks like whatever state I leave the grids in after initial layout isn't... right. I guess the bounds are computed and working for the matrix,
        // but either the cache is busted or something breaks in the interim. Perhaps moar testz. For now, explicitly rebuilding the grid's matrix,
        // and *manually* computing the world bounds of all children (lol yes I'm serious it doesn't scale but it works), we set the camera to some
        // visually useful position and try to set its bounds to that grid.
        // 
        // TL;DR:
        // `grid.rootNode.worldBounds` doesn't work at time of commit. Doing the manual compute is.. usable. Large files go boom.
        //
        grid.rootNode.rebuildTreeState()
        let computing = BoxComputing()
        grid.enumerateChildren { computing.consumeBounds($0.worldBounds) }
        let nodeBounds = computing.bounds
        
        let position = LFloat3(
            x: BoundsLeading(nodeBounds) + BoundsWidth(nodeBounds) / 2.0,
            y: BoundsTop(nodeBounds) - 16,
            z: BoundsFront(nodeBounds) + 64
        )
        
        GlobalInstances.debugCamera.interceptor.resetPositions()
        GlobalInstances.debugCamera.position = position
        GlobalInstances.debugCamera.rotation = .zero
        GlobalInstances.debugCamera.scrollBounds = grid.rootNode.worldBounds
        GlobalInstances.gridStore.editor.snapping.searchTargetGrid = grid
        
        searchScrollLock.insert(.horizontal)
    }
    
    var scrollLocks: some View {
        VStack {
            Text("Camera Lock")
            HStack {
                ForEach(DebugCamera.ScrollLock.allCases) {
                    scrollToggleButton($0)
                }
            }
        }
        .padding()
        .border(.gray)
    }
    
    var randomGlobalButtons: some View {
        VStack {
            Button("Save Glyph Atlas") {
                GlobalInstances.defaultAtlas.serialize()
            }
            
//            Button("Load glyph Atlas") {
//                GlobalInstances.defaultAtlas.serialize()
//            }
        }
    }
    
    func scrollToggleButton(_ lock: DebugCamera.ScrollLock) -> some View {
        Button(
            action: {
                _ = searchScrollLock.toggle(lock)
            },
            label: {
                Label(
                    lock.rawValue.capitalized,
                    systemImage: searchScrollLock.contains(lock)
                        ? "checkmark.square"
                        : "square"
                )
            }
        )
    }
    
    var searchInput: some View {
        TextField(
            "🔍 Find",
            text: $searchState.filterText
        )
        .padding()
        .frame(minWidth: 256.0, idealWidth: 256.0, maxWidth: 512.00)
    }
}

struct GlobalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSearchView()
    }
}
