#if canImport(Stringee)
import Stringee
import UIKit

final class StringeeSDKAdapter: NSObject, StringeeClientServiceProtocol {
    var onConnectionStateChange: ((StringeeConnectionState) -> Void)?
    var onIncomingCall: ((CallSessionProtocol) -> Void)?
    private(set) var currentConnectionState: StringeeConnectionState = .disconnected

    private let client = StringeeClient()
    private var accessToken = ""

    override init() {
        super.init()
        client.connectionDelegate = self
        client.incomingCallDelegate = self
    }

    func connect(accessToken: String) {
        self.accessToken = accessToken
        SampleLog.client("connect requested")
        emitConnection(.connecting)
        client.connect(withAccessToken: accessToken)
    }

    func disconnect() {
        SampleLog.client("disconnect requested")
        client.disconnect()
        emitConnection(.disconnected)
    }

    func makeCall(to calleeId: String, kind: CallKind) -> CallSessionProtocol {
        switch kind {
        case .voice:
            let call = StringeeCall(stringeeClient: client, from: client.userId ?? "", to: calleeId)
            let session = StringeeCallSession(call: call, direction: .outgoing)
            SampleLog.call("make outgoing voice session \(session.logDescription)")
            return session
        case .video:
            let call = StringeeCall2(stringeeClient: client, from: client.userId ?? "", to: calleeId)
            call?.isVideoCall = true
            let session = StringeeCall2Session(call: call, direction: .outgoing)
            SampleLog.call("make outgoing video session \(session.logDescription)")
            return session
        }
    }

    func registerVoIPPushToken(_ token: String, isProduction: Bool) {
        client.registerPush(forDeviceToken: token, isProduction: isProduction, isVoip: true) { status, code, message in
            SampleLog.client("registerPush status=\(status) code=\(code) message=\(message ?? "")")
        }
    }

    func unregisterVoIPPushToken(_ token: String) {
        client.unregisterPush(forDeviceToken: token) { status, code, message in
            SampleLog.client("unregisterPush status=\(status) code=\(code) message=\(message ?? "")")
        }
    }

    func checkIncomingCallExists(callId: String, completion: @escaping (Bool) -> Void) {
        client.existIncomingCall(withCallId: callId) { status, code, message, exists in
            SampleLog.client("existIncomingCall callId=\(callId) status=\(status) code=\(code) exists=\(exists) message=\(message ?? "")")
            DispatchQueue.main.async {
                completion(status && exists)
            }
        }
    }

    private func emitConnection(_ state: StringeeConnectionState) {
        currentConnectionState = state
        onConnectionStateChange?(state)
    }
}

extension StringeeSDKAdapter: StringeeConnectionDelegate {
    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        SampleLog.client("didConnect userId=\(stringeeClient.userId ?? "") isReconnecting=\(isReconnecting)")
        DispatchQueue.main.async { [weak self] in
            self?.emitConnection(.connected(userId: stringeeClient.userId ?? ""))
        }
    }

    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        SampleLog.client("didDisConnect isReconnecting=\(isReconnecting)")
        DispatchQueue.main.async { [weak self] in
            self?.emitConnection(isReconnecting ? .reconnecting : .disconnected)
        }
    }

    func didFailWithError(_ stringeeClient: StringeeClient!, code: Int32, message: String!) {
        SampleLog.client("didFailWithError code=\(code) message=\(message ?? "")")
        DispatchQueue.main.async { [weak self] in
            self?.emitConnection(.failed(message: message ?? "Code \(code)"))
        }
    }

    func requestAccessToken(_ stringeeClient: StringeeClient!) {
        SampleLog.client("requestAccessToken")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.emitConnection(.tokenExpired)
            if !self.accessToken.isEmpty {
                stringeeClient.connect(withAccessToken: self.accessToken)
            }
        }
    }

    func didReceiveCustomMessage(_ stringeeClient: StringeeClient!, message: [AnyHashable: Any]!, fromUserId userId: String!) {}
}

extension StringeeSDKAdapter: StringeeIncomingCallDelegate {
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {
        let session = StringeeCallSession(call: stringeeCall, direction: .incoming)
        SampleLog.call("incoming StringeeCall \(session.logDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.onIncomingCall?(session)
        }
    }

    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall2: StringeeCall2!) {
        let session = StringeeCall2Session(call: stringeeCall2, direction: .incoming)
        SampleLog.call("incoming StringeeCall2 \(session.logDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.onIncomingCall?(session)
        }
    }
}

private final class StringeeCallSession: NSObject, CallSessionProtocol {
    let id: String
    let kind: CallKind
    let direction: CallDirection
    let remoteUserId: String
    let displayName: String
    let implementationKind: CallImplementationKind = .stringeeCall
    var onStateChange: ((CallSessionState) -> Void)?
    var onLocalVideoView: ((UIView) -> Void)?
    var onRemoteVideoView: ((UIView) -> Void)?

