//
//  FocusSearchInputView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/7/22.
//

import SwiftUI

struct FocusSearchInputView: View {
    class State: ObservableObject {
        @Published var selected = Set<CodeGridSemanticMap.Category>()
        @Published var showCategories = false
        
        var categorySlices = CodeGridSemanticMap.Category.allCases.slices(sliceSize: 5)
        
        var searchInput: String {
            get {
                SceneLibrary.global.codePagesController.codeGridParser.query.searchInput
            }
            set {
                objectWillChange.send()
                SceneLibrary.global.codePagesController.codeGridParser.query.searchInput = newValue
            }
        }
        
        func vendBinding(_ category: CodeGridSemanticMap.Category) -> Binding<Bool> {
            Binding<Bool>(
                get: { self.selected.contains(category) },
                set: { isSelected in
                    switch isSelected {
                    case true: self.selected.insert(category)
                    case false: self.selected.remove(category)
                    }
                }
            )
        }
    }
    @StateObject var state: State = State()
    
    var body: some View {
        VStack(alignment: .trailing) {
            searchInput
            filterSelections
//            actions
        }.padding(4)
    }
    
    var actions: some View {
        Text("New Focus")
            .padding(8.0)
            .font(.headline)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .onTapGesture { newFocusRequested() }
    }
    
    var searchInput: some View {
        TextField(
            "🔍 Find",
            text: .init(get: { state.searchInput }, set: { newText in state.searchInput = newText })
        )
        .frame(width: 256)
    }
    
    @ViewBuilder
    var filterSelections: some View {
        Toggle("Filter Categories", isOn: $state.showCategories)
        if state.showCategories {
            HStack(alignment: .top) {
                ForEach(state.categorySlices, id: \.self) { slice in
                    VStack(alignment: .leading) {
                        ForEach(slice, id: \.self) { category in
                            Toggle("\(category.rawValue)", isOn: state.vendBinding(category))
                        }
                    }
                }
            }
        }
    }
    
    func newFocusRequested() {
        SceneLibrary.global.codePagesController.compat
            .inputCompat.focus.setNewFocus()
    }
}

struct SearchInput_Previews: PreviewProvider {
    static var previews: some View {
        FocusSearchInputView()
    }
}
