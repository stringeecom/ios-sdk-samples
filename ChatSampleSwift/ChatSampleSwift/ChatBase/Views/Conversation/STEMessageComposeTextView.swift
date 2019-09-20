//
//  STEMessageComposeTextView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEMessageComposeTextViewFont = UIFont.systemFont(ofSize: 17)
let STEPlaceholderText = "Tin nhắn"

class STEMessageComposeTextView: UITextView {
    
    var placeholderLabel: UILabel!
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        self.commonInit()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    private func commonInit() {
        self.attributedText = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: STEMessageComposeTextViewFont, NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        
//        self.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        self.font = STEMessageComposeTextViewFont
        self.dataDetectorTypes = .link
        
        placeholderLabel = UILabel()
        placeholderLabel.font = self.font
        placeholderLabel.text = STEPlaceholderText
        placeholderLabel.textColor = STEColor.darkGray
        placeholderLabel.lineBreakMode = .byTruncatingTail
        addSubview(placeholderLabel)
                
        NotificationCenter.default.addObserver(self, selector: #selector(textViewTextDidChange(notification:)), name: UITextView.textDidChangeNotification, object: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !placeholderLabel.isHidden {
            var placeHolderFrame = self.placeholderLabel.frame
            let textviewHorizontalIndent: CGFloat = 5
            placeHolderFrame.origin.x = textContainerInset.left + textviewHorizontalIndent
            placeHolderFrame.origin.y = textContainerInset.top
            let fittedPlaceholderSize = self.placeholderLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            placeHolderFrame.size = fittedPlaceholderSize
            let maxPlaceholderWidth = self.frame.width - self.textContainerInset.left - self.textContainerInset.right - textviewHorizontalIndent * 2
            if fittedPlaceholderSize.width > maxPlaceholderWidth {
                placeHolderFrame.size.width = maxPlaceholderWidth
            }
            
            self.placeholderLabel.frame = placeHolderFrame
            
            // Đặt label ra sau dấu nháy của textview
            self.sendSubviewToBack(self.placeholderLabel)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func textViewTextDidChange(notification: Notification) {
        configurePlaceholderVisibility()
    }
    
    override var text: String! {
        didSet {
            configurePlaceholderVisibility()
        }
    }
    
    override var attributedText: NSAttributedString! {
        didSet {
            configurePlaceholderVisibility()
        }
    }
    
    // MARK: - Utils
    
    func configurePlaceholderVisibility() {
        if self.placeholderLabel != nil && self.attributedText != nil {
            self.placeholderLabel.isHidden = self.attributedText.length > 0
        }
    }
    
}
