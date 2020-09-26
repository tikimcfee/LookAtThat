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

struct MultipeerStateView: View {
    var body: some View {
        return VStack(alignment: .trailing) {
            Button(action: startBrowser) {
                Text("Start browser")
            }.padding(8).overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )

            Button(action: startAdvertiser) {
                Text("Start advertiser")
            }.padding(8).overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    func startBrowser() {
        MultipeerConnectionManager.shared.startBrowser()
    }

    func startAdvertiser() {
        MultipeerConnectionManager.shared.startAdvertiser()
    }
}

struct PeerListView: View {
    @Binding var selectedPeer: PeerConnection?
    @State var currentPeers = [PeerConnection]()

    var body: some View {
        return VStack(alignment: .leading) {
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
            MultipeerConnectionManager.shared.sharedConnectionStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: RunLoop.main)
        ) { currentPeers = Array($0.values) }
    }

    func selectPeer(_ peer: PeerConnection) {
        selectedPeer = peer
    }
}

struct MessageSendView: View {
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
                }.overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray)
                ).padding(8)
            }
            if let peer = selectedPeer {
                VStack {
                    Text("Sending a message to '\(peer.targetPeerId.displayName)'")
                        .fontWeight(.light)
                        .italic()
                }.padding(8)
            }
        }
    }

    func sendMessageToPeers() {
        guard let peer = selectedPeer else {
            fatalError("HOW DID THIS HAPPEN!?")
        }
        MultipeerConnectionManager.shared.send(message: message, to: peer.targetPeerId)
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
