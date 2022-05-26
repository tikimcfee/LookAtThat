//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import SwiftUI
import Foundation

let FileIcon = "📄"
let FocusIcon = "👁️‍🗨️"
let AddToOriginIcon = "🌐"
let DirectoryIconCollapsed = "▶️"
let DirectoryIconExpanded = "🔽"

extension FileBrowserView {
    var fileBrowser: FileBrowser {
        SceneLibrary.global.codePagesController.fileBrowser
    }
    
    func pathDepths(_ scope: FileBrowser.Scope) -> Int {
        fileBrowser.distanceToRoot(scope)
    }
}

struct FileBrowserView: View {
    
    typealias RowType = [FileBrowser.Scope]
    @State var files: RowType = []
    
    var body: some View {
        fileRows(files)
            .onReceive(
                SceneLibrary.global.codePagesController.fileStream
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
            ) { selectedScopes in
                self.files = selectedScopes
            }
    }
    
    func fileRows(_ rows: RowType) -> some View {
        ScrollView {
            ForEach(rows, id: \.id) { scope in
                rowForScope(scope)
            }
        }
        .padding(4.0)
        .frame(
            minWidth: 256.0,
            maxWidth: 384.0,
            maxHeight: 768.0,
            alignment: .leading
        )
    }
    
    func actionButton(
        _ text: String,
        _ path: FileKitPath,
        event: FileBrowser.Event
    ) -> some View {
        Text(text)
            .font(.footnote)
            .onTapGesture { genericSelection(event) }
            .padding(8.0)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .padding(2.0)
    }
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            HStack(spacing: 2) {
                Spacer().frame(width: 2.0)
                makeSpacer(pathDepths(scope))
                Text(FileIcon)
                    .font(.footnote)
                    .truncationMode(.middle)
                Text(path.lastPathComponent)
                    .fontWeight(.light)
                
                Spacer()

                actionButton("\(FocusIcon)+", path, event: .newSingleCommand(path, .addToFocus))
                actionButton("\(AddToOriginIcon) v3", path, event: .newSingleCommand(path, .addToWorld))
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1))
            .onTapGesture {
                genericSelection(.newSingleCommand(path, .focusOnExistingGrid))
            }
        case let .directory(path):
            HStack {
                makeSpacer(pathDepths(scope))
                Text(DirectoryIconCollapsed)
                
                Text(path.lastPathComponent)
                    .fontWeight(.medium)
                
                Spacer()
                
                actionButton("\(FocusIcon)+", path, event: .newMultiCommandRecursiveAllLayout(path, .addToFocus))
                actionButton("\(AddToOriginIcon) v3", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .onTapGesture { fileScopeSelected(scope) }
        case let .expandedDirectory(path):
            HStack {
                makeSpacer(pathDepths(scope))
                Text(DirectoryIconExpanded)
                
                Text(path.lastPathComponent)
                    .underline()
                    .fontWeight(.heavy)
                
                Spacer()
                
                actionButton("\(FocusIcon)+", path, event: .newMultiCommandRecursiveAllLayout(path, .addToFocus))
                actionButton("\(AddToOriginIcon) v3", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.3))
            .onTapGesture { fileScopeSelected(scope) }
        }
    }
    
    func fileSelected(_ path: FileKitPath, _ selectType: FileBrowser.Event.SelectType) {
        SceneLibrary.global.codePagesController
            .fileBrowser
            .fileSeletionEvents = .newSingleCommand(path, selectType)
    }
    
    func fileScopeSelected(_ scope: FileBrowser.Scope) {
        SceneLibrary.global.codePagesController.fileBrowser.onScopeSelected(scope)
    }
    
    func genericSelection(_ action: FileBrowser.Event) {
        SceneLibrary.global.codePagesController
            .fileBrowser
            .fileSeletionEvents = action
    }
    
    @ViewBuilder
    func makeSpacer(_ depth: Int?) -> some View {
        HStack(spacing: 2.0) {
//            RectangleDivider()
            RectangleDivider()
        }.frame(
            width: 16.0 * CGFloat(depth ?? 1),
            height: 16.0
        )
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
        }
    }()
    
    static var previews: some View {
        FileBrowserView(files: testFiles)
    }
}
#endif
