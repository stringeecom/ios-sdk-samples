import Foundation
import UIKit

enum CallKind: Equatable {
    case voice
    case video
}

enum CallDirection: Equatable {
    case incoming
    case outgoing
}

enum CallImplementationKind: Equatable {
    case stringeeCall
    case stringeeCall2
    case fake
}

enum StringeeConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(userId: String)
    case reconnecting
    case failed(message: String)
    case tokenExpired
}

enum CallSessionState: Equatable {
    case calling
    case ringing
    case answered
    case mediaConnected
    case mediaDisconnected
    case ended(reason: String)
}

protocol StringeeClientServiceProtocol: AnyObject {
    var onConnectionStateChange: ((StringeeConnectionState) -> Void)? { get set }
    var onIncomingCall: ((CallSessionProtocol) -> Void)? { get set }
    var currentConnectionState: StringeeConnectionState { get }

    func connect(accessToken: String)
    func disconnect()
    func makeCall(to calleeId: String, kind: CallKind) -> CallSessionProtocol
    func registerVoIPPushToken(_ token: String, isProduction: Bool)
    func unregisterVoIPPushToken(_ token: String)
    func checkIncomingCallExists(callId: String, completion: @escaping (Bool) -> Void)
}

protocol CallSessionProtocol: AnyObject {
    var id: String { get }
    var kind: CallKind { get }
    var direction: CallDirection { get }
    var remoteUserId: String { get }
    var displayName: String { get }
    var implementationKind: CallImplementationKind { get }
    var onStateChange: ((CallSessionState) -> Void)? { get set }
    var onLocalVideoView: ((UIView) -> Void)? { get set }
    var onRemoteVideoView: ((UIView) -> Void)? { get set }

    func start()
    func answer()
    func reject()
    func hangup()
    func setMuted(_ isMuted: Bool)
    func setSpeakerEnabled(_ isEnabled: Bool)
    func setCameraEnabled(_ isEnabled: Bool)
}

protocol CallClock: AnyObject {
    func start(onTick: @escaping (Int) -> Void)
    func stop()
}

enum CallDurationFormatter {
    static func string(from seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

final class TimerCallClock: CallClock {
    private var timer: Timer?
    private var elapsedSeconds = 0

    func start(onTick: @escaping (Int) -> Void) {
        stop()
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            onTick(self.elapsedSeconds)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
