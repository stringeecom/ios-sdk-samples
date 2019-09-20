//
//  STEMessageInputToolbar.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEMessageInputToolbarHorizontalPadding: CGFloat = 8.0
let STEMessageInputToolbarButtonVerticalPadding: CGFloat = 10.0
let STEMessageInputToolbarTextViewVerticalPadding: CGFloat = 4.0
let STEMessageInputToolbarBackgroundColor = UIColor(red: 247, green: 247, blue: 247, alpha: 1)

let STELeftAccessoryButtonWidth: CGFloat = 30.0
let STERightAccessoryButtonWidth: CGFloat = 30.0
let STEAccessoryButtonHeight: CGFloat = 30.0

// TextView
let STEMessageInputToolbarTextViewMaxNumberOfLines = 8
let STEMessageInputToolbarTextViewFont = UIFont.systemFont(ofSize: 16)
let STEMessageInputToolbarTextViewMaxHeight = CGFloat(STEMessageInputToolbarTextViewMaxNumberOfLines) * STEMessageInputToolbarTextViewFont.lineHeight
let STEMessageInputToolbarTextViewMinScrollHeight = CGFloat((STEMessageInputToolbarTextViewMaxNumberOfLines - 1)) * STEMessageInputToolbarTextViewFont.lineHeight

// Sticker
let STEMessageInputToolbarTickerButtonHeight: CGFloat = 30

@objc protocol STEMessageInputToolbarDelegate {
    func didTapRightAccessoryButton(rightButton: UIButton, messageInputToolbar: STEMessageInputToolbar)
    
    func didTapLeftAccessoryButton(leftButton: UIButton, messageInputToolbar: STEMessageInputToolbar)
    
//    @objc optional func didTapStickerButton(stickerButton: UIButton, messageInputToolbar: STEMessageInputToolbar)
    
    @objc optional func messageInputToolbarDidType(messageInputToolbar: STEMessageInputToolbar)
    
    @objc optional func messageInputToolbarDidEndTyping(messageInputToolbar: STEMessageInputToolbar)
}


class STEMessageInputToolbar: UIView {
    
    weak var containerViewController: UIViewController?
    var buttonCenterY: CGFloat = 0
    weak var inputToolbarDelegate: STEMessageInputToolbarDelegate?
    var isStickerMode = false
    
