//
//  CodePagesTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/10/22.
//

import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import BitHandling
import MetalLink
import MetalLinkHeaders
import MetalLinkResources
import SwiftGlyphs
@testable import LookAtThat_AppKit

class LookAtThat_AppKit_CodePagesTests: XCTestCase {
    var bundle: TestBundle!

    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
    }

    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
    }
    
    func testClassCollections() throws {
        let link = GlobalInstances.defaultLink
        let builder = try CodeGridGlyphCollectionBuilder(
            link: link,
            sharedSemanticMap: SemanticInfoMap(),
            sharedTokenCache: CodeGridTokenCache(),
            sharedGridCache: bundle.gridCache
        )
        
        let testDirectory = try XCTUnwrap(bundle.testSourceDirectory, "Must have valid root code directory")
        FileBrowser.recursivePaths(testDirectory)
            .filter { FileBrowser.isSwiftFile($0) }
            .forEach {
                builder
                    .createConsumerForNewGrid()
                    .consume(url: $0)
            }
        
        var classNames = [String]()
        for grid in bundle.gridCache.cachedGrids.values {
            grid.semanticInfoMap.classes.lazy.compactMap { key, value in
                grid.semanticInfoMap.semanticsLookupBySyntaxId[key]
            }.forEach { semanticInfo in
                classNames.append(semanticInfo.referenceName)
            }
        }
        classNames.sort()
        for name in classNames {
            print(name)
        }
    }
    
    func testGitStuff() throws {
        let repoGet = expectation(description: "Retrieve repo")
        let repoName = "SceneKit-SCNLine"
        let owner = "tikimcfee"
        let branchName = "main"
        printStart(.message("Git repo fetch test, \(owner):\(repoName)@\(branchName)"))
        
        GitHubClient.shared.downloadAndUnzipRepository(
            owner: owner, repositoryName: repoName, branchName: branchName
        ) { result in
            switch result {
            case .success(let url):
                let allPaths = url.children(recursive: true)
                let toShow = 10
                print("-- Downloaded files: \(allPaths.count)")
                print("-- Showing \(toShow)")
                allPaths.prefix(toShow).forEach { print("-> ", $0.fileName) }
                repoGet.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [repoGet], timeout: 15.0)
        
        print("Have URLs:")
        AppFiles.allRepositoryRoots.forEach { url in
            print(url)
        }
        
        AppFiles.allRepositoryRoots.forEach {
            AppFiles.delete(fileUrl: $0)
        }
        
        print("After deletion:")
        AppFiles.allRepositoryRoots.forEach { url in
            print(url)
        }
        
        printEnd()
    }
    
    func testPathEncoding() throws {
        printStart()
        
        let pathSource =  bundle.testFile
        print(pathSource)
        let pathJson = try JSONEncoder().encode(pathSource)
        print("encoded", pathJson.count)
        let pathStringRep = try XCTUnwrap(String(data: pathJson, encoding: .utf8), "json must be decodable as utf8")
        print(pathStringRep)
        
        let scopeSource = FileBrowser.Scope.file(pathSource)
        print("scope source:\n", scopeSource)
        let scopeJson = try JSONEncoder().encode(scopeSource)
        print("encoded", scopeJson.count)
        let scopeStringRep = try XCTUnwrap(String(data: scopeJson, encoding: .utf8), "json must be decodable as utf8")
        print(scopeStringRep)
        
        let reified = try JSONDecoder().decode(FileBrowser.Scope.self, from: scopeJson)
        print("scope reified:\n", reified)
        XCTAssertEqual(reified, scopeSource, "Round trip encoding must succeed")
        
        printEnd()
    }
    
}
