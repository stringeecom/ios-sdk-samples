import Foundation

@MainActor
protocol CallCoordinating: AnyObject {
    var onPresentCall: ((CallSessionProtocol) -> Void)? { get set }
    var onPushStatusChange: ((String) -> Void)? { get set }

    func handleIncomingPush(_ dictionary: [AnyHashable: Any], completion: @escaping () -> Void)
    func handleConnectionState(_ state: StringeeConnectionState)
    func handleVoIPToken(_ token: String)
    func startOutgoingCall(_ session: CallSessionProtocol)
    func answer(_ session: CallSessionProtocol)
    func reject(_ session: CallSessionProtocol)
    func hangup(_ session: CallSessionProtocol)
    func setMuted(_ isMuted: Bool, for session: CallSessionProtocol)
    func clearCall(_ session: CallSessionProtocol)
}

@MainActor
final class CallCoordinator: CallCoordinating {
    var onPresentCall: ((CallSessionProtocol) -> Void)? {
        didSet {
            guard let pendingSessionForPresentation else { return }
            self.pendingSessionForPresentation = nil
            onPresentCall?(pendingSessionForPresentation)
        }
    }
    var onPushStatusChange: ((String) -> Void)?

    private struct ActiveCall {
        var record: ManagedCallRecord
        var session: CallSessionProtocol?
        var isAnswered = false
        var answerRequested = false
    }

    private let clientService: StringeeClientServiceProtocol
    private let callKitService: CallKitServiceProtocol
    private let tokenStore: AccessTokenStoreProtocol
    private let timeoutScheduler: CallTimeoutScheduling

    private var activeCall: ActiveCall?
    private var trackedIncomingKeys = Set<String>()
    private var voipToken: String?
    private var pendingSessionForPresentation: CallSessionProtocol?

    convenience init(
        clientService: StringeeClientServiceProtocol,
        callKitService: CallKitServiceProtocol,
        tokenStore: AccessTokenStoreProtocol
    ) {
        self.init(
            clientService: clientService,
            callKitService: callKitService,
            tokenStore: tokenStore,
            timeoutScheduler: CallTimeoutScheduler()
        )
    }

    init(
        clientService: StringeeClientServiceProtocol,
        callKitService: CallKitServiceProtocol,
        tokenStore: AccessTokenStoreProtocol,
        timeoutScheduler: CallTimeoutScheduling
    ) {
        self.clientService = clientService
        self.callKitService = callKitService
        self.tokenStore = tokenStore
        self.timeoutScheduler = timeoutScheduler
        bind()
    }

    func handleIncomingPush(_ dictionary: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let payload = StringeePushPayload(dictionary: dictionary) else {
            SampleLog.call("VoIP push ignored because payload is not a started Stringee call")
            callKitService.reportFakeIncomingCall(completion: completion)
            return
        }

        let key = trackingKey(callId: payload.callId, serial: payload.serial)
        guard activeCall == nil, !trackedIncomingKeys.contains(key) else {
            SampleLog.call("VoIP push ignored because call is duplicate or another call is active callId=\(payload.callId)")
            callKitService.reportFakeIncomingCall(completion: completion)
            return
        }

        trackedIncomingKeys.insert(key)
        let record = ManagedCallRecord(
            uuid: UUID(),
            callId: payload.callId,
            serial: payload.serial,
            callerName: payload.callerName,
            callerNumber: payload.callerNumber,
            kind: payload.kind,
            direction: .incoming
        )
        activeCall = ActiveCall(record: record)

        callKitService.reportIncomingCall(record) { [weak self] status in
            guard let self else { return }
            if !status {
                self.clearActiveRecord()
            }
            completion()
        }

        reconnectForPushIfNeeded()
        schedulePendingIncomingTimeout(callId: payload.callId)
    }

    func handleConnectionState(_ state: StringeeConnectionState) {
        if case .connected = state, let voipToken {
            registerVoIPToken(voipToken)
        }
    }

    func handleVoIPToken(_ token: String) {
        voipToken = token
        onPushStatusChange?("VoIP token received")
        if case .connected = clientService.currentConnectionState {
            registerVoIPToken(token)
        }
    }

    func startOutgoingCall(_ session: CallSessionProtocol) {
        guard activeCall == nil || activeCall?.session === session else { return }
        let record = ManagedCallRecord(
            uuid: UUID(),
            callId: session.id,
            serial: 0,
            callerName: session.displayName,
            callerNumber: session.remoteUserId,
            kind: session.kind,
            direction: .outgoing
        )
        activeCall = ActiveCall(record: record, session: session)
        callKitService.startOutgoingCall(record)
    }

    func answer(_ session: CallSessionProtocol) {
        guard updateActiveSessionIfNeeded(session) else {
            session.answer()
            return
        }
        activeCall?.isAnswered = true
        activeCall?.answerRequested = false
        session.answer()
    }

    func reject(_ session: CallSessionProtocol) {
        session.reject()
        endCallKitIfNeeded(for: session)
        clearCall(session)
    }

    func hangup(_ session: CallSessionProtocol) {
        session.hangup()
        endCallKitIfNeeded(for: session)
        clearCall(session)
    }

