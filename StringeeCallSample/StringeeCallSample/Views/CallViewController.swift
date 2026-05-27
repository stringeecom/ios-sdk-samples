import UIKit

@MainActor
final class CallViewController: UIViewController {
    private let viewModel: CallViewModel

    private let remoteVideoContainer = UIView()
    private let localVideoContainer = UIView()
    private let voiceAvatarView = UIImageView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let controlsStack = UIStackView()
    private let answerButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SampleLog.call("CallViewController viewDidLoad \(viewModel.session.logDescription)")
        configureView()
        configureBindings()
        render()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SampleLog.call("CallViewController viewDidDisappear \(viewModel.session.logDescription) isBeingDismissed=\(isBeingDismissed)")
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        remoteVideoContainer.backgroundColor = .secondarySystemBackground
        remoteVideoContainer.accessibilityIdentifier = "remoteVideoContainer"
        remoteVideoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(remoteVideoContainer)

        localVideoContainer.backgroundColor = .tertiarySystemBackground
        localVideoContainer.layer.cornerRadius = 8
        localVideoContainer.clipsToBounds = true
        localVideoContainer.accessibilityIdentifier = "localVideoContainer"
        localVideoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(localVideoContainer)

        voiceAvatarView.image = UIImage(systemName: "person.crop.circle.fill")
        voiceAvatarView.tintColor = .systemBlue
        voiceAvatarView.contentMode = .scaleAspectFit
        voiceAvatarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(voiceAvatarView)

        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        controlsStack.axis = .horizontal
        controlsStack.alignment = .center
        controlsStack.distribution = .equalSpacing
        controlsStack.spacing = 14
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStack)

        configureCircleButton(muteButton, symbolName: "mic.slash.fill", identifier: "muteButton")
        configureCircleButton(speakerButton, symbolName: "speaker.wave.2.fill", identifier: "speakerButton")
        configureCircleButton(cameraButton, symbolName: "video.fill", identifier: "cameraButton")
        configureCircleButton(answerButton, symbolName: "phone.fill", identifier: "answerCallButton", color: .systemGreen)
        configureCircleButton(rejectButton, symbolName: "phone.down.fill", identifier: "rejectCallButton", color: .systemRed)
        configureCircleButton(endButton, symbolName: "phone.down.fill", identifier: "endCallButton", color: .systemRed)

        [muteButton, speakerButton, cameraButton, answerButton, rejectButton, endButton].forEach {
            controlsStack.addArrangedSubview($0)
            $0.widthAnchor.constraint(equalToConstant: 56).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 56).isActive = true
        }

        answerButton.addTarget(self, action: #selector(answerTapped), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(endTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(speakerTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            remoteVideoContainer.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            localVideoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            localVideoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            localVideoContainer.widthAnchor.constraint(equalToConstant: 120),
            localVideoContainer.heightAnchor.constraint(equalToConstant: 160),

            voiceAvatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            voiceAvatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -96),
            voiceAvatarView.widthAnchor.constraint(equalToConstant: 128),
            voiceAvatarView.heightAnchor.constraint(equalToConstant: 128),

            titleLabel.topAnchor.constraint(equalTo: voiceAvatarView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            controlsStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            controlsStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            controlsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

    private func configureBindings() {
        viewModel.onChange = { [weak self] in
            self?.render()
        }
        viewModel.onLocalVideoView = { [weak self] videoView in
            self?.install(videoView, in: self?.localVideoContainer)
        }
        viewModel.onRemoteVideoView = { [weak self] videoView in
            self?.install(videoView, in: self?.remoteVideoContainer)
        }
    }

    private func render() {
        titleLabel.text = viewModel.titleText
        statusLabel.text = viewModel.statusText

        remoteVideoContainer.isHidden = !viewModel.isVideoCall
        localVideoContainer.isHidden = !viewModel.isVideoCall
        voiceAvatarView.isHidden = viewModel.isVideoCall

        answerButton.isHidden = !viewModel.shouldShowAnswerControls
        rejectButton.isHidden = !viewModel.shouldShowAnswerControls
        endButton.isHidden = viewModel.shouldShowAnswerControls
        cameraButton.isHidden = !viewModel.isVideoCall

        updateButton(muteButton, isSelected: viewModel.isMuted, symbolName: viewModel.isMuted ? "mic.fill" : "mic.slash.fill")
        updateButton(speakerButton, isSelected: viewModel.isSpeakerEnabled, symbolName: "speaker.wave.2.fill")
        updateButton(cameraButton, isSelected: viewModel.isCameraEnabled, symbolName: viewModel.isCameraEnabled ? "video.fill" : "video.slash.fill")
    }

    private func configureCircleButton(_ button: UIButton, symbolName: String, identifier: String, color: UIColor = .secondarySystemFill) {
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.backgroundColor = color
        button.tintColor = color == .secondarySystemFill ? .label : .white
        button.layer.cornerRadius = 28
        button.accessibilityIdentifier = identifier
    }

    private func updateButton(_ button: UIButton, isSelected: Bool, symbolName: String) {
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        if button !== endButton && button !== answerButton && button !== rejectButton {
            button.backgroundColor = isSelected ? .systemBlue : .secondarySystemFill
            button.tintColor = isSelected ? .white : .label
        }
    }

    private func install(_ videoView: UIView, in container: UIView?) {
        guard let container else { return }
        container.subviews.forEach { $0.removeFromSuperview() }
        videoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: container.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    @objc private func answerTapped() {
        SampleLog.call("answer button tapped \(viewModel.session.logDescription)")
        viewModel.answerTapped()
    }

    @objc private func rejectTapped() {
        viewModel.rejectTapped()
    }

    @objc private func endTapped() {
        viewModel.endTapped()
    }

    @objc private func muteTapped() {
        viewModel.muteTapped()
    }

    @objc private func speakerTapped() {
        viewModel.speakerTapped()
    }

    @objc private func cameraTapped() {
        viewModel.cameraTapped()
    }
}
