import Testing
import UIKit
@testable import StringeeCallSample

@MainActor
struct HomeViewModelTests {
    @Test func connectUsesEnteredTokenAndPublishesConnectedUser() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)

        viewModel.accessToken = "token-user-a"
        viewModel.connectTapped()
        service.emitConnection(.connected(userId: "user-a"))

        #expect(service.connectedToken == "token-user-a")
        #expect(viewModel.connectionStatusText == "Connected as user-a")
        #expect(viewModel.isConnected)
    }

    @Test func disconnectClearsConnectedState() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)

        service.emitConnection(.connected(userId: "user-a"))
        viewModel.disconnectTapped()

        #expect(service.disconnectCallCount == 1)
        #expect(viewModel.connectionStatusText == "Disconnected")
        #expect(!viewModel.isConnected)
    }

    @Test func requestNewTokenReconnectsWithCurrentToken() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)

        viewModel.accessToken = "fresh-token"
        service.emitConnection(.tokenExpired)

        #expect(service.connectedToken == "fresh-token")
    }

    @Test func outgoingVoiceCreatesStringeeCallSession() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)
        var presentedSession: CallSessionProtocol?
        viewModel.onPresentCall = { presentedSession = $0 }

        viewModel.calleeId = "user-b"
        viewModel.selectedCallKind = .voice
        viewModel.startCallTapped()

        #expect(service.createdSessions.last?.kind == .voice)
        #expect(service.createdSessions.last?.implementationKind == .stringeeCall)
        #expect(presentedSession?.remoteUserId == "user-b")
    }

    @Test func outgoingVideoCreatesStringeeCall2Session() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)
        var presentedSession: CallSessionProtocol?
        viewModel.onPresentCall = { presentedSession = $0 }

        viewModel.calleeId = "user-b"
        viewModel.selectedCallKind = .video
        viewModel.startCallTapped()

        #expect(service.createdSessions.last?.kind == .video)
        #expect(service.createdSessions.last?.implementationKind == .stringeeCall2)
        #expect(presentedSession?.remoteUserId == "user-b")
    }

    @Test func incomingCallPresentsWhenIdle() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)
        let incoming = FakeCallSession(kind: .voice, direction: .incoming, remoteUserId: "user-b")
        var presentedSession: CallSessionProtocol?
        viewModel.onPresentCall = { presentedSession = $0 }

        viewModel.handleIncomingCall(incoming)

        #expect(presentedSession?.remoteUserId == "user-b")
        #expect(incoming.rejectCallCount == 0)
    }

    @Test func incomingCallRejectsWhenAnotherCallIsActive() {
        let service = FakeStringeeClientService()
        let viewModel = HomeViewModel(clientService: service)
        let active = FakeCallSession(kind: .voice, direction: .outgoing, remoteUserId: "user-b")
        let incoming = FakeCallSession(kind: .video, direction: .incoming, remoteUserId: "user-c")

        viewModel.calleeId = "user-b"
        viewModel.onPresentCall = { _ in }
        service.nextSession = active
        viewModel.startCallTapped()
        viewModel.handleIncomingCall(incoming)

        #expect(incoming.rejectCallCount == 1)
    }
}

@MainActor
struct CallViewModelTests {
    @Test func answerRejectAndHangupDelegateToSession() {
        let session = FakeCallSession(kind: .voice, direction: .incoming, remoteUserId: "user-b")
        let viewModel = CallViewModel(session: session, clock: ManualClock())

        viewModel.answerTapped()
        viewModel.rejectTapped()
        viewModel.endTapped()

        #expect(session.answerCallCount == 1)
        #expect(session.rejectCallCount == 1)
        #expect(session.hangupCallCount == 1)
    }

