//
//  GitHubClientView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/1/22.
//

import SwiftUI
import Combine

class GitHubClientViewState: ObservableObject {
    @Published var repoUrls: [URL] = []
    
    @Published var enabled: Bool = true
    
    @Published var repoName: String = "" { didSet { evalInput() }}
    @Published var owner: String = "" { didSet { evalInput() }}
    @Published var branch: String = "" { didSet { evalInput() }}
    
    @Published var error: Error?
    
    init() {
        self.repoUrls = AppFiles.allDownloadedRepositories
        self.evalInput()
    }
    
    private func evalInput() {
        enabled = !(
            repoName.isEmpty
            || owner.isEmpty
        )
    }
    
    func doRepositoryDownload() {
        guard enabled else { return }
        enabled = false
        
        GitHubClient.shared.downloadAndUnzipRepository(
            owner: owner,
            repositoryName: repoName,
            branchName: branch
        ) { result in
            DispatchQueue.main.async {
                self.onRepositoryDownloaded(result)
            }
        }
    }
    
    func deleteURL(_ url: URL) {
        guard let index = repoUrls.firstIndex(of: url) else {
            print("Man where did you get that that url from?")
            return
        }
        AppFiles.delete(fileUrl: url)
        repoUrls.remove(at: index)
    }
    
    private func onRepositoryDownloaded(_ downloadResult: Result<URL, Error>) {
        switch downloadResult {
        case .success(let url):
            print("Retrieved URL: \(url)")
            self.repoUrls.append(url)
            
        case .failure(let error):
            self.error = error
        }
        self.enabled = true
    }
}

struct GitHubClientView: View {
    
    @StateObject var clientState = GitHubClientViewState()
    
    @ViewBuilder
    var body: some View {
        rootBodyView
            .padding()
            .fixedSize()
    }
    
    @ViewBuilder
    var rootBodyView: some View {
        #if os(iOS)
        VStack(alignment: .leading) {
            repoListView
                .padding()
                .border(.gray, width: 1.0)
            Spacer()
            repoInfoCaptureView
                .padding()
                .border(.gray, width: 1.0)
            repoDownloadStateView
                .padding()
                .border(.gray, width: 1.0)
        }
        #elseif os(macOS)
        HStack(alignment: .top) {
            repoInfoCaptureView
            repoDownloadStateView
            repoListView
        }
        #endif
    }
    
    @ViewBuilder
    var repoInfoCaptureView: some View {
        VStack(alignment: .leading) {
            Text("Repository Download")
            TextField("Name", text: $clientState.repoName)
            TextField("Owner", text: $clientState.owner)
            TextField("Branch (leave empty for default)", text: $clientState.branch)
        }
    }
    
    @ViewBuilder
    var repoDownloadStateView: some View {
        VStack {
            Button("Download Repo") {
                clientState.doRepositoryDownload()
            }.disabled(!clientState.enabled)
            
            if let error = clientState.error {
                VStack {
                    Text("Download error")
                    Text("\(error.localizedDescription)")
                }.foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    var repoListView: some View {
        ScrollView {
            VStack {
                ForEach(clientState.repoUrls, id: \.path) { url in
                    HStack {
                        Text("\(url.lastPathComponent)")
                        Spacer()
                        Button("╳", action: { clientState.deleteURL(url) })
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.3))
                    .onTapGesture { onRepositoryUrlSelected(url) }
                }
            }
        }
        .frame(width: 256.0)
    }
    
    func onRepositoryUrlSelected(_ url: URL) {
        GlobalInstances
            .fileBrowser
            .fileSelectionEvents = .newMultiCommandRecursiveAllLayout(url, .addToWorld)
        GlobalInstances
            .fileBrowser
            .setRootScope(url)
    }
}

struct GitHubClientView_Preview: PreviewProvider {
    static let sampleState: GitHubClientViewState = {
        let state = GitHubClientViewState()
        state.repoUrls = [
            URL(fileURLWithPath: "/var/users/some-lib/downloaded-here/ACoolName"),
            URL(fileURLWithPath: "/var/users/some-lib/downloaded-here/A Very Lengthy Name with Stuff"),
            URL(fileURLWithPath: "/var/users/some-lib/downloaded-here/liblol")
        ]
        return state
    }()
    
    static var previews: some View {
        GitHubClientView(clientState: sampleState)
            
    }
}
