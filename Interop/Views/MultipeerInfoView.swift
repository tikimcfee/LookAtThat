import MultipeerConnectivity
import SwiftUI
import Foundation

struct MultipeerInfoView: View {
    @State var selectedPeer: PeerConnection?
    
    var body: some View {
        VStack(spacing: 0) {
            MultipeerStateView()
            PeerListView(selectedPeer: $selectedPeer)
            MessageSendView(selectedPeer: $selectedPeer)
        }.background(Color.gray.opacity(0.3))
    }
}

struct MultipeerStateViewModel {
    var displayName: String = UserKeys.peerDisplayName.safeValue(using: "")
    var isBrowsing: Bool = false
    var isAdvertising: Bool = false
    var startBrowsing: () -> Void = { }
    var startAdvertising: () -> Void = { }
}

struct MultipeerStateView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager
    var viewModel: MultipeerStateViewModel { manager.peerDiscoveryState }

    var body: some View {
        return HStack {
            displayName
            Spacer()
            startBrowsingButton
            startAdvertisingButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    var displayName: some View {
        Text(viewModel.displayName)
            .fontWeight(.heavy)
    }

    var startBrowsingButton: some View {
        Button(action: viewModel.startBrowsing) {
            Text(
                viewModel.isBrowsing
                    ? "Browsing..."
                    : "Start browsing"
            )
        }
        .disabled(viewModel.isAdvertising)
        .padding(8).overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }

    var startAdvertisingButton: some View {
        Button(action: viewModel.startAdvertising) {
            Text(
                viewModel.isAdvertising
                    ? "Advertising..."
                    : "Start advertising"
            )
        }
        .disabled(viewModel.isBrowsing)
        .padding(8).overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }
}

struct PeerListView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager
    @Binding var selectedPeer: PeerConnection?
    @State var currentPeers = [PeerConnection]()

    var body: some View {
        return List {
            Text("Peers").underline()
            ForEach(currentPeers, id:\.targetPeerId.displayName) { peer in
                Button(action: { selectPeer(peer) }) {
                    HStack {
                        Text(peer.targetPeerId.displayName)
                        Spacer()
                        Text(peer.state.description)
                            .foregroundColor(Color.gray)
                            .italic()
                            .fontWeight(.light)
                    }
                }.frame(maxWidth: UIScreen.main.bounds.width, alignment: .leading)
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
        }
        .frame(maxWidth: UIScreen.main.bounds.width, minHeight: 128, alignment: .topLeading)
        .padding(8)
        .onReceive(
            manager.peerStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: RunLoop.main)
        ) { currentPeers = Array($0.values) }
    }

    func selectPeer(_ peer: PeerConnection) {
        selectedPeer = peer
    }
}

struct MessageSendView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager
    @Binding var selectedPeer: PeerConnection?
    @State var message: String = ""

    var body: some View {
        return VStack(alignment: .trailing, spacing: 0) {
            HStack {
                TextField("Type a message", text: $message)
                    .lineLimit(0)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray)
                    )
                    .padding(8)
                Button(action: sendMessageToPeers) {
                    Text("Send").padding(8)
                }.disabled(selectedPeer == nil)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray)
                ).padding(8)
            }
            if let peer = selectedPeer {
                VStack {
                    Text("Sending a message to '\(peer.targetPeerId.displayName)'")
                        .font(.footnote)
                        .fontWeight(.light)
                        .italic()
                }.padding(8)
            }
        }
    }

    func sendMessageToPeers() {
        guard let peer = selectedPeer else {
            print("Well so much for the disabled state")
            return
        }
        manager.send(message: message, to: peer.targetPeerId)
    }
}

#if DEBUG
struct MessageSendView_Previews: PreviewProvider {
    static let current = WrappedBinding<PeerConnection?>(
        PeerConnection(targetPeerId: .init(displayName: "Sup"), state: .connected)
    )

    static var previews: some View {
        return MultipeerInfoView()
    }
}
#endif

public class WrappedBinding<Value> {
    private var current: Value
    init(_ start: Value) {
        self.current = start
    }
    lazy var binding = Binding<Value>(
        get: { return self.current },
        set: { (val: Value) in self.current = val }
    )
}