    @Test func togglesMuteSpeakerAndCameraState() {
        let session = FakeCallSession(kind: .video, direction: .outgoing, remoteUserId: "user-b")
        let viewModel = CallViewModel(session: session, clock: ManualClock())

        viewModel.muteTapped()
        viewModel.speakerTapped()
        viewModel.cameraTapped()

        #expect(viewModel.isMuted)
        #expect(viewModel.isSpeakerEnabled)
        #expect(!viewModel.isCameraEnabled)
        #expect(session.muteValues == [true])
        #expect(session.speakerValues == [true])
        #expect(session.cameraValues == [false])
    }

    @Test func startsDurationWhenMediaConnects() {
        let clock = ManualClock()
        let session = FakeCallSession(kind: .voice, direction: .outgoing, remoteUserId: "user-b")
        let viewModel = CallViewModel(session: session, clock: clock)

        session.emitState(.answered)
        session.emitState(.mediaConnected)
        clock.advance(seconds: 65)

        #expect(viewModel.statusText == "01:05")
    }

    @Test func mapsEndedStateToDismissCallback() {
        let session = FakeCallSession(kind: .voice, direction: .outgoing, remoteUserId: "user-b")
        let viewModel = CallViewModel(session: session, clock: ManualClock())
        var didRequestDismiss = false
        viewModel.onDismiss = { didRequestDismiss = true }

        session.emitState(.ended(reason: "Call ended"))

        #expect(viewModel.statusText == "Call ended")
        #expect(didRequestDismiss)
    }
}

@MainActor
struct DurationFormatterTests {
    @Test func formatsMinutesAndHours() {
        #expect(CallDurationFormatter.string(from: 65) == "01:05")
        #expect(CallDurationFormatter.string(from: 3_661) == "01:01:01")
    }
}

@MainActor
struct StringeePushPayloadTests {
    @Test func parsesStartedCallEventPayload() throws {
        let payload = StringeePushPayload(dictionary: validPushPayload(callId: "call-1", serial: 7))

        let unwrapped = try #require(payload)
        #expect(unwrapped.callId == "call-1")
        #expect(unwrapped.serial == 7)
        #expect(unwrapped.callerName == "Caller A")
        #expect(unwrapped.callerNumber == "user-a")
        #expect(unwrapped.kind == .voice)
    }

    @Test func rejectsNonCallEventPayload() {
        let payload = StringeePushPayload(dictionary: [
            "data": [
                "map": [
                    "type": "CUSTOM_EVENT",
                    "data": ["map": ["callStatus": "started", "callId": "call-1"]]
                ]
            ]
        ])

        #expect(payload == nil)
    }
}

@MainActor
struct VoIPPushConfigurationTests {
    @Test func debugUsesSandboxPushRegistration() {
        #if DEBUG
        #expect(VoIPPushEnvironment.currentIsProduction == false)
        #endif
    }
}

