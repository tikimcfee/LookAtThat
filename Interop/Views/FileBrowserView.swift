//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import SwiftUI
import Foundation

struct FileBrowserView: View {
    
    typealias RowType = [FileBrowser.Scope]
    @State var files: RowType = []
    
    var fileBrowser: FileBrowser { SceneLibrary.global.codePagesController.fileBrowser }
    func pathDepths(_ scope: FileBrowser.Scope) -> Int { fileBrowser.distanceToRoot(scope) }
    
    var body: some View {
        fileRows(files)
            .onReceive(
                SceneLibrary.global.codePagesController.fileStream
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
            ) { scopes in
                self.files = scopes
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
    
    @ViewBuilder
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
            .padding(4.0)
    }
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            HStack {
                makeSpacer(pathDepths(scope))
                Text("📄")
                    .font(.footnote)
                    .truncationMode(.middle)
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.light)
                
                Spacer()

                actionButton("📦", path, event: .newSingleCommand(path, .addToWorld))
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1))
            .onTapGesture {
                genericSelection(.newSingleCommand(path, .addToFocus))
            }
        case let .directory(path):
            HStack {
                makeSpacer(pathDepths(scope))
                Text("▶️")
                
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.medium)
                
                Spacer()
                
                actionButton("📦", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
                actionButton("📦🔂", path, event: .newMultiCommandRecursiveAllCache(path))
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .onTapGesture { fileScopeSelected(scope) }
        case let .expandedDirectory(path):
            HStack {
                makeSpacer(pathDepths(scope))
                Text("🔽")
                
                Text(path.components.last?.rawValue ?? "")
                    .underline()
                    .fontWeight(.heavy)
                
                Spacer()
                
                actionButton("📦", path, event: .newMultiCommandRecursiveAllLayout(path, .addToWorld))
                actionButton("📦🔂", path, event: .newMultiCommandRecursiveAllCache(path))
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
            Spacer()
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
    let width: CGFloat = 1.0
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
            .edgesIgnoringSafeArea(.horizontal)
    }
}
