//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import SCNLine
import Foundation

struct RenderPlan {
    let rootPath: URL
    let queue: DispatchQueue
    
    let renderer: ConcurrentGridRenderer
    let state: RecurseState = RecurseState()
    
    var statusObject: AppStatus { CodePagesController.shared.appStatus }
    
    func startRender() {
        queue.async {
            statusObject.resetProgress()
            
            WatchWrap.startTimer("\(rootPath.fileName)")
            cacheGrids()
            
            WatchWrap.stopTimer("\(rootPath.fileName)")
            
            statusObject.update {
                $0.message = "Render complete!"
                $0.currentValue = statusObject.progress.totalValue
            }
        }
    }
}

extension RenderPlan {
    class State {
        let rootPath: URL
        init(rootPath: URL) {
            self.rootPath = rootPath
        }
    }
}

// MARK: - Focus Style

private extension RenderPlan {
    
}

// MARK: - Focus Style

private extension RenderPlan {
    
    
    func doPathRender(
        _ childPath: URL,
        _ state: State
    ) {
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "Layout: \(childPath.lastPathComponent)"
        }
        
        let parentPath = childPath.deletingLastPathComponent()
        // TODO: Do layout
        
        statusObject.update {
            $0.currentValue += 1
            $0.detail = "Layout complete: \(childPath.lastPathComponent)"
        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        let dispatchGroup = DispatchGroup()
        FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .forEach { childPath in
                dispatchGroup.enter()
                statusObject.update {
                    $0.totalValue += 1
                    $0.detail = "File: \(childPath.lastPathComponent)"
                }
                
                renderer.asyncAccess(childPath) { _ in
                    statusObject.update {
                        $0.currentValue += 1
                        $0.detail = "File Complete: \(childPath.lastPathComponent)"
                    }
                    
                    dispatchGroup.leave()
                }
            }
        
        dispatchGroup.wait()
    }
    
    func iterateRoot(
        _ recursive: Bool = true,
        _ receiver: (URL) -> Void
    ) {
        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                receiver(childPath)
            }
    }
}

class WatchWrap {
    static let stopwatch = Stopwatch(running: false)
    
    static func startTimer(_ name: String) {
        print("[* StopWatch *] Starting \(name)")
        stopwatch.start()
        
    }
    static func stopTimer(_ name: String) {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = Self.stopwatch.elapsedTimeString()
        print("[* Stopwatch *] Time for \(name): \(time)")
    }
}