    private let call: StringeeCall

    init(call: StringeeCall!, direction: CallDirection) {
        self.call = call
        self.id = call.callId ?? UUID().uuidString
        self.kind = call.isVideoCall ? .video : .voice
        self.direction = direction
        self.remoteUserId = direction == .incoming ? (call.from ?? "") : (call.to ?? "")
        self.displayName = call.fromAlias?.isEmpty == false ? call.fromAlias : self.remoteUserId
        super.init()
        self.call.delegate = self
        if direction == .incoming {
            SampleLog.call("init answer StringeeCall id=\(id)")
            self.call.initAnswer()
        }
    }

    func start() {
        SampleLog.call("start StringeeCall \(logDescription)")
        call.make { [weak self] status, _, message, _ in
            SampleLog.call("make callback StringeeCall id=\(self?.id ?? "") status=\(status) message=\(message ?? "")")
            guard !status else { return }
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call failed"))
            }
        }
    }

    func answer() {
        SampleLog.call("answer requested StringeeCall \(logDescription)")
        call.answer { [weak self] status, _, message in
            SampleLog.call("answer callback StringeeCall id=\(self?.id ?? "") status=\(status) message=\(message ?? "")")
            guard !status else { return }
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Answer failed"))
            }
        }
    }

    func reject() {
        SampleLog.call("reject requested StringeeCall \(logDescription)")
        call.reject { [weak self] _, _, message in
            SampleLog.call("reject callback StringeeCall id=\(self?.id ?? "") message=\(message ?? "")")
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call rejected"))
            }
        }
    }

    func hangup() {
        SampleLog.call("hangup requested StringeeCall \(logDescription)")
        call.hangup { [weak self] _, _, message in
            SampleLog.call("hangup callback StringeeCall id=\(self?.id ?? "") message=\(message ?? "")")
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call ended"))
            }
        }
    }

    func setMuted(_ isMuted: Bool) {
        SampleLog.call("setMuted StringeeCall id=\(id) isMuted=\(isMuted)")
        call.mute(isMuted)
    }

    func setSpeakerEnabled(_ isEnabled: Bool) {
        SampleLog.call("setSpeakerEnabled StringeeCall id=\(id) isEnabled=\(isEnabled)")
        StringeeAudioManager.instance()?.setLoudspeaker(isEnabled)
    }

    func setCameraEnabled(_ isEnabled: Bool) {
        SampleLog.call("setCameraEnabled StringeeCall id=\(id) isEnabled=\(isEnabled)")
        _ = call.enableLocalVideo(isEnabled)
    }
}

extension StringeeCallSession: StringeeCallDelegate {
    func didChangeSignalingState(_ stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        SampleLog.call("signaling StringeeCall id=\(id) state=\(signalingState) reason=\(reason ?? "") sipCode=\(sipCode) sipReason=\(sipReason ?? "")")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(Self.map(signalingState: signalingState, reason: reason))
        }
    }

    func didChangeMediaState(_ stringeeCall: StringeeCall!, mediaState: MediaState) {
        SampleLog.call("media StringeeCall id=\(id) state=\(mediaState)")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(mediaState == .connected ? .mediaConnected : .mediaDisconnected)
        }
    }

    func didReceiveLocalStream(_ stringeeCall: StringeeCall!) {
        SampleLog.call("local stream StringeeCall id=\(id)")
        DispatchQueue.main.async { [weak self] in
            self?.onLocalVideoView?(stringeeCall.localVideoView)
        }
    }

    func didReceiveRemoteStream(_ stringeeCall: StringeeCall!) {
        SampleLog.call("remote stream StringeeCall id=\(id)")
        DispatchQueue.main.async { [weak self] in
            self?.onRemoteVideoView?(stringeeCall.remoteVideoView)
        }
    }

    func didHandle(onAnotherDevice stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        SampleLog.call("handled on another device StringeeCall id=\(id) state=\(signalingState) reason=\(reason ?? "") sipCode=\(sipCode) sipReason=\(sipReason ?? "")")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(.ended(reason: reason ?? "Handled on another device"))
        }
    }

    fileprivate static func map(signalingState: SignalingState, reason: String?) -> CallSessionState {
        switch signalingState {
        case .calling:
            return .calling
        case .ringing:
            return .ringing
        case .answered:
            return .answered
        case .busy:
            return .ended(reason: reason ?? "Busy")
        case .ended:
            return .ended(reason: reason ?? "Call ended")
        @unknown default:
            return .ended(reason: reason ?? "Call ended")
        }
    }
}