@MainActor
struct CallCoordinatorTests {
    @Test func incomingPushReportsCallKitAndCallsCompletion() {
        let service = FakeStringeeClientService()
        let callKit = FakeCallKitService()
        let tokenStore = InMemoryAccessTokenStore()
        tokenStore.saveAccessToken("token-user-a")
        let scheduler = ManualCallTimeoutScheduler()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: tokenStore,
            timeoutScheduler: scheduler
        )
        var completionCount = 0

        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2)) {
            completionCount += 1
        }

        #expect(callKit.reportedIncomingCallIds == ["call-1"])
        #expect(completionCount == 1)
        #expect(service.connectedToken == "token-user-a")
    }

    @Test func matchingIncomingCallAttachesToPendingPushRecordAndPresents() {
        let service = FakeStringeeClientService()
        let callKit = FakeCallKitService()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: InMemoryAccessTokenStore(),
            timeoutScheduler: ManualCallTimeoutScheduler()
        )
        let session = FakeCallSession(id: "call-1", kind: .voice, direction: .incoming, remoteUserId: "user-a")
        var presented: CallSessionProtocol?
        coordinator.onPresentCall = { presented = $0 }

        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2), completion: {})
        service.emitIncoming(session)

        #expect(presented?.id == "call-1")
        #expect(session.rejectCallCount == 0)
        #expect(callKit.reportedIncomingCallIds == ["call-1"])
    }

    @Test func incomingSessionBeforeUIPresenterIsPresentedWhenPresenterAttaches() {
        let service = FakeStringeeClientService()
        let callKit = FakeCallKitService()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: InMemoryAccessTokenStore(),
            timeoutScheduler: ManualCallTimeoutScheduler()
        )
        let session = FakeCallSession(id: "call-1", kind: .voice, direction: .incoming, remoteUserId: "user-a")
        var presented: CallSessionProtocol?

        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2), completion: {})
        service.emitIncoming(session)
        #expect(presented == nil)

        coordinator.onPresentCall = { presented = $0 }

        #expect(presented?.id == "call-1")
    }

    @Test func callKitAnswerWaitsForMatchingSession() {
        let service = FakeStringeeClientService()
        let callKit = FakeCallKitService()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: InMemoryAccessTokenStore(),
            timeoutScheduler: ManualCallTimeoutScheduler()
        )
        let session = FakeCallSession(id: "call-1", kind: .voice, direction: .incoming, remoteUserId: "user-a")

        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2), completion: {})
        let uuid = tryUnwrap(callKit.reportedIncomingUUIDs.last)
        callKit.emitAction(.answer(uuid))
        #expect(session.answerCallCount == 0)

        service.emitIncoming(session)

        #expect(session.answerCallCount == 1)
    }

    @Test func endActionRejectsUnansweredIncomingAndHangsUpAnsweredCall() {
        let service = FakeStringeeClientService()
        let callKit = FakeCallKitService()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: InMemoryAccessTokenStore(),
            timeoutScheduler: ManualCallTimeoutScheduler()
        )
        let session = FakeCallSession(id: "call-1", kind: .voice, direction: .incoming, remoteUserId: "user-a")

        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2), completion: {})
        service.emitIncoming(session)
        let uuid = tryUnwrap(callKit.reportedIncomingUUIDs.last)
        callKit.emitAction(.end(uuid))
        #expect(session.rejectCallCount == 1)

        coordinator.handleIncomingPush(validPushPayload(callId: "call-2", serial: 3), completion: {})
        let answered = FakeCallSession(id: "call-2", kind: .voice, direction: .incoming, remoteUserId: "user-b")
        service.emitIncoming(answered)
        let answeredUUID = tryUnwrap(callKit.reportedIncomingUUIDs.last)
        callKit.emitAction(.answer(answeredUUID))
        callKit.emitAction(.end(answeredUUID))

        #expect(answered.answerCallCount == 1)
        #expect(answered.hangupCallCount == 1)
    }

    @Test func timeoutEndsStaleCallKitWhenIncomingCallDoesNotExist() {
        let service = FakeStringeeClientService()
        service.incomingCallExists = false
        let callKit = FakeCallKitService()
        let scheduler = ManualCallTimeoutScheduler()
        let coordinator = CallCoordinator(
            clientService: service,
            callKitService: callKit,
            tokenStore: InMemoryAccessTokenStore(),
            timeoutScheduler: scheduler
        )
        coordinator.handleIncomingPush(validPushPayload(callId: "call-1", serial: 2), completion: {})
        scheduler.fire()

        #expect(service.checkedIncomingCallIds == ["call-1"])
        #expect(callKit.endedUUIDs.count == 1)
    }
}

