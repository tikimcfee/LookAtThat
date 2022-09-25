//
//  GlobalSearchView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/1/22.
//

import SwiftUI
import Combine

class GlobalSearchViewState: ObservableObject {
    @Published var filterText = ""
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
            
            GlobalInstances.gridStore.editor.applyAllUpdates(
                sizeSortedAdditions: task.searchLayout.values,
                sizeSortedMissing: task.missedGrids.values
            )
        }
    }
}

struct GlobalSearchView: View {
    @StateObject var searchState = GlobalSearchViewState()
    
    var body: some View {
        searchInput
            .padding()
            .frame(minWidth: 256.0, idealWidth: 256.0, maxWidth: 512.00)
    }
    
    var searchInput: some View {
        TextField(
            "🔍 Find",
            text: $searchState.filterText
        )
    }
}

struct GlobalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSearchView()
    }
}
