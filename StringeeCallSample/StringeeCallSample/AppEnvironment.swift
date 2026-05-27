import Foundation

@MainActor
enum AppEnvironment {
    static func makeRuntime() -> AppRuntime {
        if CommandLine.arguments.contains("--uitesting-fake-stringee") {
            return AppRuntime(
                clientService: DemoStringeeClientService(),
                callKitService: FakeCallKitService(),
                tokenStore: InMemoryAccessTokenStore(),
                voIPPushService: DemoVoIPPushService()
            )
        }

        #if canImport(Stringee)
        return AppRuntime(
            clientService: StringeeSDKAdapter(),
            callKitService: CallKitService(),
            tokenStore: AccessTokenStore(),
            voIPPushService: VoIPPushService()
        )
        #else
        return AppRuntime(
            clientService: DemoStringeeClientService(),
            callKitService: FakeCallKitService(),
            tokenStore: InMemoryAccessTokenStore(),
            voIPPushService: DemoVoIPPushService()
        )
        #endif
    }
}

@MainActor
final class AppRuntime {
    static let shared = AppEnvironment.makeRuntime()

    let clientService: StringeeClientServiceProtocol
    let tokenStore: AccessTokenStoreProtocol
    let callCoordinator: CallCoordinator
    private let voIPPushService: VoIPPushServiceProtocol

    init(
        clientService: StringeeClientServiceProtocol,
        callKitService: CallKitServiceProtocol,
        tokenStore: AccessTokenStoreProtocol,
        voIPPushService: VoIPPushServiceProtocol
    ) {
        self.clientService = clientService
        self.tokenStore = tokenStore
        self.voIPPushService = voIPPushService
        self.callCoordinator = CallCoordinator(
            clientService: clientService,
            callKitService: callKitService,
            tokenStore: tokenStore
        )
        bindPushService()
    }

    func start() {
        voIPPushService.start()
    }

    private func bindPushService() {
        voIPPushService.onTokenUpdate = { [weak self] token in
            self?.callCoordinator.handleVoIPToken(token)
        }
        voIPPushService.onIncomingPush = { [weak self] payload, completion in
            self?.callCoordinator.handleIncomingPush(payload, completion: completion)
        }
    }
}
