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
            .sink { newText in
                GlobalInstances.gridStore.searchContainer.search(newText) {
                    print("Filter completion reported: \(newText)")
                }
            }.store(in: &bag)
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
