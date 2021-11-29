import MultipeerConnectivity
import SwiftUI
import Foundation

struct MultipeerInfoView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager

    @State var selectedPeer: PeerConnection?
    @State var isChangingName = false
    @State var displayName = UserKeys.peerDisplayName.safeValue(using: "")
    
    var body: some View {
        let baseView = VStack(spacing: 0) {
            displayNameView
            PeerListView(selectedPeer: $selectedPeer)
            MessageSendView(selectedPeer: $selectedPeer)
            MultipeerStateView(selectedPeer: $selectedPeer)
        }.background(Color.gray.opacity(0.3))
        .onReceive(
            manager.stateStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: RunLoop.main)
        ) { item in
            displayName = item.displayName
        }
        .sheet(isPresented: $isChangingName) {
            ChangeNameView(
                isChangingName: $isChangingName,
                originalDisplayName: manager.currentConnection.myPeerId.displayName
            ).environmentObject(MultipeerConnectionManager.shared)
        }
        #if os(OSX)
        return baseView
        #else
        return baseView
        #endif

    }

    var displayNameView: some View {
        Button(action: { isChangingName = true }) {
            VStack(alignment: .leading) {
                Text("My display name (tap to change)")
                    .font(.caption)
                    .fontWeight(.heavy)
                Text(displayName)
                    .font(.footnote)
            }
        }
        .buttonStyle(FitButtonLabelStyle())
        .padding(.top, 8)
    }
}

struct MultipeerStateViewModel {
    var displayName: String = UserKeys.peerDisplayName.safeValue(using: "")
    var isBrowsing: Bool = false
    var isAdvertising: Bool = false
}

struct FitButtonLabelStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(4)
            .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
            .background(configuration.isPressed ? Color.gray : Color.gray)
            .cornerRadius(4)
    }
}

struct MultipeerStateView: View {
    @EnvironmentObject var manager: MultipeerConnectionManager
    @State var viewModel: MultipeerStateViewModel = MultipeerStateViewModel()
    @Binding var selectedPeer: PeerConnection?

    var body: some View {
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Finding Peers")
                startBrowsingButton
                startAdvertisingButton
            }.padding(8).overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
            HStack {
                sendCodeSheetButton
                startStreamButton
            }
        }
        .padding(8)
        .onReceive(
            manager.stateStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: RunLoop.main)
        ) { item in
            viewModel = item
        }
    }

    var startBrowsingButton: some View {
        VStack(spacing: 4) {
            Button(action: { manager.startBrowser() }) {
                Text(
                    viewModel.isBrowsing
                        ? "Stop browsing"
                        : "Start browsing"
                )
            }
            .buttonStyle(FitButtonLabelStyle())
            Circle()
                .foregroundColor(
                    viewModel.isBrowsing
                        ? .green
                        : .red
                )
                .frame(width: 10, height: 10)
        }
    }

    var startAdvertisingButton: some View {
        VStack(spacing: 4) {
            Button(action: { manager.startAdvertiser() }) {
                Text(
                    viewModel.isAdvertising
                        ? "Stop advertising"
                        : "Start advertising"
                )
            }
            .buttonStyle(FitButtonLabelStyle())
            Circle()
                .foregroundColor(
                    viewModel.isAdvertising
                        ? .green
                        : .red
                )
                .frame(width: 10, height: 10)
        }
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

    var startStreamButton: some View {
        Button(action: {
            guard let selectedPeer = selectedPeer else { return }
            manager.openStream(to: selectedPeer.targetPeerId)
        }) {
            Text("Open stream")
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
                }
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray)
            )
        }
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
    @State var event: FileBrowser.Event = .noSelection

    var body: some View {
        return VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 8) {
                TextField("Type a message", text: $message)
                    .lineLimit(0)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray)
                    )
                Button(action: sendMessageToPeers) {
                    Text("Send").padding(8)
                }
                .buttonStyle(FitButtonLabelStyle())
                .disabled(selectedPeer == nil)
            }.padding(4)

            if let peer = selectedPeer {
                VStack {
                    Text("Sending a message to '\(peer.targetPeerId.displayName)'")
                        .font(.footnote)
                        .fontWeight(.light)
                        .italic()
                }.padding(8)
            }
        }.onReceive(
            SceneLibrary.global.codePagesController.fileEventStream
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
        ) { event in
            self.event = event
            sendFileStreamToPeers()
        }
    }
    
    func sendFileStreamToPeers() {
        guard let peer = selectedPeer else {
            print("Well so much for the disabled state")
            return
        }
        
        switch event {
        case let .newSingleCommand(path, _):
            guard let fileData = try? Data(contentsOf: path.url),
                  let compressed = manager.sheetDataTransformer.compress(fileData) else {
                print("No file data it exploded what a shame")
                return
            }
            
            manager.multipeerStreamController.streamRaw(to: peer.targetPeerId, compressed)
        case let .newSinglePath(path):
            guard let fileData = try? Data(contentsOf: path.url),
                  let compressed = manager.sheetDataTransformer.compress(fileData) else {
                print("No file data it exploded what a shame")
                return
            }
            manager.multipeerStreamController.streamRaw(to: peer.targetPeerId, compressed)
        default:
            print("Ignoring event: \(event)")
        }
    }

    func sendMessageToPeers() {
        guard let peer = selectedPeer else {
            print("Well so much for the disabled state")
            return
        }
//        manager.send(message: message, to: peer.targetPeerId)
        manager.multipeerStreamController.streamMessage(to: peer.targetPeerId, message)
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
    private var onSet: ((Value) -> Void)?
    init(_ start: Value) {
        self.current = start
    }
    init(_ start: Value, onSet: @escaping (Value) -> Void) {
        self.current = start
        self.onSet = onSet
    }
    lazy var binding = Binding<Value>(
        get: { return self.current },
        set: { (val: Value) in
            self.current = val
            self.onSet?(val)
        }
    )
}
