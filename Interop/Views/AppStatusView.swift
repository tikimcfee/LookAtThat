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
        VStack {
            Text(status.progress.isReportedProgressActive
                 ? "AppStatus: active, reported"
                 : status.progress.isActive
                 ? "AppStatus: active, flag"
                 : "AppStatus: not active")
            
            if status.progress.isActive {
                clampedProgressViewLabel
            } else {
                progressLabel
            }
        }
    }
    
    @ViewBuilder
    var clampedProgressViewLabel: some View {
        let (safeValue, safeTotal) = (
            min(status.progress.currentValue, status.progress.totalValue),
            max(status.progress.currentValue, status.progress.totalValue)
        )
        ProgressView(
            value: safeValue,
            total: safeTotal,
            label: { progressLabel }
        )
    }
    
    @ViewBuilder
    var progressLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading) {
                Text(status.progress.message)
                Text("\(status.progress.roundedCurrent) / \(status.progress.roundedTotal)")
            }
            Spacer()
            Text(status.progress.detail)
        }
    }
}

class AppStatus: ObservableObject {
    struct AppProgress {
        var message: String = ""
        var detail: String = ""
        var totalValue: Double = 0
        var currentValue: Double = 0
        var isActive: Bool = false
        var isReportedProgressActive: Bool { currentValue < totalValue }
        
        var roundedTotal: Int { Int(totalValue) }
        var roundedCurrent: Int { Int(currentValue) }
    }
    
    @Published private(set) var progress = AppProgress()
    
    func update(_ receiver: (inout AppProgress) -> Void) {
        var current = progress
        receiver(&current)
        DispatchQueue.main.async {
            self.progress = current
        }
    }
    
    func resetProgress() {
        DispatchQueue.main.async {
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
        status.update {
            $0.isActive = true
            $0.message = "Loading grids..."
            $0.totalValue = 15
        }

        QuickLooper(
            interval: .milliseconds(100),
            loop: {
                status.update {
                    $0.currentValue += 1
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
