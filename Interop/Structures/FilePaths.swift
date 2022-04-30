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
}

// MARK: -- Rewrites

extension AppFiles {
    public static var rewritesDirectory: URL {
        directory(named: "rewrites")
    }
}


// MARK: - Tracing

extension AppFiles {
    private static let traceNamePrefix = "app-trace-output-"
    
    public static var tracesDirectory: URL {
        directory(named: "traces")
    }
        
    public static func createTraceFile(named newFileName: String) -> URL {
        let newFileName = "\(traceNamePrefix)\(newFileName).txt"
        print("Created new trace file: \(newFileName)")
        return file(named: newFileName, in: tracesDirectory)
    }
    
    public static func allTraceFiles() -> [URL] {
        guard let tracesRoot = FileKitPath(url: tracesDirectory) else {
            print("Cannot make path: \(tracesDirectory)")
            return []
        }
        
        return tracesRoot.children().filter {
            !$0.isDirectory && $0.fileName.starts(with: traceNamePrefix)
        }.map { $0.url }
    }
}
