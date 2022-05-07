//
//  FocusSearchInputView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/7/22.
//

import SwiftUI

struct FocusSearchInputView: View {
    class State: ObservableObject {
        var searchInput: String {
            get {
                SceneLibrary.global.codePagesController.codeGridParser.query.searchInput
            }
            set {
                objectWillChange.send()
                SceneLibrary.global.codePagesController.codeGridParser.query.searchInput = newValue
            }
        }
    }
    @StateObject var state: State = State()
    
    var body: some View {
        HStack {
            TextField(
                "🔍 Find",
                text: .init(get: { state.searchInput }, set: { newText in state.searchInput = newText })
            ).frame(width: 256)
            
            Text("New Focus")
                .padding(8.0)
                .font(.headline)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                .onTapGesture { newFocusRequested() }
        }
    }
    
    func newFocusRequested() {
        SceneLibrary.global.codePagesController.compat
            .inputCompat.focus.setNewFocus()
    }
}
