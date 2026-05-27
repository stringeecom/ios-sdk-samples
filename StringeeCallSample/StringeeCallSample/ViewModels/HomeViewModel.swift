import Foundation

@MainActor
final class HomeViewModel {
    var onChange: (() -> Void)?
    var onPresentCall: ((CallSessionProtocol) -> Void)?
    var onConnectionStateObserved: ((StringeeConnectionState) -> Void)?

    var accessToken = ""
    var calleeId = ""
    var selectedCallKind: CallKind = .voice {
        didSet { onChange?() }
    }

    private let clientService: StringeeClientServiceProtocol
    private var activeSession: CallSessionProtocol?
    private(set) var connectionState: StringeeConnectionState = .disconnected {
        didSet { onChange?() }
    }

    init(clientService: StringeeClientServiceProtocol) {
        self.clientService = clientService
        bindService()
    }

    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }

    var canStartCall: Bool {
        isConnected && !calleeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && activeSession == nil
    }

    var connectionStatusText: String {
        switch connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected(let userId):
            return "Connected as \(userId)"
        case .reconnecting:
            return "Reconnecting..."
        case .failed(let message):
            return "Connection failed: \(message)"
        case .tokenExpired:
            return "Token expired"
        }
    }

    func connectTapped() {
        let token = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            connectionState = .failed(message: "Access token is required")
            return
        }
        connectionState = .connecting
        clientService.connect(accessToken: token)
    }

    func disconnectTapped() {
        clientService.disconnect()
        connectionState = .disconnected
    }

    func startCallTapped() {
        let trimmedCalleeId = calleeId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCalleeId.isEmpty, activeSession == nil else { return }

        let session = clientService.makeCall(to: trimmedCalleeId, kind: selectedCallKind)
        present(session)
        session.start()
    }

    func trackExternalCall(_ session: CallSessionProtocol) {
        guard activeSession == nil || activeSession === session else { return }
        activeSession = session
        onChange?()
    }

    func clearActiveCall(_ session: CallSessionProtocol) {
        guard activeSession === session else { return }
        SampleLog.call("clear active call \(session.logDescription)")
        activeSession = nil
        onChange?()
    }

    private func bindService() {
        clientService.onConnectionStateChange = { [weak self] state in
            guard let self else { return }
            self.handleConnectionState(state)
        }

    }

    func handleConnectionState(_ state: StringeeConnectionState) {
        connectionState = state
        onConnectionStateObserved?(state)
        if case .tokenExpired = state {
            let token = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { return }
            clientService.connect(accessToken: token)
        }
    }

    func handleIncomingCall(_ session: CallSessionProtocol) {
        SampleLog.call("home received incoming \(session.logDescription) hasActiveCall=\(activeSession != nil)")
        guard activeSession == nil else {
            SampleLog.call("reject incoming because another call is active \(session.logDescription)")
            session.reject()
            return
        }
        present(session)
    }

    private func present(_ session: CallSessionProtocol) {
        SampleLog.call("home present session \(session.logDescription)")
        activeSession = session
        onPresentCall?(session)
        onChange?()
    }
}
