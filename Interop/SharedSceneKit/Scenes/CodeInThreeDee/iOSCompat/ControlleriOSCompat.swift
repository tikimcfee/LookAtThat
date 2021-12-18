//
//  ControlleriOSCompat.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

class ControlleriOSCompat {
    let controller: CodePagesController
    let inputCompat: CodePagesInput
    
    init(controller: CodePagesController) {
        self.controller = controller
        self.inputCompat = CodePagesInput(controller: controller)
    }
    
    func attachEventSink() {
        SceneLibrary.global.codePagesController.fileEventStream
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] event in
                inputCompat.controller.onNewFileStreamEvent(event)
            }
            .store(in: &controller.cancellables)
    }
    
    func attachSearchInputSink() {
//        SceneLibrary.global.codePagesController.codeGridParser.query.searchStream
//            .receive(on: DispatchQueue.global(qos: .userInteractive))
//            .sink { [inputCompat] searchEvent in
//                print("skip \(searchEvent)")
//            }
//            .store(in: &controller.cancellables)
    }
}

extension ControlleriOSCompat: CommandHandler {
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        guard let newGrid = renderAndCache(path) else { return }
        
        parser.editorWrapper.addInFrontOfCamera(grid: newGrid)
    }
}