private final class StringeeCall2Session: NSObject, CallSessionProtocol {
    let id: String
    let kind: CallKind = .video
    let direction: CallDirection
    let remoteUserId: String
    let displayName: String
    let implementationKind: CallImplementationKind = .stringeeCall2
    var onStateChange: ((CallSessionState) -> Void)?
    var onLocalVideoView: ((UIView) -> Void)?
    var onRemoteVideoView: ((UIView) -> Void)?

    private let call: StringeeCall2

    init(call: StringeeCall2!, direction: CallDirection) {
        self.call = call
        self.id = call.callId ?? UUID().uuidString
        self.direction = direction
        self.remoteUserId = direction == .incoming ? (call.from ?? "") : (call.to ?? "")
        self.displayName = call.fromAlias?.isEmpty == false ? call.fromAlias : self.remoteUserId
        super.init()
        self.call.delegate = self
        self.call.isVideoCall = true
        if direction == .incoming {
            SampleLog.call("init answer StringeeCall2 id=\(id)")
            self.call.initAnswer()
        }
    }

    func start() {
        SampleLog.call("start StringeeCall2 \(logDescription)")
        call.make { [weak self] status, _, message, _ in
            SampleLog.call("make callback StringeeCall2 id=\(self?.id ?? "") status=\(status) message=\(message ?? "")")
            guard !status else { return }
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call failed"))
            }
        }
    }

    func answer() {
        SampleLog.call("answer requested StringeeCall2 \(logDescription)")
        call.answer { [weak self] status, _, message in
            SampleLog.call("answer callback StringeeCall2 id=\(self?.id ?? "") status=\(status) message=\(message ?? "")")
            guard !status else { return }
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Answer failed"))
            }
        }
    }

    func reject() {
        SampleLog.call("reject requested StringeeCall2 \(logDescription)")
        call.reject { [weak self] _, _, message in
            SampleLog.call("reject callback StringeeCall2 id=\(self?.id ?? "") message=\(message ?? "")")
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call rejected"))
            }
        }
    }

    func hangup() {
        SampleLog.call("hangup requested StringeeCall2 \(logDescription)")
        call.hangup { [weak self] _, _, message in
            SampleLog.call("hangup callback StringeeCall2 id=\(self?.id ?? "") message=\(message ?? "")")
            DispatchQueue.main.async {
                self?.onStateChange?(.ended(reason: message ?? "Call ended"))
            }
        }
    }

    func setMuted(_ isMuted: Bool) {
        SampleLog.call("setMuted StringeeCall2 id=\(id) isMuted=\(isMuted)")
        call.mute(isMuted)
    }

    func setSpeakerEnabled(_ isEnabled: Bool) {
        SampleLog.call("setSpeakerEnabled StringeeCall2 id=\(id) isEnabled=\(isEnabled)")
        StringeeAudioManager.instance()?.setLoudspeaker(isEnabled)
    }

    func setCameraEnabled(_ isEnabled: Bool) {
        SampleLog.call("setCameraEnabled StringeeCall2 id=\(id) isEnabled=\(isEnabled)")
        _ = call.enableLocalVideo(isEnabled)
    }
}

extension StringeeCall2Session: StringeeCall2Delegate {
    func didChangeSignalingState2(_ stringeeCall2: StringeeCall2!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        SampleLog.call("signaling StringeeCall2 id=\(id) state=\(signalingState) reason=\(reason ?? "") sipCode=\(sipCode) sipReason=\(sipReason ?? "")")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(StringeeCallSession.map(signalingState: signalingState, reason: reason))
        }
    }

    func didChangeMediaState2(_ stringeeCall2: StringeeCall2!, mediaState: MediaState) {
        SampleLog.call("media StringeeCall2 id=\(id) state=\(mediaState)")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(mediaState == .connected ? .mediaConnected : .mediaDisconnected)
        }
    }

    func didReceiveLocalStream2(_ stringeeCall2: StringeeCall2!) {
        SampleLog.call("local stream StringeeCall2 id=\(id)")
        DispatchQueue.main.async { [weak self] in
            self?.onLocalVideoView?(stringeeCall2.localVideoView)
        }
    }

    func didReceiveRemoteStream2(_ stringeeCall2: StringeeCall2!) {
        SampleLog.call("remote stream StringeeCall2 id=\(id)")
        DispatchQueue.main.async { [weak self] in
            self?.onRemoteVideoView?(stringeeCall2.remoteVideoView)
        }
    }

    func didHandle(onAnotherDevice2 stringeeCall2: StringeeCall2!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        SampleLog.call("handled on another device StringeeCall2 id=\(id) state=\(signalingState) reason=\(reason ?? "") sipCode=\(sipCode) sipReason=\(sipReason ?? "")")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(.ended(reason: reason ?? "Handled on another device"))
        }
    }
}
#endif
