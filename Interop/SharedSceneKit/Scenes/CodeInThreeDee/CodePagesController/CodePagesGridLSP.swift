//
//  CodePagesGridLSP.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/10/22.
//

import Foundation
import LanguageClient
import LanguageServerProtocol

class CodePagesKitten {
    func testKitten() {
        
    }
}

class CodePagesGridLSP {
    func start(_ done: @escaping () -> Void) {
        let lspPath = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
        let directoryPath = "/Users/lugos/udev/manicmind/LookAtThat"
        
        let execution = Process.ExecutionParameters(
            path: lspPath,
            arguments: [],
            environment: [:],
            currentDirectoryURL: URL(fileURLWithPath: directoryPath)
        )
        
//    https://microsoft.github.io//language-server-protocol/specifications/lsp/3.17/specification/#initialize
        let server = LocalProcessServer(executionParameters: execution)
        server.logMessages = true
        
        let initializer = InitializingServer(server: server)
        initializer.initializeParamsProvider = { initializationReceiver in
            let params = InitializeParams(
                processId: 1,
                rootPath: nil, // nil => "no folder is open"
                rootURI: nil, // "some-document-uri-as-string"
                initializationOptions: nil, // AnyCodable?
                capabilities: ClientCapabilities(
                    workspace: nil, // <#T##ClientCapabilities.Workspace?#>
                    textDocument: nil, // <#T##TextDocumentClientCapabilities?#>
                    window: nil, // <#T##WindowClientCapabilities?#>
                    general: nil, // <#T##GeneralClientCapabilities?#>
                    experimental: nil // <#T##LSPAny#> == AnyCodable?
                ),
                trace: nil, // Tracing?
                workspaceFolders: nil // [WorkspaceFolder]?
            )
            initializationReceiver(.success(params))
        }
        let definitionURI = "file:///Users/lugos/udev/manicmind/LookAtThat/Interop/Caches/LockingCache.swift"
        initializer.definition(
            params: .init(
                uri: definitionURI,
                position: Position(line: 1, character: 1)
            ),
            block: { result in
                switch result {
                case .success(let response):
                    switch response {
                    case .optionA(let location):
                        print(location)
                    case .optionB(let locations):
                        print(locations)
                    case .optionC(let locationLinks):
                        print(locationLinks)
                    case .none:
                        print("Success response, no result value")
                    }
                case .failure(let error):
                    print(error)
                }
                done()
            }
        )
    }
}
