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
    @State var pathDepths: [FileKitPath: Int] = [:]
    
    var body: some View {
        fileRows(files)
            .onReceive(
                SceneLibrary.global.codePagesController.fileStream
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
            ) { scopes in
                self.files = scopes
            }
            .onReceive(
                SceneLibrary.global.codePagesController.pathDepthStream
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
            ) { depths in
                self.pathDepths = depths
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
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("📄")
                    .font(.footnote)
                    .truncationMode(.middle)
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.light)
                
                Spacer()

                Text("📦")
                    .font(.footnote)
                    .onTapGesture { genericSelection(
                        .newSinglePath(path)
                    ) }
                    .padding(4.0)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .padding(4.0)
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1))
            .onTapGesture { fileSelected(path, .addToRow) }
        case let .directory(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("▶️")
                
                Text(path.components.last?.rawValue ?? "")
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("📦")
                    .font(.callout)
                    .onTapGesture { genericSelection(
                        .newMultiCommandRecursiveAll(
                            path, .allChildrenInNewPlane
                        )
                    ) }
                    .padding(4.0)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .padding([.top, .bottom, .leading], 4)
                
                Text("📦🔂")
                    .font(.callout)
                    .onTapGesture { genericSelection(
                        .newMultiCommandRecursiveAllCache(path)
                    ) }
                    .padding(4.0)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .padding(4.0)
            }
            .padding(0.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
            .onTapGesture { fileScopeSelected(scope) }
        case let .expandedDirectory(path):
            HStack {
                makeSpacer(pathDepths[path])
                Text("🔽")
                
                Text(path.components.last?.rawValue ?? "")
                    .underline()
                    .fontWeight(.heavy)
                
                Spacer()
                
                Text("📦")
                    .font(.callout)
                    .onTapGesture { genericSelection(
                        .newMultiCommandRecursiveAll(
                            path, .allChildrenInNewPlane
                        )
                    ) }
                    .padding(4.0)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.2))
                    .padding(4.0)
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
        #if os(OSX)
        SceneLibrary.global.codePagesController
            .fileBrowser
            .fileSeletionEvents = action
        #else
        SceneLibrary.global.codePagesController
            .onNewFileStreamEvent(action)
        #endif
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
