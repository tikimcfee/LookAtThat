//
//  FilePaths.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import Zip

// MARK: - File Operations
public struct AppFiles {
    
    private static let fileManager = FileManager.default
    
    private static var documentsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func directory(named directoryName: String) -> URL {
        let directory = documentsDirectory.appendingPathComponent(directoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }
    
    public static func file(named fileName: String, in directory: URL) -> URL {
        let fileUrl = directory.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileUrl.path) {
            fileManager.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil)
        }
        return fileUrl
    }
    
    public static func touch(in fileURL: URL) {
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        }
    }
    
    public static func move(fileUrl: URL, to targetUrl: URL) throws {
        print("Moving:\n\t\(fileUrl)\n\t\(targetUrl)")
        try fileManager.moveItem(at: fileUrl, to: targetUrl)
    }
    
    public static func delete(fileUrl: URL) {
        guard fileManager.isDeletableFile(atPath: fileUrl.path) else {
            print("Not deletable: \(fileUrl)")
            return
        }
        do {
            try fileManager.removeItem(at: fileUrl)
        } catch {
            print("Failed to remove item", error)
        }
    }
    
    public static func unzip(fileUrl: URL, to targetUrl: URL) throws {
        Zip.addCustomFileExtension("tmp")
        try Zip.unzipFile(fileUrl, destination: targetUrl, overwrite: true, password: nil)
    }
}

// MARK: -- Rewrites

extension AppFiles {
    public static var rewritesDirectory: URL {
        directory(named: "rewrites")
    }
}

// MARK: - Downloaded Repos

extension AppFiles {
    public static var githubRepositoriesRoot: URL {
        directory(named: "github-repositories")
    }
    
    public static var allRepositoryRoots: [URL] {
        githubRepositoriesRoot
            .children()
    }
    
    public static var allDownloadedRepositories: [URL] {
        githubRepositoriesRoot
            .children()
            .map { url in
                if let firstChild = url.children().first {
                    return firstChild
                } else {
                    return url
                }
            }
    }
}


// MARK: - Tracing

extension AppFiles {
    private static let traceNameIDsPrefix = "app-trace-id-list-"
    private static let traceNameDefaultMapName = "app-trace-map-default.txt"
    
    public static var tracesDirectory: URL {
        directory(named: "traces")
    }
    
    public static func createTraceIDFile(named newFileName: String) -> URL {
        let prefixedName = "\(traceNameIDsPrefix)\(newFileName).txt"
        print("Created new trace ID list file: \(prefixedName)")
        return file(named: prefixedName, in: tracesDirectory)
    }
    
    public static func getDefaultTraceMapFile() -> URL {
        return file(named: traceNameDefaultMapName, in: tracesDirectory)
    }
    
    public static func allTraceFiles() -> [URL] {
        return tracesDirectory.children().filter {
            $0.lastPathComponent.starts(with: traceNameIDsPrefix)
        }
    }
}

// MARK: -- Scene Output

extension AppFiles {
    public static var sceneOutputDirectory: URL {
        directory(named: "sceneOutput")
    }
    
    public static var defaultSceneOutputFile: URL {
        file(named: "default-cherriei-view", in: sceneOutputDirectory)
    }
}
