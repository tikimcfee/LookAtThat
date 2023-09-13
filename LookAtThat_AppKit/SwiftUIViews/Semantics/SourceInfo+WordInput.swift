//  LookAtThat_AppKit
//
//  Created on 9/13/23.
//  

import SwiftUI

extension SourceInfoPanelView {
    struct WordInputView: View {
        
        @State var textInput: String = ""
        @State var toggledRows: Set<String> = []
        
        @State var playingList: Bool = false
//        {
//            didSet {
//                if !playingList {
//                    autoscrollWord = nil
//                }
//            }
//        }
        
        @State var goSlow: Bool = true
//        @State var autoscrollWord: String?
        
        @StateObject var controller = DictionaryController()
        
        var body: some View {
            VStack(alignment: .leading) {
                dictionaryView
                TextField("Word goes here", text: $textInput)
                
                HStack {
                    Button("Load Dictionary") {
                        controller.start()
                    }
                    
                    Button("Refresh Wall") {
                        GlobalInstances
                            ._2ETRoot
                            .setupDictionaryTest(controller)
                    }
                    
                    Button(
                        action: { toggleListPlay() },
                        label: {
                            if playingList {
                                HStack {
                                    Text("Stop List Play")
                                    ProgressView()
                                }
                            } else {
                                Text("Play List")
                            }
                        }
                    )
                    
                    Button("Play sentence") {
                        playInputAsSentence(textInput)
                    }
                    
                    Toggle("Go Slow", isOn: $goSlow)
                }
            }
            .padding()
            .onChange(of: textInput) { newValue in
                updateFocusOnTextChange(newValue)
            }
        }
        
        func toggleListPlay() {
            guard !playingList else {
                playingList = false
                return
            }
            
            playingList = true
            
            WorkerPool.shared.nextConcurrentWorker().async {
                startPlay()
            }
            
            func startPlay() {
                var iterator = controller.sortedDictionary.sorted.makeIterator()
                func nextWord() -> String? { iterator.next()?.0 }
                while let word = nextWord(), playingList {
//                    autoscrollWord = word
                    updateFocusOnTextChange(word)
                    
                    __goSlow(really: goSlow)
                }
                Task { @MainActor in playingList = false }
            }
        }
        
        func __goSlow(really: Bool = false) {
            if really {
                Thread.sleep(until: Date.now.addingTimeInterval(2))
            } else {
                Thread.sleep(until: Date.now.addingTimeInterval(0.33))
            }
        }
        
        func playInputAsSentence(_ dirtySentence: String) {
            let cleanedSentence = dirtySentence.lowercased().splitToWords.map {
                $0.trimmingCharacters(in: .alphanumerics.inverted).lowercased()
            }
            
            WorkerPool.shared.nextWorker().async {
                for word in cleanedSentence {
                    updateFocusOnTextChange(word)
                    
                    __goSlow(really: goSlow)
                }
            }
        }
        
        func updateFocusOnTextChange(_ dirtyInput: String) {
            let cleanInput = dirtyInput.lowercased()
            
            guard let node = controller.nodeMap[cleanInput] else {
                print("No word found for: \(cleanInput)")
                controller.focusedWordNode = nil
                return
            }
            
            controller.focusedWordNode = node
//            GlobalInstances.debugCamera.interceptor.resetPositions()
//            GlobalInstances.debugCamera.position = node.position.translated(dZ: -10)
//            GlobalInstances.debugCamera.rotation = .zero
        }
        
        @ViewBuilder
        var dictionaryView: some View {
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(controller.sortedDictionary.sorted, id: \.0) { entry in
                            dictionaryViewCell(for: entry)
                                .padding(.bottom, 8)
                                .tag(entry.0)
                        }
                    }
                    .id(UUID()) // Use .id() to force rebuilding without diff computation
                }
//                .onChange(of: autoscrollWord) { word in
//                    guard goSlow, let word else { return }
////                    reader.scrollTo(word)
//                }
            }
            .frame(maxHeight: 380.0)
        }
        
        @ViewBuilder
        func dictionaryViewCell(for entry: (String, [String])) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.0)
                if toggledRows.contains(entry.0) {
                    Text(entry.1.joined(separator: ", "))
                }
            }
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 4, trailing: 6))
            .background(cellBackground(for: entry))
            .onTapGesture {
                toggledRows.removeAll()
                toggledRows.insert(entry.0)
                
//                let toggled = toggledRows.toggle(entry.0)
//                print("'\(entry.0)' toggled: \(toggled)")
                
                if let node = controller.nodeMap[entry.0] {
                    controller.focusedWordNode = node
                } else {
                    controller.focusedWordNode = nil
                }
            }
        }
        
        func cellBackground(for entry: (String, [String])) -> some View {
            ZStack {
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
//                    .fill(
//                        autoscrollWord == entry.0
//                            ? .gray.opacity(0.6)
//                            : .gray.opacity(0.2)
//                    )
                    .fill(.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                    .stroke(.gray)
            }.drawingGroup(opaque: true)
        }
    }
}