    let leftAccessoryButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "attachement"), for: .normal)
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    let rightAccessoryButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "microphone"), for: .normal)
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    let textInputView: STEMessageComposeTextView = {
        let inputView = STEMessageComposeTextView()
        inputView.layer.borderWidth = 0.5
        inputView.layer.cornerRadius = 10
        inputView.layer.borderColor = UIColor.lightGray.cgColor
        inputView.isScrollEnabled = true
        inputView.font = STEMessageInputToolbarTextViewFont
        
        return inputView
    }()
    
    let dummyTextView: STEMessageComposeTextView = {
        let textView = STEMessageComposeTextView()
        textView.font = STEMessageInputToolbarTextViewFont
        return textView
    }()

    let stickerButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "stickers"), for: .normal)
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
//    override var intrinsicContentSize: CGSize {
//        return .zero
//    }
    
    private func commonInit() {
        self.backgroundColor = STEMessageInputToolbarBackgroundColor

        self.translatesAutoresizingMaskIntoConstraints = false;
        self.autoresizingMask = .flexibleWidth;
        
        addSubview(leftAccessoryButton)
        addSubview(textInputView)
        addSubview(rightAccessoryButton)
        addSubview(stickerButton)
        
        self.textInputView.delegate = self
        leftAccessoryButton.addTarget(self, action: #selector(STEMessageInputToolbar.leftAccessoryButtonTapped), for: .touchUpInside)
        rightAccessoryButton.addTarget(self, action: #selector(STEMessageInputToolbar.rightAccessoryButtonTapped), for: .touchUpInside)
        stickerButton.addTarget(self, action: #selector(STEMessageInputToolbar.stickerTapped), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        bringSubviewToFront(leftAccessoryButton)
//        bringSubviewToFront(textInputView)
//        bringSubviewToFront(rightAccessoryButton)
//        bringSubviewToFront(stickerButton)

//        let safeAreaInsets = self.getSafeAreaInsets()
        let safeAreaInsets = UIEdgeInsets.zero
        
        var frame = self.frame
        var leftButtonFrame = leftAccessoryButton.frame
        var rightButtonFrame = rightAccessoryButton.frame
        var textViewFrame = self.textInputView.frame
        var stickerButtonFrame = self.stickerButton.frame
        
        leftButtonFrame.size.width = STELeftAccessoryButtonWidth
        if self.containerViewController != nil {
            let windowRect: CGRect = self.containerViewController?.view.superview?.convert(self.containerViewController?.view.frame ?? .zero, to: nil) ?? .zero
            frame.size.width = windowRect.size.width
            frame.origin.x = windowRect.origin.x
        }
        leftButtonFrame.size.height = STEAccessoryButtonHeight
        leftButtonFrame.origin.x = STEMessageInputToolbarHorizontalPadding + safeAreaInsets.left
        
        rightButtonFrame.size.width = STERightAccessoryButtonWidth
        rightButtonFrame.size.height = STEAccessoryButtonHeight
        rightButtonFrame.origin.x = frame.width - rightButtonFrame.width - STEMessageInputToolbarHorizontalPadding - safeAreaInsets.right
        
        textViewFrame.origin.x = leftButtonFrame.maxX + STEMessageInputToolbarHorizontalPadding
        textViewFrame.origin.y = STEMessageInputToolbarTextViewVerticalPadding
        textViewFrame.size.width = rightButtonFrame.minX - textViewFrame.minX - STEMessageInputToolbarHorizontalPadding
        
        dummyTextView.attributedText = textInputView.attributedText
        let fittedTextViewSize = dummyTextView.sizeThatFits(CGSize(width: textViewFrame.width, height: CGFloat.greatestFiniteMagnitude))
        textViewFrame.size.height = ceil(Swift.min(fittedTextViewSize.height, STEMessageInputToolbarTextViewMaxHeight))
        
        frame.size.height = textViewFrame.size.height + STEMessageInputToolbarTextViewVerticalPadding * 2 + safeAreaInsets.bottom
        frame.origin.y -= (frame.size.height - self.frame.height)
        
        // Ghim 2 button ở dưới khi chat, center textview khi sticker

            if buttonCenterY == 0 {
                buttonCenterY = (frame.height - leftButtonFrame.height - safeAreaInsets.bottom) / 2
            }
            leftButtonFrame.origin.y = frame.size.height - leftButtonFrame.size.height - buttonCenterY - safeAreaInsets.bottom
            rightButtonFrame.origin.y = frame.size.height - rightButtonFrame.size.height - buttonCenterY - safeAreaInsets.bottom
        


        // Sticker button
        stickerButtonFrame.size = CGSize(width: STEMessageInputToolbarTickerButtonHeight, height: STEMessageInputToolbarTickerButtonHeight)
        stickerButtonFrame.origin.x = textViewFrame.maxX - 5 - STEMessageInputToolbarTickerButtonHeight
        stickerButtonFrame.origin.y = rightButtonFrame.maxY - STEAccessoryButtonHeight * 0.5 - STEMessageInputToolbarTickerButtonHeight * 0.5
        
        let heightChanged: Bool = (textViewFrame.size.height != textInputView.frame.size.height) || (frame.size.height != self.frame.size.height)
        
        // Gán lại frame
        self.leftAccessoryButton.frame = leftButtonFrame
        self.rightAccessoryButton.frame = rightButtonFrame
        self.textInputView.frame = textViewFrame
        if textViewFrame.height < STEMessageInputToolbarTextViewMaxHeight {
            // Fix bug textContainerView's frame bị sai lần thứ 2 thay đổi height
            self.textInputView.textContainer.size = textViewFrame.size
        }
        self.stickerButton.frame = stickerButtonFrame
        self.frame = frame
        
        if heightChanged {
            // Bắn notification
            NotificationCenter.default.post(name: Notification.Name.STEMessageInputToolbarDidChangeHeightNotification, object: self)
        }
    }
    
    // MARK: - Actions

    @objc func leftAccessoryButtonTapped() {
        self.inputToolbarDelegate?.didTapLeftAccessoryButton(leftButton: self.leftAccessoryButton, messageInputToolbar: self)
    }
    
    @objc func rightAccessoryButtonTapped() {
        if let messageInputToolbarDidEndTyping = self.inputToolbarDelegate?.messageInputToolbarDidEndTyping {
            messageInputToolbarDidEndTyping(self)
        }
        self.inputToolbarDelegate?.didTapRightAccessoryButton(rightButton: self.rightAccessoryButton, messageInputToolbar: self)
        
        self.textInputView.text = ""
        setNeedsLayout()
        configureRightAccessoryButton()
    }
    
    @objc func stickerTapped() {
        changeStickerMode()
    }
    
    func changeStickerMode(shouldFireNotification: Bool = true) {
        isStickerMode = !isStickerMode
        let imageName = isStickerMode ? "ConversationInputFieldKeyboardIcon" : "stickers"
        stickerButton.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
        stickerButton.tintColor = STEColor.iconGrayTheme
        if shouldFireNotification {
            NotificationCenter.default.post(name: Notification.Name.STEDidTapStickerNotification, object: self, userInfo: nil)
        }
    }
}

// MARK: - TextViewDelegate

extension STEMessageInputToolbar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Thay image cho button send
        configureRightAccessoryButton()
        
        // Bắn event
        if textView.text.count > 0 {
            if let messageInputToolbarDidType = self.inputToolbarDelegate?.messageInputToolbarDidType {
                messageInputToolbarDidType(self)
            }
        } else if textView.text.count == 0 {
            if let messageInputToolbarDidEndTyping = self.inputToolbarDelegate?.messageInputToolbarDidEndTyping {
                messageInputToolbarDidEndTyping(self)
            }
        }
        
        // Layout lại để thay đổi frame của textview
        setNeedsLayout()
        
        // Cho scroll nếu đã viết hết 1 dòng hoặc ấn xuống dòng
        self.textInputView.isScrollEnabled = self.textInputView.frame.size.height > STEMessageInputToolbarTextViewMinScrollHeight
        
        // Di chuyển khung nhìn đến phần đang typing
        let line = textView.caretRect(for: textView.selectedTextRange?.start ?? UITextPosition())
        if !line.size.equalTo(.zero) {
            let overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.top - textView.contentInset.bottom)
            if overflow > 0 {
                var offset = textView.contentOffset
                offset.y += overflow
                
                UIView.animate(withDuration: 0.2) {
                    textView.contentOffset = offset
                }
            }
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        // Fix bug một số trường hợp ko tự động scroll
        textView.scrollRangeToVisible(textView.selectedRange)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        configureRightAccessoryButton()
        
        // Nếu đang là stickerMode mà người dùng ấn vào textview thì cần chuyển trạng thái
        if isStickerMode == true {
            changeStickerMode()
        }
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        configureRightAccessoryButton()
        return true
    }

}

// MARK: - Utils
extension STEMessageInputToolbar {
    func configureRightAccessoryButton() {
        let baseText = textInputView.text ?? ""
//        let trimedText = baseText.trimmingCharacters(in: .whitespacesAndNewlines)
        if baseText.count > 0 {
            rightAccessoryButton.setImage(UIImage(named: "ModernConversationSend"), for: .normal)
        } else {
            rightAccessoryButton.setImage(UIImage(named: "microphone"), for: .normal)
        }
        
        stickerButton.isHidden = baseText.count > 0
    }
}
