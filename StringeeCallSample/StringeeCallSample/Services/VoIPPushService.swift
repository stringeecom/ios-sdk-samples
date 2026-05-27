import Foundation
import PushKit

protocol VoIPPushServiceProtocol: AnyObject {
    var onTokenUpdate: ((String) -> Void)? { get set }
    var onIncomingPush: (([AnyHashable: Any], @escaping () -> Void) -> Void)? { get set }

    func start()
}

final class VoIPPushService: NSObject, VoIPPushServiceProtocol {
    var onTokenUpdate: ((String) -> Void)?
    var onIncomingPush: (([AnyHashable: Any], @escaping () -> Void) -> Void)?

    private var registry: PKPushRegistry?

    func start() {
        guard registry == nil else { return }
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.registry = registry
    }
}

extension VoIPPushService: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        SampleLog.client("VoIP token updated \(token)")
        onTokenUpdate?(token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        SampleLog.client("VoIP token invalidated")
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }
        SampleLog.call("VoIP push received \(payload.dictionaryPayload)")
        onIncomingPush?(payload.dictionaryPayload, completion)
    }
}

final class DemoVoIPPushService: VoIPPushServiceProtocol {
    var onTokenUpdate: ((String) -> Void)?
    var onIncomingPush: (([AnyHashable: Any], @escaping () -> Void) -> Void)?

    func start() {}
}
