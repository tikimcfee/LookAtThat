import MultipeerConnectivity
import SwiftUI
import Foundation

struct MultipeerInfoView: View {
    @State var selectedPeer: PeerConnection?
    
    var body: some View {
        VStack(spacing: 0) {
            PeerListView(selectedPeer: $selectedPeer)
            MessageSendView(selectedPeer: $selectedPeer)
            MultipeerStateView(selectedPeer: $selectedPeer)
        }.background(Color.gray.opacity(0.3))
    }
}

struct MultipeerStateViewModel {
    var displayName: String = UserKeys.peerDisplayName.safeValue(using: "")
    var isBrowsing: Bool = false
    var isAdvertising: Bool = false
}

struct MultipeerStateView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager
    @State var viewModel: MultipeerStateViewModel = MultipeerStateViewModel()
    @State var isChangingName = false
    @Binding var selectedPeer: PeerConnection?

    var body: some View {
        return VStack {
            displayName
            HStack {
                startBrowsingButton
                startAdvertisingButton
            }
            HStack {
                sendCodeSheetButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .sheet(isPresented: $isChangingName) {
            ChangeNameView(
                isChangingName: $isChangingName,
                originalDisplayName: manager.currentConnection.myPeerId.displayName
            ).environmentObject(MultipeerConnectionManager.shared)
        }
        .onReceive(
            manager.stateStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: RunLoop.main)
        ) { item in
            viewModel = item
        }

    }

    var displayName: some View {
        Button(action: { isChangingName = true }) {
            VStack(alignment: .leading) {
                Text("My display name (tap to change)")
                    .font(.caption)
                    .fontWeight(.heavy)
                Text(viewModel.displayName)
                    .font(.footnote)
            }
        }
        .foregroundColor(Color.purple)
        .padding(8)
    }

    var startBrowsingButton: some View {
        Button(action: { manager.startBrowser() }) {
            Text(
                viewModel.isBrowsing
                    ? "Browsing..."
                    : "Start browsing"
            )
        }
        .disabled(viewModel.isBrowsing)
        .padding(8).overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }

    var startAdvertisingButton: some View {
        Button(action: { manager.startAdvertiser() }) {
            Text(
                viewModel.isAdvertising
                    ? "Advertising..."
                    : "Start advertising"
            )
        }
        .disabled(viewModel.isAdvertising)
        .padding(8).overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }

    var sendCodeSheetButton: some View {
        Button(action: {
            guard let selectedPeer = selectedPeer else { return }
            manager.sendCodeSheet(to: selectedPeer.targetPeerId)
        }) {
            Text("Send code sheet")
        }
        .padding(8).overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray)
        )
    }
}

struct ChangeNameView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager

    @Binding var isChangingName: Bool
    var originalDisplayName: String = ""
    @State var displayName: String = ""

    var nameLengthRange = 5...15
    var nameLength: Bool { return nameLengthRange.contains(displayName.count) }
    var validString: Bool { displayName.allSatisfy { character in
        return character.isLetter || character.isNumber
    }}

    var isDisabled: Bool {
        return !(nameLength && validString)
    }

    var buttonText: String {
        isDisabled
            ? "Fix name to save"
            : "Save"
    }

    var problemText: String {
        if isDisabled {
            if !nameLength {
                return "Name is \(displayName.count), should be between (\(nameLengthRange))"
            } else if !validString {
                return "Letters and numbers only, please."
            } else {
                return "If you see this: Sorry, we messed up."
            }
        } else {
            return ""
        }
    }

    var body: some View {
        return VStack(alignment: .leading) {
            Spacer()
            Text("Current name")
                .underline()
            Text(originalDisplayName)
                .font(.footnote)
                .padding(8)

            Text("New name")
                .underline()
            #if os(iOS)
            TextField("Enter a new name here", text: $displayName)
                .keyboardType(.namePhonePad)
                .font(.footnote)
                .lineLimit(0)
                .multilineTextAlignment(.leading)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray)
                )
            #elseif os(OSX)
            TextField("Enter a new name here", text: $displayName)
                .lineLimit(0)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray)
                )
            #endif

            Spacer()
            Button(action: saveDisplayName) {
                Text(buttonText)
                    .padding(8)
            }
            .disabled(isDisabled)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
            if isDisabled && displayName.count >= nameLengthRange.first! {
                Text(problemText)
                    .font(.footnote)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color.red.opacity(0.6))
            }
        }
        .padding(8)
        .frame(maxHeight: .infinity)
        .background(Color.gray.opacity(0.4))
    }

    func saveDisplayName() {
        guard !isDisabled else { return }
        manager.setDisplayName(to: displayName)
        isChangingName = false
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
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
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
    static var previews: some View {
        return MultipeerInfoView()
            .environmentObject(MultipeerConnectionManager.shared)
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
