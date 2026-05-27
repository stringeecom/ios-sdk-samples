import UIKit

@MainActor
final class HomeViewController: UIViewController {
    private enum DemoDefaults {
        static let accessToken = [
            "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ",
            "eyJqdGkiOiJTS3JTaWZRWlVJa3ZPY2Q0RHdZT2c1Y2lpQUJma01kTTJOLTE3Nzk3ODg2MzgiLCJpc3MiOiJTS3JTaWZRWlVJa3ZPY2Q0RHdZT2c1Y2lpQUJma01kTTJOIiwiZXhwIjoxNzc5ODc1MDM4LCJ1c2VySWQiOiI4NDk4ODI0NzAwMCIsImNhbkNhbGxvdXQiOmZhbHNlfQ",
            "xCWNgaTyoHQLSk1WF-kis8e-griJLQT36hwVye6vELU"
        ].joined(separator: ".")
    }

    private let viewModel: HomeViewModel
    private let clientService: StringeeClientServiceProtocol
    private let tokenStore: AccessTokenStoreProtocol?
    private let callCoordinator: CallCoordinating?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()
    private let pushStatusLabel = UILabel()
    private let tokenField = UITextField()
    private let calleeField = UITextField()
    private let callKindControl = UISegmentedControl(items: ["Voice", "Video"])
    private let connectButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    private let startCallButton = UIButton(type: .system)
    private let simulateIncomingVoiceButton = UIButton(type: .system)
    private let simulateIncomingVideoButton = UIButton(type: .system)
    private let simulateVoIPPushButton = UIButton(type: .system)

