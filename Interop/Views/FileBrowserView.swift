//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import Combine
import SwiftUI
import Foundation
import BitHandling

let FileIcon = "📄"
let FocusIcon = "👁️‍🗨️"
let AddToOriginIcon = "🌐"
//let DirectoryIconCollapsed = "📁"
//let DirectoryIconExpanded = "📂"
let DirectoryIconCollapsed = "􀆊"
let DirectoryIconExpanded = "􀆈"

extension FileBrowserView {
    var fileBrowser: FileBrowser {
        GlobalInstances.fileBrowser
    }
    
    func pathDepths(_ scope: FileBrowser.Scope) -> Int {
        fileBrowser.distanceToRoot(scope)
    }
}

class FileBrowserViewState: ObservableObject {
    @Published var files: FileBrowserView.RowType = []
    @Published var filterText: String = ""
    
    private var selectedfiles: FileBrowserView.RowType = []
    private var bag = Set<AnyCancellable>()
    
    init() {
        GlobalInstances.fileStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedScopes in
                guard let self = self else { return }
                self.selectedfiles = selectedScopes
                self.files = self.filter(files: selectedScopes)
            }.store(in: &bag)
        
        $filterText.sink { [weak self] _ in
            guard let self = self else { return }
            self.files = self.filter(files: self.selectedfiles)
        }.store(in: &bag)
    }
    
    func filter(files: [FileBrowser.Scope]) -> [FileBrowser.Scope] {
        guard !filterText.isEmpty else { return files }
        return files.filter {
//            $0.path.path.fuzzyMatch(filterText)
            $0.path.fileName.fuzzyMatch(filterText)
        }
    }
}

struct FileBrowserView: View {
    
    typealias RowType = [FileBrowser.Scope]
    @StateObject var browserState = FileBrowserViewState()
    
    var body: some View {
        rootView
            .padding(4.0)
            .frame(
                minWidth: 256.0,
                maxWidth: 640.0,
                maxHeight: 768.0,
                alignment: .leading
            )
    }
    
    var rootView: some View {
        VStack(alignment: .leading) {
            fileRows(browserState.files)
            searchInput
        }
    }
    
    
    var searchInput: some View {
        TextField(
            "🔍 Find",
            text: $browserState.filterText
        )
    }
    
    @ViewBuilder
    func fileRows(_ rows: RowType) -> some View {
        List(rows) { scope in
            HStack(spacing: 0) {
                makeSpacer(pathDepths(scope))
                rowForScope(scope)
            }
        }
        #if os(macOS)
        .listStyle(.inset(alternatesRowBackgrounds: true))
        #else
        .listStyle(.plain)
        #endif
    }
}

private extension FileBrowserView {
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            fileView(scope, path)
                .onTapGesture {
                    genericSelection(.newSingleCommand(path, .focusOnExistingGrid))
                }
        case let .directory(path):
            directoryView(scope, path)
                .onTapGesture {
                    fileScopeSelected(scope)
                }
        case let .expandedDirectory(path):
            expandedDirectoryView(scope, path)
                .onTapGesture {
                    fileScopeSelected(scope)
                }
        }
    }
    
    @ViewBuilder
    func makeSpacer(_ depth: Int?) -> some View {
        if let depth {
            if depth == 0 {
                EmptyView()
            } else {
//                RectangleDivider()
                Spacer()
                    .frame(width: depth.cg * 8.0)
//                    .padding(.leading, depth.cg * 16.0)
            }
        }
    }
    
    @ViewBuilder
    func fileView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack(spacing: 4) {
            Text(FileIcon)
                .font(.footnote)
                .padding(1)
                .background(
                    RoundedRectangle(cornerRadius: 2.0)
                        .strokeBorder(lineWidth: 0.5)
                        .foregroundColor(.gray)
                        
                )
            Text(path.lastPathComponent)
                .fontWeight(.light)
            Spacer()
        }
        .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8))
    }
    
    @ViewBuilder
    func directoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack {
            Text(DirectoryIconCollapsed)
            Text(path.lastPathComponent)
            Spacer()
            showDirectoryButton(path)
        }
        .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.3))
    }
    
    @ViewBuilder
    func expandedDirectoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack {
            Text(DirectoryIconExpanded)
            Text(path.lastPathComponent)
                .bold()
            Spacer()
            showDirectoryButton(path)
        }
        .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.5))
    }
    
    func showDirectoryButton(
        _ path: URL
    ) -> some View {
        Button(
            action: {
                genericSelection(
                    .newMultiCommandRecursiveAllLayout(path, .addToWorld)
                )
            },
            label: {
                Text("Show All")
                    .font(.caption2)
            }
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 4.0)
                .foregroundColor(.blue.opacity(0.6))
        )
        .buttonStyle(.plain)
        #if os(macOS)
        .onLongPressGesture(perform: {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(path.path, forType: .string)
        })
        #endif
    }
}

private extension FileBrowserView {
    func fileSelected(_ path: URL, _ selectType: FileBrowser.Event.SelectType) {
        GlobalInstances
            .fileBrowser
            .fileSelectionEvents = .newSingleCommand(path, selectType)
    }
    
    func fileScopeSelected(_ scope: FileBrowser.Scope) {
        GlobalInstances
            .fileBrowser
            .onScopeSelected(scope)
    }
    
    func genericSelection(_ action: FileBrowser.Event) {
        GlobalInstances
            .fileBrowser
            .fileSelectionEvents = action
    }
}

// MARK: RectangleDivider
struct RectangleDivider: View {
    let color: Color = .secondary.opacity(0.4)
    let height: CGFloat = 8.0
    let width: CGFloat = 2.0
    var body: some View {
        Text("﹂")
            .foregroundColor(color)
    }
}

#if DEBUG
struct FileBrowserView_Previews: PreviewProvider {
    
    static let testPaths = [
        "/Users/ivanlugo/rapiddev/_personal/LookAtThat/LookAtThatMobile",
        "/Users/ivanlugo/rapiddev/_personal/LookAtThat/LookAtThatMobile/SampleFiles.bundle"
    ]
    
    static let testFiles = {
        testPaths.reduce(into: [FileBrowser.Scope]()) { result, path in
            result.append(.directory(URL(fileURLWithPath: path)))
        }
    }()
    
    static let testState: FileBrowserViewState = {
        let state = FileBrowserViewState()
//        state.files = testFiles
        return state
    }()
    
    static var previews: some View {
        FileBrowserView(browserState: testState)
            .onAppear {
                for file in testFiles {
                    DispatchQueue.main.async {
                        GlobalInstances.fileBrowser.onScopeSelected(file)
                    }
                }
            }
    }
}
#endif
