//
//  CodePagesTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/10/22.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import Foundation
@testable import LookAtThat_AppKit

class GitHubClient {
    static let shared = GitHubClient()
    
    let basePath = "https://api.github.com/"
    lazy var baseURL = URL(string: basePath)!
    
    private init() { }
}

extension GitHubClient {
    private func getRepoZipEndpointUrl(
        owner: String,
        repo: String,
        branchRef: String
    ) -> URL {
        let apiPath = "repos/\(owner)/\(repo)/zipball/\(branchRef)"
        return baseURL.appendingPathComponent(apiPath)
    }
    
    func downloadRepoZip(
        owner: String,
        repo: String,
        branchRef: String,
        _ receiver: @escaping (URL) -> Void
    ) {
        let moveTargetUrl = AppFiles.githubRepos
            .appendingPathComponent(repo)
            .appendingPathExtension("zip")
        let zipURL = GitHubClient.shared
            .getRepoZipEndpointUrl(owner: owner, repo: repo, branchRef: branchRef)
        
        URLSession.shared.downloadTask(with: zipURL, completionHandler: { url, response, error in
            guard let url = url, error == nil else {
                print("Download task failed: \(String(describing: error))")
                return
            }
            AppFiles.move(fileUrl: url, to: moveTargetUrl)
            receiver(moveTargetUrl)
        }).resume()
    }
}

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
    
    func testGitStuff() throws {
        printStart()
        let repoGet = expectation(description: "Retrieve repo")
        let repoName = "SceneKit-SCNLine"
        GitHubClient.shared.downloadRepoZip(owner: "tikimcfee", repo: repoName, branchRef: "main") { zipUrl in
            print("Got zip url: \(zipUrl)")
            repoGet.fulfill()
        }
        
        wait(for: [repoGet], timeout: 5.0)
        
        print("Have URLs:")
        AppFiles.allRepositoryURLs.forEach { url in
            print(url)
        }
        
        AppFiles.allRepositoryURLs.forEach {
            AppFiles.delete(fileUrl: $0)
        }
        
        print("After deletion:")
        AppFiles.allRepositoryURLs.forEach { url in
            print(url)
        }
        
        printEnd()
    }
    
    func testPathEncoding() throws {
        printStart()
        
        let pathSource = try XCTUnwrap(URL(string: bundle.testFileAbsolute), "Need valid file")
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