    init(
        clientService: StringeeClientServiceProtocol,
        tokenStore: AccessTokenStoreProtocol? = nil,
        callCoordinator: CallCoordinating? = nil
    ) {
        self.clientService = clientService
        self.tokenStore = tokenStore
        self.callCoordinator = callCoordinator
        self.viewModel = HomeViewModel(clientService: clientService)
        super.init(nibName: nil, bundle: nil)
        title = "Stringee Call"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureBindings()
        render()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .always

        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "connectionStatusLabel"

        pushStatusLabel.font = .preferredFont(forTextStyle: .subheadline)
        pushStatusLabel.textColor = .secondaryLabel
        pushStatusLabel.numberOfLines = 0
        pushStatusLabel.accessibilityIdentifier = "pushStatusLabel"
        pushStatusLabel.text = "VoIP push not registered"

        configureTextField(tokenField, placeholder: "Access token", identifier: "accessTokenTextField")
        let savedToken = tokenStore?.loadAccessToken()
        let initialToken = savedToken?.isEmpty == false ? savedToken! : DemoDefaults.accessToken
        tokenField.text = initialToken
        viewModel.accessToken = initialToken

        configureTextField(calleeField, placeholder: "Callee user ID", identifier: "calleeTextField")

        callKindControl.selectedSegmentIndex = 0
        callKindControl.accessibilityIdentifier = "callKindSegmentedControl"
        callKindControl.addTarget(self, action: #selector(callKindChanged), for: .valueChanged)

        configurePrimaryButton(connectButton, title: "Connect", symbolName: "bolt.horizontal.circle.fill", identifier: "connectButton")
        configureSecondaryButton(disconnectButton, title: "Disconnect", symbolName: "bolt.horizontal.circle", identifier: "disconnectButton")
        configurePrimaryButton(startCallButton, title: "Start Call", symbolName: "phone.arrow.up.right.fill", identifier: "startCallButton")
        configureSecondaryButton(simulateIncomingVoiceButton, title: "Incoming Voice", symbolName: "phone.arrow.down.left", identifier: "simulateIncomingVoiceButton")
        configureSecondaryButton(simulateIncomingVideoButton, title: "Incoming Video", symbolName: "video.badge.ellipsis", identifier: "simulateIncomingVideoButton")
        configureSecondaryButton(simulateVoIPPushButton, title: "VoIP Push", symbolName: "bell.badge", identifier: "simulateVoIPPushButton")

        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        startCallButton.addTarget(self, action: #selector(startCallTapped), for: .touchUpInside)
        simulateIncomingVoiceButton.addTarget(self, action: #selector(simulateIncomingVoiceTapped), for: .touchUpInside)
        simulateIncomingVideoButton.addTarget(self, action: #selector(simulateIncomingVideoTapped), for: .touchUpInside)
        simulateVoIPPushButton.addTarget(self, action: #selector(simulateVoIPPushTapped), for: .touchUpInside)
        tokenField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        calleeField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

        let connectionStack = UIStackView(arrangedSubviews: [connectButton, disconnectButton])
        connectionStack.axis = .horizontal
        connectionStack.spacing = 12
        connectionStack.distribution = .fillEqually

        let fakeStack = UIStackView(arrangedSubviews: [simulateIncomingVoiceButton, simulateIncomingVideoButton, simulateVoIPPushButton])
        fakeStack.axis = .vertical
        fakeStack.spacing = 12
        fakeStack.isHidden = !CommandLine.arguments.contains("--uitesting-fake-stringee")

        [statusLabel, pushStatusLabel, tokenField, connectionStack, calleeField, callKindControl, startCallButton, fakeStack].forEach {
            contentStack.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            tokenField.heightAnchor.constraint(equalToConstant: 48),
            calleeField.heightAnchor.constraint(equalToConstant: 48),
            connectButton.heightAnchor.constraint(equalToConstant: 48),
            startCallButton.heightAnchor.constraint(equalToConstant: 52),
            callKindControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func configureBindings() {
        viewModel.onChange = { [weak self] in
            self?.render()
        }
        viewModel.onPresentCall = { [weak self] session in
            self?.presentCall(session)
        }
        viewModel.onConnectionStateObserved = { [weak self] state in
            self?.callCoordinator?.handleConnectionState(state)
        }
        callCoordinator?.onPresentCall = { [weak self] session in
            guard let self else { return }
            self.viewModel.trackExternalCall(session)
            self.presentCall(session)
        }
        callCoordinator?.onPushStatusChange = { [weak self] text in
            self?.pushStatusLabel.text = text
        }
    }

    private func render() {
        statusLabel.text = viewModel.connectionStatusText
        connectButton.isEnabled = !viewModel.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        disconnectButton.isEnabled = viewModel.isConnected
        startCallButton.isEnabled = viewModel.canStartCall
    }

    private func presentCall(_ session: CallSessionProtocol) {
        SampleLog.call("present call screen \(session.logDescription)")
        if session.direction == .outgoing {
            callCoordinator?.startOutgoingCall(session)
        }
        let callViewModel = CallViewModel(session: session, actions: coordinatorActions())
        let callViewController = CallViewController(viewModel: callViewModel)
        callViewController.modalPresentationStyle = .fullScreen
        callViewModel.onDismiss = { [weak self, weak callViewController] in
            SampleLog.call("HomeViewController onDismiss \(session.logDescription)")
            self?.callCoordinator?.clearCall(session)
            self?.viewModel.clearActiveCall(session)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                SampleLog.call("dismiss call screen \(session.logDescription)")
                callViewController?.dismiss(animated: true)
            }
        }
        present(callViewController, animated: true)
    }

    private func configureTextField(_ textField: UITextField, placeholder: String, identifier: String) {
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.placeholder = placeholder
        textField.accessibilityIdentifier = identifier
    }

    private func configurePrimaryButton(_ button: UIButton, title: String, symbolName: String, identifier: String) {
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        button.accessibilityIdentifier = identifier
    }

    private func configureSecondaryButton(_ button: UIButton, title: String, symbolName: String, identifier: String) {
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        button.accessibilityIdentifier = identifier
    }

    @objc private func connectTapped() {
        view.endEditing(true)
        textFieldChanged()
        let token = viewModel.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty {
            tokenStore?.saveAccessToken(token)
        }
        viewModel.connectTapped()
    }

    @objc private func disconnectTapped() {
        viewModel.disconnectTapped()
    }

    @objc private func startCallTapped() {
        view.endEditing(true)
        textFieldChanged()
        viewModel.startCallTapped()
    }

    @objc private func callKindChanged() {
        viewModel.selectedCallKind = callKindControl.selectedSegmentIndex == 0 ? .voice : .video
    }

    @objc private func textFieldChanged() {
        viewModel.accessToken = tokenField.text ?? ""
        viewModel.calleeId = calleeField.text ?? ""
        render()
    }

    @objc private func simulateIncomingVoiceTapped() {
        (clientService as? DemoStringeeClientService)?.simulateIncoming(kind: .voice)
    }

    @objc private func simulateIncomingVideoTapped() {
        (clientService as? DemoStringeeClientService)?.simulateIncoming(kind: .video)
    }

    @objc private func simulateVoIPPushTapped() {
        let callId = "demo-push-call-\(UUID().uuidString)"
        let payload: [AnyHashable: Any] = [
            "data": [
                "map": [
                    "type": "CALL_EVENT",
                    "data": [
                        "map": [
                            "callStatus": "started",
                            "callId": callId,
                            "serial": 1,
                            "isVideoCall": false,
                            "from": [
                                "map": [
                                    "alias": "demo-caller",
                                    "number": "demo-caller"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        callCoordinator?.handleIncomingPush(payload) {}
        (clientService as? DemoStringeeClientService)?.simulateIncoming(kind: .voice, id: callId)
    }

    private func coordinatorActions() -> CallViewModel.Actions {
        guard let callCoordinator else { return CallViewModel.Actions() }
        return CallViewModel.Actions(
            answer: { callCoordinator.answer($0) },
            reject: { callCoordinator.reject($0) },
            hangup: { callCoordinator.hangup($0) },
            mute: { isMuted, session in callCoordinator.setMuted(isMuted, for: session) },
            speaker: { isEnabled, session in session.setSpeakerEnabled(isEnabled) },
            camera: { isEnabled, session in session.setCameraEnabled(isEnabled) }
        )
    }
}
