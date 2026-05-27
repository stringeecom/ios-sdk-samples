import AVFoundation
import CallKit
import Foundation

enum CallKitActionEvent: Equatable {
    case start(UUID)
    case answer(UUID)
    case end(UUID)
    case mute(UUID, Bool)
}

struct ManagedCallRecord: Equatable {
    let uuid: UUID
    let callId: String
    let serial: Int
    let callerName: String
    let callerNumber: String
    let kind: CallKind
    let direction: CallDirection
}

protocol CallKitServiceProtocol: AnyObject {
    var onAction: ((CallKitActionEvent) -> Void)? { get set }

    func reportIncomingCall(_ record: ManagedCallRecord, completion: @escaping (Bool) -> Void)
    func reportFakeIncomingCall(completion: @escaping () -> Void)
    func startOutgoingCall(_ record: ManagedCallRecord)
    func reportOutgoingConnected(uuid: UUID)
    func endCall(uuid: UUID)
    func updateCall(_ record: ManagedCallRecord)
}

final class CallKitService: NSObject, CallKitServiceProtocol {
    var onAction: ((CallKitActionEvent) -> Void)?

    private let provider: CXProvider
    private let callController = CXCallController()

    override init() {
        let configuration = CXProviderConfiguration(localizedName: "Stringee")
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic, .phoneNumber]
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = true
        }
        self.provider = CXProvider(configuration: configuration)
        super.init()
        provider.setDelegate(self, queue: .main)
    }

    func reportIncomingCall(_ record: ManagedCallRecord, completion: @escaping (Bool) -> Void) {
        let update = CXCallUpdate()
        update.hasVideo = record.kind == .video
        update.localizedCallerName = record.callerName
        update.remoteHandle = CXHandle(type: .generic, value: record.callerNumber)
        SampleLog.call("CallKit report incoming callId=\(record.callId) uuid=\(record.uuid)")
        provider.reportNewIncomingCall(with: record.uuid, update: update) { error in
            if let error {
                SampleLog.call("CallKit report incoming failed callId=\(record.callId) error=\(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }

    func reportFakeIncomingCall(completion: @escaping () -> Void) {
        let uuid = UUID()
        let update = CXCallUpdate()
        update.hasVideo = false
        update.localizedCallerName = "Expired Call"
        SampleLog.call("CallKit report fake incoming uuid=\(uuid)")
        provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] _ in
            DispatchQueue.main.async {
                self?.endCall(uuid: uuid)
                completion()
            }
        }
    }

    func startOutgoingCall(_ record: ManagedCallRecord) {
        let handle = CXHandle(type: .generic, value: record.callerNumber)
        let action = CXStartCallAction(call: record.uuid, handle: handle)
        action.isVideo = record.kind == .video
        callController.request(CXTransaction(action: action)) { error in
            if let error {
                SampleLog.call("CallKit start outgoing failed callId=\(record.callId) error=\(error.localizedDescription)")
            }
        }
    }

    func reportOutgoingConnected(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }

    func endCall(uuid: UUID) {
        let action = CXEndCallAction(call: uuid)
        callController.request(CXTransaction(action: action)) { error in
            if let error {
                SampleLog.call("CallKit end failed uuid=\(uuid) error=\(error.localizedDescription)")
            }
        }
    }

    func updateCall(_ record: ManagedCallRecord) {
        let update = CXCallUpdate()
        update.hasVideo = record.kind == .video
        update.localizedCallerName = record.callerName
        update.remoteHandle = CXHandle(type: .generic, value: record.callerNumber)
        provider.reportCall(with: record.uuid, updated: update)
    }
}

extension CallKitService: CXProviderDelegate {
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        SampleLog.call("CallKit action start uuid=\(action.callUUID)")
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        onAction?(.start(action.callUUID))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        SampleLog.call("CallKit action answer uuid=\(action.callUUID)")
        onAction?(.answer(action.callUUID))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        SampleLog.call("CallKit action end uuid=\(action.callUUID)")
        onAction?(.end(action.callUUID))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        SampleLog.call("CallKit action mute uuid=\(action.callUUID) isMuted=\(action.isMuted)")
        onAction?(.mute(action.callUUID, action.isMuted))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        SampleLog.call("CallKit didActivate audio session")
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        SampleLog.call("CallKit didDeactivate audio session")
    }

    func providerDidReset(_ provider: CXProvider) {
        SampleLog.call("CallKit providerDidReset")
    }
}

@MainActor
final class FakeCallKitService: CallKitServiceProtocol {
    var onAction: ((CallKitActionEvent) -> Void)?

    private(set) var reportedIncomingCallIds: [String] = []
    private(set) var reportedIncomingUUIDs: [UUID] = []
    private(set) var fakeIncomingCount = 0
    var endedUUIDs: [UUID] = []
    private(set) var outgoingUUIDs: [UUID] = []
    private(set) var mutedEvents: [(UUID, Bool)] = []

    func reportIncomingCall(_ record: ManagedCallRecord, completion: @escaping (Bool) -> Void) {
        reportedIncomingCallIds.append(record.callId)
        reportedIncomingUUIDs.append(record.uuid)
        completion(true)
    }

    func reportFakeIncomingCall(completion: @escaping () -> Void) {
        fakeIncomingCount += 1
        completion()
    }

    func startOutgoingCall(_ record: ManagedCallRecord) {
        outgoingUUIDs.append(record.uuid)
    }

    func reportOutgoingConnected(uuid: UUID) {}

    func endCall(uuid: UUID) {
        endedUUIDs.append(uuid)
    }

    func updateCall(_ record: ManagedCallRecord) {}

    func emitAction(_ action: CallKitActionEvent) {
        if case let .mute(uuid, isMuted) = action {
            mutedEvents.append((uuid, isMuted))
        }
        onAction?(action)
    }
}
