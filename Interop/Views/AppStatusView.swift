//
//  AppStatusView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/22.
//

import SwiftUI

struct AppStatusView: View {
    @ObservedObject var status: AppStatus
    
    var body: some View {
        mainView
            .padding()
            .frame(width: 640.0)
    }
    
    @ViewBuilder
    var mainView: some View {
        if status.progress.isActive {
            ProgressView(
                value: status.progress.currentValue,
                total: status.progress.totalValue,
                label: { progressLabel }
            )
        } else {
            Text("Application Idle")
        }
    }
    
    @ViewBuilder
    var progressLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading) {
                Text(status.progress.message)
                Text("\(status.progress.roundedCurrent) / \(status.progress.roundedTotal)")
            }
            Text(status.progress.detail)
            List(status.progress.startedItems, id: \.id) { item in
                Text(item.name)
            }.frame(width: 300.0, height: 120.0)
            
            List(status.progress.finishedItems, id: \.id) { item in
                Text(item.name)
            }.frame(width: 300.0, height: 120.0)
        }
    }
}

class AppStatus: ObservableObject {
    struct AppProgress {
        struct Item: Equatable, Identifiable {
            let id: String = UUID().uuidString
            let name: String
        }
        
        var message: String = ""
        var detail: String = ""
        var isActive: Bool = false
        
        private(set) var startedItems: [Item] = []
        private(set) var finishedItems: [Item] = []
        
        mutating func start(_ item: Item) {
            startedItems.insert(item, at: 0)
        }
        
        mutating func finish(_ item: Item) {
            startedItems.removeAll(where: { $0 == item })
            finishedItems.insert(item, at: 0)
        }
        
        var totalValue: Double { Double(startedItems.count) + Double(finishedItems.count) }
        var currentValue: Double { Double(finishedItems.count) }
        var roundedTotal: Int { Int(totalValue) }
        var roundedCurrent: Int { Int(currentValue) }
    }
    
    @Published private(set) var progress = AppProgress()
    
    func update(_ receiver: (inout AppProgress) -> Void) {
        var current = progress
        receiver(&current)
        DispatchQueue.main.sync {
//            withAnimation {
                self.progress = current
//            }
        }
    }
    
    func resetProgress() {
        DispatchQueue.main.sync {
            self.progress = AppProgress()
        }
    }
}

struct AppStatusView_Previews: PreviewProvider {
    static let testDetails = [
        "Reticulating splines...",
        "Burrowing stash...",
        "Executing order 33...",
        "Building bridges...",
        "Burning built bridges...",
        "Repairing bridges...",
        "Attoning for sins...",
        "Supplying rebels with supplies...",
        "Narfling the Garthok..."
    ]
    
    static var status: AppStatus {
        let status = AppStatus()
        status.update { outStatus in
            outStatus.isActive = true
            outStatus.message = "Loading grids..."
            (0...10)
                .map { AppStatus.AppProgress.Item(name: "File_\($0)") }
                .forEach { outStatus.start($0) }
            (11...20)
                .map { AppStatus.AppProgress.Item(name: "File_\($0)") }
                .forEach { outStatus.finish($0) }
        }

        QuickLooper(
            interval: .milliseconds(100),
            loop: {
                status.update {
                    guard let first = $0.startedItems.first else { return }
                    $0.finish(first)
                    $0.detail = testDetails.randomElement()!
                }
            }
        ).runUntil(onStop: {
            status.update { $0.message = "Done!" }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                status.update { $0.isActive = false }
            }
        }) {
            status.progress.currentValue >= status.progress.totalValue
        }
        return status
    }
    static var previews: some View {
        AppStatusView(status: status)
    }
}
