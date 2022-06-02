//
//  GitHubClient.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/1/22.
//

import Foundation

class GitHubClient {
    static let shared = GitHubClient()
    
    static let basePath = "https://api.github.com/"
    static let baseURL = URL(string: basePath)!
    
    private init() { }
}

extension GitHubClient {
    enum Error: Swift.Error {
        case missingResultURL
    }
    
    struct RepositoryZipArgs {
        let owner: String
        let repo: String
        let branchRef: String
        
        let unzippedResultTargetUrl: URL
    }
    
    enum Endpoint {
        case repositoryZip(RepositoryZipArgs, (URL) -> Void)
        
        var apiPath: String {
            switch self {
            case let .repositoryZip(args, _):
                return "repos/\(args.owner)/\(args.repo)/zipball/\(args.branchRef)"
            }
        }
        
        var apiUrl: URL {
            GitHubClient.baseURL.appendingPathComponent(apiPath)
        }
    }
}

extension GitHubClient {

    func fetch(endpoint: Endpoint) {
        switch endpoint {
        case let .repositoryZip(repositoryZipArgs, receiver):
            URLSession.shared.downloadTask(with: endpoint.apiUrl) { url, response, error in
                do {
                    guard let savedUrl = url else { throw Error.missingResultURL }
                    try AppFiles.unzip(fileUrl: savedUrl, to: repositoryZipArgs.unzippedResultTargetUrl)
                    receiver(repositoryZipArgs.unzippedResultTargetUrl)
                } catch {
                    print("Failed during file io: \(error)")
                }
            }.resume()
        }
    }
    
    func downloadAndUnzipRepository(
        owner: String,
        repositoryName: String,
        branchName: String,
        _ unzippedRepoReceiver: @escaping (URL) -> Void
    ) {
        let repoFileDownloadTarget = AppFiles.githubRepos
            .appendingPathComponent(repositoryName)
        
        fetch(endpoint: .repositoryZip(
            RepositoryZipArgs(
                owner: owner,
                repo: repositoryName,
                branchRef: branchName,
                unzippedResultTargetUrl: repoFileDownloadTarget
            ),
            unzippedRepoReceiver
        ))
    }
}
