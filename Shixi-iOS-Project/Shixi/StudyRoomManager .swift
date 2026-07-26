// StudyRoomManager.swift
import MultipeerConnectivity
import Combine

class StudyRoomManager: NSObject, ObservableObject {
    @Published var isHost = false
    @Published var roomCode = ""
    @Published var isConnected = false
    @Published var connectedPeerCount = 0
    @Published var connectionError: String?

    var onReceiveMessage: ((Message) -> Void)?
    var onPeerConnected: (() -> Void)?

    private let serviceType = "shixi-room"
    private let myPeerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
    }

    func startHost() {
        isHost = true
        roomCode = generateRoomCode()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: ["roomCode": roomCode],
                                               serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func startClient(with code: String) {
        isHost = false
        roomCode = code
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func disconnect() {
        session.disconnect()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        isConnected = false
        connectedPeerCount = 0
        roomCode = ""
        isHost = false
        connectionError = nil
    }

    func sendMessage(_ message: Message) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        guard session.connectedPeers.count > 0 else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("发送消息失败: \(error)")
        }
    }

    private func generateRoomCode() -> String {
        String(format: "%06d", Int.random(in: 100000...999999))
    }
}

extension StudyRoomManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedPeerCount = session.connectedPeers.count
                if self.isHost {
                    self.onPeerConnected?()
                }
            case .connecting:
                break
            case .notConnected:
                self.isConnected = false
                self.connectedPeerCount = session.connectedPeers.count
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else { return }
        DispatchQueue.main.async {
            self.onReceiveMessage?(message)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension StudyRoomManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.connectionError = "广播失败: \(error.localizedDescription)"
        }
    }
}

extension StudyRoomManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let discoveredCode = info?["roomCode"], discoveredCode == roomCode else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.connectionError = "搜索失败: \(error.localizedDescription)"
        }
    }
}

enum Message: Codable {
    case stateUpdate(StatePayload)

    struct StatePayload: Codable {
        let remainingSeconds: Int
        let totalSeconds: Int
        let isRunning: Bool
        let isPaused: Bool
        let timerMode: String
        let pomoPhase: String?
        let currentStationIndex: Int
        let isMusicPlaying: Bool
        let volume: Double
    }
}
