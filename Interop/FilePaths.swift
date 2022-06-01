//
//  FilePaths.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation

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
    
    public static func move(
        fileUrl: URL,
        to targetUrl: URL
    ) {
        print("Moving:\n\t\(fileUrl)\n\t\(targetUrl)")
        do {
            try fileManager.moveItem(at: fileUrl, to: targetUrl)
        } catch {
            print("Could not move file", error)
        }
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
    public static var githubRepos: URL {
        directory(named: "github-repositories")
    }
    
    public static var allRepositoryURLs: [URL] {
        githubRepos.children()
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
