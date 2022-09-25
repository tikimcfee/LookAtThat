//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import Combine
import SwiftUI
import Foundation

let FileIcon = "📄"
let FocusIcon = "👁️‍🗨️"
let AddToOriginIcon = "🌐"
let DirectoryIconCollapsed = "📁"
let DirectoryIconExpanded = "📂"

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
        return files.filter { $0.path.path.fuzzyMatch(filterText) }
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
    
    func fileRows(_ rows: RowType) -> some View {
        ScrollView {
            ForEach(rows, id: \.id) { scope in
                rowForScope(scope)
            }
        }
    }
    
    func actionButton(
        _ text: String,
        _ path: URL,
        event: FileBrowser.Event
    ) -> some View {
        Text(text)
            .font(.title)
            .onTapGesture { genericSelection(event) }
        #if os(macOS)
            .onLongPressGesture(perform: {
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(path.path, forType: .string)
            })
        #endif
            .padding(8.0)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .padding(2.0)
    }
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            fileView(scope, path)
        case let .directory(path):
            directoryView(scope, path)
        case let .expandedDirectory(path):
            expandedDirectoryView(scope, path)
        }
    }
    
    @ViewBuilder
    func makeSpacer(_ depth: Int?) -> some View {
        HStack(spacing: 2.0) {
            RectangleDivider()
        }.frame(
            width: 16.0 * CGFloat(depth ?? 1),
            height: 16.0
        )
    }
}

private extension FileBrowserView {
    @ViewBuilder
    func fileView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack(spacing: 2) {
            Spacer().frame(width: 2.0)
            makeSpacer(pathDepths(scope))
            Text(FileIcon)
                .font(.footnote)
                .truncationMode(.middle)
            Text(path.lastPathComponent)
                .fontWeight(.light)
            Spacer()
        }
        .padding(0.5)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1))
        .onTapGesture {
            genericSelection(.newSingleCommand(path, .focusOnExistingGrid))
        }
    }
    
    @ViewBuilder
    func directoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack {
            makeSpacer(pathDepths(scope))
            Text(DirectoryIconCollapsed)
            Text(path.lastPathComponent)
                .fontWeight(.medium)
            Spacer()
            actionButton("\(AddToOriginIcon)", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
        }
        .padding(0.5)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
        .onTapGesture { fileScopeSelected(scope) }
    }
    
    @ViewBuilder
    func expandedDirectoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack {
            makeSpacer(pathDepths(scope))
            Text(DirectoryIconExpanded)
            Text(path.lastPathComponent)
                .underline()
                .fontWeight(.heavy)
            Spacer()
            actionButton("\(AddToOriginIcon)", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
        }
        .padding(0.5)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.3))
        .onTapGesture { fileScopeSelected(scope) }
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
    let color: Color = .secondary
    let height: CGFloat = 8.0
    let width: CGFloat = 2.0
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
//            .edgesIgnoringSafeArea(.horizontal)
    }
}

#if DEBUG
struct FileBrowserView_Previews: PreviewProvider {
    
    static let testPaths = [
        "/Users/lugos/udev/manicmind/LookAtThat",
        "/Users/lugos/udev/manicmind/LookAtThat/Interop/CodeGrids/",
        "/Users/lugos/udev/manicmind/otherfolks/swift-ast-explorer/.build/checkouts/swift-syntax/Sources/SwiftSyntax"
    ]
    
    static let testFiles = {
        testPaths.reduce(into: [FileBrowser.Scope]()) { result, path in
            result.append(.file(URL(fileURLWithPath: path)))
            result.append(.directory(URL(fileURLWithPath: path)))
            result.append(.expandedDirectory(URL(fileURLWithPath: path)))
        }
    }()
    
    static let testState: FileBrowserViewState = {
        let state = FileBrowserViewState()
        state.files = testFiles
        return state
    }()
    
    static var previews: some View {
        FileBrowserView(browserState: testState)
    }
}
#endif
