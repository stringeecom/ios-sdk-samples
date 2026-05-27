import Foundation
import UIKit

@MainActor
final class CallViewModel {
    struct Actions {
        var answer: (CallSessionProtocol) -> Void = { $0.answer() }
        var reject: (CallSessionProtocol) -> Void = { $0.reject() }
        var hangup: (CallSessionProtocol) -> Void = { $0.hangup() }
        var mute: (Bool, CallSessionProtocol) -> Void = { isMuted, session in session.setMuted(isMuted) }
        var speaker: (Bool, CallSessionProtocol) -> Void = { isEnabled, session in session.setSpeakerEnabled(isEnabled) }
        var camera: (Bool, CallSessionProtocol) -> Void = { isEnabled, session in session.setCameraEnabled(isEnabled) }
    }

    var onChange: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onLocalVideoView: ((UIView) -> Void)?
    var onRemoteVideoView: ((UIView) -> Void)?

    let session: CallSessionProtocol

    private let actions: Actions
    private let clock: CallClock
    private(set) var statusText: String {
        didSet { onChange?() }
    }
    private(set) var isMuted = false {
        didSet { onChange?() }
    }
    private(set) var isSpeakerEnabled = false {
        didSet { onChange?() }
    }
    private(set) var isCameraEnabled = true {
        didSet { onChange?() }
    }
    private(set) var isAnswered = false {
        didSet { onChange?() }
    }

    convenience init(session: CallSessionProtocol, clock: CallClock? = nil) {
        self.init(session: session, clock: clock, actions: Actions())
    }

    init(session: CallSessionProtocol, clock: CallClock? = nil, actions: Actions) {
        self.session = session
        self.actions = actions
        self.clock = clock ?? TimerCallClock()
        self.statusText = session.direction == .incoming
            ? "Incoming call from \(session.displayName)"
            : "Calling \(session.displayName)"
        SampleLog.call("CallViewModel init \(session.logDescription)")
        bindSession()
    }

    var titleText: String {
        session.displayName
    }

    var isIncoming: Bool {
        session.direction == .incoming
    }

    var isVideoCall: Bool {
        session.kind == .video
    }

    var shouldShowAnswerControls: Bool {
        isIncoming && !isAnswered
    }

    func answerTapped() {
        SampleLog.call("answer tapped \(session.logDescription)")
        actions.answer(session)
        isAnswered = true
        statusText = "Connecting..."
    }

    func rejectTapped() {
        SampleLog.call("reject tapped \(session.logDescription)")
        actions.reject(session)
        statusText = "Call rejected"
        SampleLog.call("dismiss requested after reject \(session.logDescription)")
        onDismiss?()
    }

    func endTapped() {
        SampleLog.call("end tapped \(session.logDescription)")
        actions.hangup(session)
        statusText = "Call ended"
        SampleLog.call("dismiss requested after end \(session.logDescription)")
        onDismiss?()
    }

    func muteTapped() {
        isMuted.toggle()
        actions.mute(isMuted, session)
    }

    func speakerTapped() {
        isSpeakerEnabled.toggle()
        actions.speaker(isSpeakerEnabled, session)
    }

    func cameraTapped() {
        guard isVideoCall else { return }
        isCameraEnabled.toggle()
        actions.camera(isCameraEnabled, session)
    }

    private func bindSession() {
        session.onStateChange = { [weak self] state in
            guard let self else { return }
            self.handleState(state)
        }
        session.onLocalVideoView = { [weak self] view in
            self?.onLocalVideoView?(view)
        }
        session.onRemoteVideoView = { [weak self] view in
            self?.onRemoteVideoView?(view)
        }
    }

    private func handleState(_ state: CallSessionState) {
        SampleLog.call("view model state \(session.logDescription) state=\(state.logDescription)")
        switch state {
        case .calling:
            statusText = "Calling \(session.displayName)"
        case .ringing:
            statusText = "Ringing..."
        case .answered:
            isAnswered = true
            statusText = "Answered"
        case .mediaConnected:
            isAnswered = true
            clock.start { [weak self] elapsedSeconds in
                self?.statusText = CallDurationFormatter.string(from: elapsedSeconds)
            }
        case .mediaDisconnected:
            clock.stop()
            statusText = "Reconnecting media..."
        case .ended(let reason):
            clock.stop()
            statusText = reason
            SampleLog.call("dismiss requested after ended state \(session.logDescription) reason=\(reason)")
            onDismiss?()
        }
    }
}