@MainActor
private func validPushPayload(callId: String, serial: Int, isVideo: Bool = false) -> [AnyHashable: Any] {
    [
        "data": [
            "map": [
                "type": "CALL_EVENT",
                "data": [
                    "map": [
                        "callStatus": "started",
                        "callId": callId,
                        "serial": serial,
                        "isVideoCall": isVideo,
                        "from": [
                            "map": [
                                "alias": "Caller A",
                                "number": "user-a"
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
}

private func tryUnwrap<T>(_ value: T?, sourceLocation: SourceLocation = #_sourceLocation) -> T {
    guard let value else {
        Issue.record("Expected non-nil value", sourceLocation: sourceLocation)
        fatalError("Expected non-nil value")
    }
    return value
}

@MainActor
private final class FakeStringeeClientService: StringeeClientServiceProtocol {
    var onConnectionStateChange: ((StringeeConnectionState) -> Void)?
    var onIncomingCall: ((CallSessionProtocol) -> Void)?
    private(set) var currentConnectionState: StringeeConnectionState = .disconnected

    var connectedToken: String?
    var disconnectCallCount = 0
    var registeredVoIPTokens: [(token: String, isProduction: Bool)] = []
    var unregisteredVoIPTokens: [String] = []
    var checkedIncomingCallIds: [String] = []
    var incomingCallExists = true
    var nextSession: FakeCallSession?
    var createdSessions: [FakeCallSession] = []

    func connect(accessToken: String) {
        connectedToken = accessToken
    }

    func disconnect() {
        disconnectCallCount += 1
        emitConnection(.disconnected)
    }

    func makeCall(to calleeId: String, kind: CallKind) -> CallSessionProtocol {
        let session = nextSession ?? FakeCallSession(
            kind: kind,
            direction: .outgoing,
            remoteUserId: calleeId,
            implementationKind: kind == .voice ? .stringeeCall : .stringeeCall2
        )
        createdSessions.append(session)
        return session
    }

    func registerVoIPPushToken(_ token: String, isProduction: Bool) {
        registeredVoIPTokens.append((token, isProduction))
    }

    func unregisterVoIPPushToken(_ token: String) {
        unregisteredVoIPTokens.append(token)
    }

    func checkIncomingCallExists(callId: String, completion: @escaping (Bool) -> Void) {
        checkedIncomingCallIds.append(callId)
        completion(incomingCallExists)
    }

    func emitConnection(_ state: StringeeConnectionState) {
        currentConnectionState = state
        onConnectionStateChange?(state)
    }

    func emitIncoming(_ session: CallSessionProtocol) {
        onIncomingCall?(session)
    }
}

@MainActor
private final class FakeCallSession: CallSessionProtocol {
    let id: String
    let kind: CallKind
    let direction: CallDirection
    let remoteUserId: String
    let displayName: String
    let implementationKind: CallImplementationKind
    var onStateChange: ((CallSessionState) -> Void)?
    var onLocalVideoView: ((UIView) -> Void)?
    var onRemoteVideoView: ((UIView) -> Void)?

    var startCallCount = 0
    var answerCallCount = 0
    var rejectCallCount = 0
    var hangupCallCount = 0
    var muteValues: [Bool] = []
    var speakerValues: [Bool] = []
    var cameraValues: [Bool] = []

    init(
        id: String = UUID().uuidString,
        kind: CallKind,
        direction: CallDirection,
        remoteUserId: String,
        displayName: String? = nil,
        implementationKind: CallImplementationKind = .fake
    ) {
        self.id = id
        self.kind = kind
        self.direction = direction
        self.remoteUserId = remoteUserId
        self.displayName = displayName ?? remoteUserId
        self.implementationKind = implementationKind
    }

    func start() { startCallCount += 1 }
    func answer() { answerCallCount += 1 }
    func reject() { rejectCallCount += 1 }
    func hangup() { hangupCallCount += 1 }
    func setMuted(_ isMuted: Bool) { muteValues.append(isMuted) }
    func setSpeakerEnabled(_ isEnabled: Bool) { speakerValues.append(isEnabled) }
    func setCameraEnabled(_ isEnabled: Bool) { cameraValues.append(isEnabled) }

    func emitState(_ state: CallSessionState) {
        onStateChange?(state)
    }
}

@MainActor
private final class ManualClock: CallClock {
    var onTick: ((Int) -> Void)?
    private(set) var elapsedSeconds = 0

    func start(onTick: @escaping (Int) -> Void) {
        self.onTick = onTick
    }

    func stop() {
        onTick = nil
    }

    func advance(seconds: Int) {
        elapsedSeconds += seconds
        onTick?(elapsedSeconds)
    }
}
