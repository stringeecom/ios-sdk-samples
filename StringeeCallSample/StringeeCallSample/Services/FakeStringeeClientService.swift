import UIKit

@MainActor
final class DemoStringeeClientService: StringeeClientServiceProtocol {
    var onConnectionStateChange: ((StringeeConnectionState) -> Void)?
    var onIncomingCall: ((CallSessionProtocol) -> Void)?
    private(set) var currentConnectionState: StringeeConnectionState = .disconnected
    private(set) var registeredVoIPToken: String?

    func connect(accessToken: String) {
        emitConnection(.connecting)
        emitConnection(.connected(userId: "demo-user"))
    }

    func disconnect() {
        emitConnection(.disconnected)
    }

    func makeCall(to calleeId: String, kind: CallKind) -> CallSessionProtocol {
        DemoCallSession(kind: kind, direction: .outgoing, remoteUserId: calleeId)
    }

    func registerVoIPPushToken(_ token: String, isProduction: Bool) {
        registeredVoIPToken = token
    }

    func unregisterVoIPPushToken(_ token: String) {
        if registeredVoIPToken == token {
            registeredVoIPToken = nil
        }
    }

    func checkIncomingCallExists(callId: String, completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    func simulateIncoming(kind: CallKind) {
        simulateIncoming(kind: kind, id: UUID().uuidString)
    }

    func simulateIncoming(kind: CallKind, id: String) {
        onIncomingCall?(DemoCallSession(id: id, kind: kind, direction: .incoming, remoteUserId: "demo-caller"))
    }

    private func emitConnection(_ state: StringeeConnectionState) {
        currentConnectionState = state
        onConnectionStateChange?(state)
    }
}

@MainActor
final class DemoCallSession: CallSessionProtocol {
    let id: String
    let kind: CallKind
    let direction: CallDirection
    let remoteUserId: String
    let displayName: String
    let implementationKind: CallImplementationKind = .fake
    var onStateChange: ((CallSessionState) -> Void)?
    var onLocalVideoView: ((UIView) -> Void)?
    var onRemoteVideoView: ((UIView) -> Void)?

    init(id: String = UUID().uuidString, kind: CallKind, direction: CallDirection, remoteUserId: String) {
        self.id = id
        self.kind = kind
        self.direction = direction
        self.remoteUserId = remoteUserId
        self.displayName = remoteUserId
    }

    func start() {
        onStateChange?(.calling)
        if kind == .video {
            emitVideoViews()
        }
    }

    func answer() {
        onStateChange?(.answered)
        if kind == .video {
            emitVideoViews()
        }
        onStateChange?(.mediaConnected)
    }

    func reject() {
        onStateChange?(.ended(reason: "Call rejected"))
    }

    func hangup() {
        onStateChange?(.ended(reason: "Call ended"))
    }

    func setMuted(_ isMuted: Bool) {}
    func setSpeakerEnabled(_ isEnabled: Bool) {}
    func setCameraEnabled(_ isEnabled: Bool) {}

    private func emitVideoViews() {
        let remote = UIView()
        remote.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.35)
        remote.accessibilityIdentifier = "fakeRemoteVideoView"

        let local = UIView()
        local.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.5)
        local.accessibilityIdentifier = "fakeLocalVideoView"

        onRemoteVideoView?(remote)
        onLocalVideoView?(local)
    }
}