    func setMuted(_ isMuted: Bool, for session: CallSessionProtocol) {
        session.setMuted(isMuted)
    }

    func clearCall(_ session: CallSessionProtocol) {
        guard activeCall?.session === session || activeCall?.record.callId == session.id else { return }
        timeoutScheduler.cancel()
        clearActiveRecord()
    }

    private func bind() {
        clientService.onIncomingCall = { [weak self] session in
            guard let self else { return }
            self.handleIncomingSession(session)
        }

        callKitService.onAction = { [weak self] action in
            guard let self else { return }
            self.handleCallKitAction(action)
        }
    }

    private func handleIncomingSession(_ session: CallSessionProtocol) {
        SampleLog.call("coordinator incoming session \(session.logDescription)")
        guard var current = activeCall else {
            reportForegroundIncoming(session)
            return
        }

        guard current.record.callId == session.id else {
            SampleLog.call("coordinator reject incoming because another call is active \(session.logDescription)")
            session.reject()
            trackedIncomingKeys.insert(trackingKey(callId: session.id, serial: 0))
            return
        }

        timeoutScheduler.cancel()
        current.session = session
        activeCall = current
        callKitService.updateCall(current.record)
        present(session)

        if current.answerRequested {
            answer(session)
        }
    }

    private func reportForegroundIncoming(_ session: CallSessionProtocol) {
        let record = ManagedCallRecord(
            uuid: UUID(),
            callId: session.id,
            serial: 0,
            callerName: session.displayName,
            callerNumber: session.remoteUserId,
            kind: session.kind,
            direction: .incoming
        )
        activeCall = ActiveCall(record: record, session: session)
        trackedIncomingKeys.insert(trackingKey(callId: session.id, serial: 0))
        callKitService.reportIncomingCall(record) { [weak self] status in
            guard let self else { return }
            if status {
                self.present(session)
            } else {
                session.reject()
                self.clearActiveRecord()
            }
        }
    }

    private func handleCallKitAction(_ action: CallKitActionEvent) {
        switch action {
        case .start(let uuid):
            guard activeCall?.record.uuid == uuid else { return }
        case .answer(let uuid):
            guard var current = activeCall, current.record.uuid == uuid else { return }
            current.isAnswered = true
            current.answerRequested = true
            activeCall = current
            if let session = current.session {
                answer(session)
            }
        case .end(let uuid):
            guard let current = activeCall, current.record.uuid == uuid else { return }
            timeoutScheduler.cancel()
            if let session = current.session {
                if current.record.direction == .incoming && !current.isAnswered {
                    session.reject()
                } else {
                    session.hangup()
                }
            }
            clearActiveRecord()
        case .mute(let uuid, let isMuted):
            guard let current = activeCall, current.record.uuid == uuid, let session = current.session else { return }
            session.setMuted(isMuted)
        }
    }

    private func schedulePendingIncomingTimeout(callId: String) {
        timeoutScheduler.schedule(after: 15) { [weak self] in
            self?.checkPendingIncomingTimeout(callId: callId)
        }
    }

    private func checkPendingIncomingTimeout(callId: String) {
        guard let current = activeCall, current.record.callId == callId, current.session == nil else { return }
        clientService.checkIncomingCallExists(callId: callId) { [weak self] exists in
            guard let self, let latest = self.activeCall, latest.record.callId == callId, latest.session == nil else { return }
            if !exists {
                SampleLog.call("coordinator end stale CallKit callId=\(callId)")
                self.callKitService.endCall(uuid: latest.record.uuid)
                self.clearActiveRecord()
            }
        }
    }

    private func reconnectForPushIfNeeded() {
        guard case .connected = clientService.currentConnectionState else {
            guard let token = tokenStore.loadAccessToken(), !token.isEmpty else {
                onPushStatusChange?("VoIP push received, but no saved token")
                return
            }
            SampleLog.client("reconnect from VoIP push using saved access token")
            clientService.connect(accessToken: token)
            return
        }
    }

    private func registerVoIPToken(_ token: String) {
        SampleLog.client("register VoIP push token")
        clientService.registerVoIPPushToken(token, isProduction: VoIPPushEnvironment.currentIsProduction)
        onPushStatusChange?("VoIP token registered")
    }

    private func updateActiveSessionIfNeeded(_ session: CallSessionProtocol) -> Bool {
        guard var current = activeCall, current.record.callId == session.id else { return false }
        current.session = session
        activeCall = current
        return true
    }

    private func endCallKitIfNeeded(for session: CallSessionProtocol) {
        guard let current = activeCall, current.record.callId == session.id else { return }
        callKitService.endCall(uuid: current.record.uuid)
    }

    private func clearActiveRecord() {
        activeCall = nil
        pendingSessionForPresentation = nil
    }

    private func trackingKey(callId: String, serial: Int) -> String {
        "\(callId)-\(serial)"
    }

    private func present(_ session: CallSessionProtocol) {
        guard let onPresentCall else {
            pendingSessionForPresentation = session
            return
        }
        onPresentCall(session)
    }
}
