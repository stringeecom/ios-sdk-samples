//
//  STEBaseConversationViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import Parchment

let STEMaxScrollDistanceFromBottom: CGFloat = 150.0
let STEMessageInputStickerViewHeight: CGFloat = 260.0
let STEMessageInputViewDefaultHeight: CGFloat = 44.0
let STEMessageInputViewDistanceToDismissSticker: CGFloat = 50.0
let STEBaseConversationViewControllerBottomOffsetExtend: CGFloat = 5

class STEBaseConversationViewController: UIViewController {
    
    private var conversationView: STEConversationView!
    private var keyboardHeight: CGFloat! = 0
    private var messageInputDistanceFromMinYToBottomView: CGFloat! = 0
    private var invisibleAccessoryViewCenterY: CGFloat! = 0
    private var firstAppearance = true
    private var shouldChangeWrapViewFrame = false
    private var inputWrapView: UIView!
    private var pagingViewController: PagingViewController<IconItem>!
    private lazy var invisibleAccessoryView: STEObservingInputAccessoryView = {
        var height = STEMessageInputViewDefaultHeight
        if #available(iOS 11, *) {
            height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        let view = STEObservingInputAccessoryView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: height))
        view.backgroundColor = .blue
        view.alpha = 0
        return view
    }()
    private var safeAreaInsets: UIEdgeInsets!
    
//    fileprivate let icons = [
//        "StickerKeyboardTrendingIcon",
//        "StickerKeyboardTrendingIcon",
//        "StickerKeyboardTrendingIcon"
//    ]
    
    let messageInputView = STEMessageInputToolbar()
    
    override var inputAccessoryView: STEObservingInputAccessoryView {
        return invisibleAccessoryView
    }
    
    var collectionView: UICollectionView! {
        didSet {
            if collectionView != nil {
                self.view.addSubview(collectionView)
                collectionView.snp.makeConstraints { (make) in
                    make.edges.equalTo(self.view)
                }
            } 
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        invisibleAccessoryView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageInputView.containerViewController = self
        baseNotificationRegister()
        
        // Tự control contentInset
        if #available(iOS 11, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        self.collectionView.panGestureRecognizer.addTarget(self, action: #selector(STEBaseConversationViewController.handlePanGestureToCollectionView(gesture:)))
        
        self.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Workaround for a modal dismissal causing the message toolbar to remain offscreen on iOS 8.
        if self.presentedViewController != nil || !self.isFirstResponder {
            self.becomeFirstResponder()
        }
        
        if firstAppearance {
            updateTopCollectionViewInset()
        }
        updateBottomCollectionViewInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.presentedViewController == nil && self.navigationController != nil && self.view.inputAccessoryView?.superview == nil {
            self.becomeFirstResponder()
        }
        
        // Tạo view lần đầu nếu chưa có
        if inputWrapView == nil {
            safeAreaInsets = self.view.getSafeAreaInsets()
            
            let viewFrame = view.frame
            let wrapviewHeight: CGFloat = STEMessageInputStickerViewHeight + STEMessageInputViewDefaultHeight + safeAreaInsets.bottom
            let wrapViewOriginY = viewFrame.maxY - STEMessageInputViewDefaultHeight - safeAreaInsets.bottom
            
            // WrapView
            inputWrapView = UIView(frame: CGRect(x: viewFrame.origin.x, y: wrapViewOriginY, width: viewFrame.width, height: wrapviewHeight))
            inputWrapView.backgroundColor = STEMessageInputToolbarBackgroundColor
            view.addSubview(inputWrapView)
            
            // InputView
            messageInputView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: STEMessageInputViewDefaultHeight)
            inputWrapView.addSubview(messageInputView)
        
            // Sticker View
            let pageViewOriginY = messageInputView.frame.maxY
            pagingViewController = STEPagingViewController()
            
            addChild(pagingViewController)
            inputWrapView.addSubview(pagingViewController.view)
            pagingViewController.view.frame = CGRect(x: 0, y: pageViewOriginY, width: viewFrame.width, height: STEMessageInputStickerViewHeight)
            pagingViewController.didMove(toParent: self)
            pagingViewController.view.isHidden = true
        }
        else {
            // Fix bug frame của inputview bị sai khi push sang view này từ search controller
            let oldFrame = messageInputView.frame
            let newFrame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: oldFrame.height)
            messageInputView.frame = newFrame
        }
    }
    
}

// MARK: - Publish methods

extension STEBaseConversationViewController {
    func shouldScrollToBottom() -> Bool {
        // lấy về offset cần set để nhìn thấy đáy
        let bottomOffset = bottomOffsetFor(contentSize: collectionView.collectionViewLayout.collectionViewContentSize)
        
        // Tính khoảng cách từ screen đến đấy content (tính từ đáy screen -> đáy contentSize)
        let distanceToBottom = bottomOffset.y - collectionView.contentOffset.y
        
        /*
         Nên scroll to bottom khi:
         1. Khoảng cách đến đáy lớn hơn giá trị max
         2. User đang ko touch, ko drag và scrollview ngừng di chuyển sau khi user touch up
         **/
        let shouldScrollToBottom = distanceToBottom <= STEMaxScrollDistanceFromBottom && !collectionView.isTracking && !collectionView.isDragging && !collectionView.isDecelerating
        
        return shouldScrollToBottom
    }
    
    func scrollToBottom(animated: Bool) {
        var contentOffset = bottomOffsetFor(contentSize: collectionView.contentSize)
        contentOffset.x = collectionView.contentOffset.x
        collectionView.setContentOffset(contentOffset, animated: animated)
    }
}

// MARK: - Helpers

extension STEBaseConversationViewController {
    // Hàm này tính toạ độ Y của offset để có thể nhìn thấy content của scrollview bao gồm cả bottomInset
    func bottomOffsetFor(contentSize: CGSize) -> CGPoint {
        let contentSizeHeight = contentSize.height
        let collectionViewFrameHeight = collectionView.frame.size.height
        let contentInset = collectionView.ste_adjustedContentInset()
        
        return CGPoint(x: 0, y: Swift.max(-contentInset.top, contentSizeHeight - (collectionViewFrameHeight - contentInset.bottom)))
    }
    
    func configureWithKeyboardNotification(notification: Notification, isShow: Bool) {
        if messageInputView.isStickerMode { return }
        
        // Lấy về thông tin từ notificaion
        let keyboardBeginFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardBeginFrameInView = self.view.convert(keyboardBeginFrame ?? .zero, from: nil)
        let keyboardEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardEndFrameInView = self.view.convert(keyboardEndFrame ?? .zero, from: nil)
        let keyboardEndFrameIntersectingView = self.view.bounds.intersection(keyboardEndFrameInView)
        
        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationType = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue
        let animationCurve = UIView.AnimationCurve(rawValue: animationType) ?? .easeIn
        let animationOption = UIView.AnimationOptions(rawValue: UInt(animationType))

        // Lưu lại thông tin keyboard height bao gồm cả invisibleAccessoryView
        let keyboardHeight = keyboardEndFrameIntersectingView.size.height
//        keyboardHeight -= self.messageInputView.frame.minY
        self.keyboardHeight = keyboardHeight
        
        // Chỉnh lại vị trí của inputView để show messageinputview
        let viewFrame = view.frame
        if inputWrapView != nil {
            var inputWrapViewOriginY: CGFloat!
            if isShow && keyboardEndFrameIntersectingView.minY < (viewFrame.maxY - 150) {
                inputWrapViewOriginY = viewFrame.maxY - (self.keyboardHeight - (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom)) - self.messageInputView.frame.height
            } else {
                inputWrapViewOriginY = viewFrame.maxY - (self.keyboardHeight - (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom)) - (self.messageInputView.frame.height + safeAreaInsets.bottom)
            }

//            UIView.animate(withDuration: animationDuration, delay: 0, options: animationOption, animations: {
//                self.inputWrapView.frame = CGRect(origin: CGPoint(x: viewFrame.origin.x, y: inputWrapViewOriginY), size: self.inputWrapView.frame.size)
//            }, completion: nil)
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationOption, animations: {
                self.inputWrapView.frame = CGRect(origin: CGPoint(x: viewFrame.origin.x, y: inputWrapViewOriginY), size: self.inputWrapView.frame.size)
            }) { (status) in
                self.pagingViewController.view.isHidden = !self.messageInputView.isStickerMode
            }
            
            messageInputDistanceFromMinYToBottomView = viewFrame.maxY - inputWrapViewOriginY
        } else {
            messageInputDistanceFromMinYToBottomView = keyboardHeight
        }
        
        // Update bottom inset của colelectionView không animate
        if keyboardEndFrameInView.equalTo(keyboardBeginFrameInView) {
            UIView.performWithoutAnimation {
                updateBottomCollectionViewInset()
            }
            return
        }

        // Update bottom inset của colelectionView có animate
        self.view.layoutIfNeeded()
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        updateBottomCollectionViewInset()
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
    }

}

// MARK: - Notifications

extension STEBaseConversationViewController {
    
    func baseNotificationRegister() {
        // Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(STEBaseConversationViewController.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEBaseConversationViewController.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(messageInputToolbarDidChangeHeight(notification:)), name: Notification.Name.STEMessageInputToolbarDidChangeHeightNotification, object: messageInputView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewTextDidBeginEditing(notification:)), name: UITextView.textDidBeginEditingNotification, object: messageInputView.textInputView)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidTapSticker(notification:)), name: Notification.Name.STEDidTapStickerNotification, object: messageInputView)
    }
    
    @objc func messageInputToolbarDidChangeHeight(notification: Notification) {
        print("messageInputToolbarDidChangeHeight \(messageInputView.frame.height)")
        
        if self.messageInputView.superview == nil {
            return
        }
        // Cập nhật lại frame của InputWrapView
        let viewFrame = view.frame
        let messageInputFrame = messageInputView.frame
        let wrapviewHeight = STEMessageInputStickerViewHeight + messageInputFrame.height + safeAreaInsets.bottom
        let inputWrapViewOriginY = viewFrame.maxY - (self.keyboardHeight - (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom)) - self.messageInputView.frame.height
        inputWrapView.frame = CGRect(x: viewFrame.origin.x, y: inputWrapViewOriginY, width: viewFrame.width, height: wrapviewHeight)
        self.messageInputView.frame.origin = CGPoint(x: viewFrame.origin.x, y: 0)
        self.pagingViewController.view.frame.origin = CGPoint(x: viewFrame.origin.x, y: self.messageInputView.frame.maxY)

        // Lấy về rect of messageInputToolbar trong view
        let toolbarFrame = self.view.convert(self.messageInputView.frame, from: self.messageInputView.superview)
        
        // Lấy về khoảng cách từ minY của messageInputView tới bottom
        let distanceFromMessageInputViewToBottom = self.view.frame.height - toolbarFrame.minY
        if distanceFromMessageInputViewToBottom == self.messageInputDistanceFromMinYToBottomView {
            return
        }

        let messagebarDidGrow = distanceFromMessageInputViewToBottom > self.messageInputDistanceFromMinYToBottomView
        self.messageInputDistanceFromMinYToBottomView = distanceFromMessageInputViewToBottom
        updateBottomCollectionViewInset()

        if self.shouldScrollToBottom() && messagebarDidGrow {
            self.scrollToBottom(animated: true)
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        print("keyboardWillShow")
        shouldChangeWrapViewFrame = true
        if self.navigationController?.modalPresentationStyle == .popover {
            return
        }
        configureWithKeyboardNotification(notification: notification, isShow: true)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        print("keyboardWillHide")
        configureWithKeyboardNotification(notification: notification, isShow: false)
    }
    
    @objc func textViewTextDidBeginEditing(notification: Notification) {
        scrollToBottom(animated: true)
    }
    
    @objc func handleDidTapSticker(notification: Notification) {
        print("handleDidTapSticker")
        let animationDuration = messageInputView.textInputView.isFirstResponder ? 0.32 : 0.2
        
        if messageInputView.isStickerMode {
            // Ẩn keyboard
            messageInputView.textInputView.resignFirstResponder()
            
            // Thay đổi frame wrapview để hiện thị sticker
            let oldFrame = inputWrapView.frame
            let newOriginY = view.frame.maxY - oldFrame.height
            messageInputDistanceFromMinYToBottomView = oldFrame.height
            pagingViewController.view.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.inputWrapView.frame.origin = CGPoint(x: oldFrame.origin.x, y: newOriginY)
                
                // Update contentinset của collectionView và scroll tới đáy
                self.updateBottomCollectionViewInset()
                self.scrollToBottom(animated: true)
            }, completion: nil)
        } else {
            // Show keyboard
            shouldChangeWrapViewFrame = false
            messageInputView.textInputView.becomeFirstResponder()
        }
    }
}

// MARK: - Content Inset Management

extension STEBaseConversationViewController {
    func updateTopCollectionViewInset() {
        // Lấy về contentInset
        var contentInset = self.collectionView.ste_adjustedContentInset()
        var scrollIndicatorInsets = self.collectionView.scrollIndicatorInsets
        
        contentInset.top = self.navigationController?.navigationBar.frame.maxY ?? 0
        scrollIndicatorInsets.top = contentInset.top
        self.collectionView.contentInset = contentInset
        self.collectionView.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    func updateBottomCollectionViewInset() {
        self.messageInputView.layoutIfNeeded()
        
        var insets = self.collectionView.ste_adjustedContentInset()
        let distanceFromMessageInputViewToBottom = Swift.max(self.messageInputDistanceFromMinYToBottomView, self.messageInputView.frame.height)
        
        insets.bottom = distanceFromMessageInputViewToBottom + STEBaseConversationViewControllerBottomOffsetExtend
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
    }
}

// MARK: - Gesture

extension STEBaseConversationViewController {
    @objc private func handlePanGestureToCollectionView(gesture: UIPanGestureRecognizer) {
        // Nếu ko phải stickerMode thì thôi
        if !messageInputView.isStickerMode { return }
        
        let velocity = gesture.velocity(in: self.view)
        
        // Người dùng đang kéo xuống mới tính
        if velocity.y > 0 {
            // Lấy về touch point
            let point = gesture.location(in: self.view)

            let wrapViewMinY = inputWrapView.frame.minY
            let detal = abs(wrapViewMinY - point.y)
            
            // Dissmiss StickerView và chuyển chế độ
            if detal <= STEMessageInputViewDistanceToDismissSticker || point.y > wrapViewMinY {
                dismissStickerView()
            }
        }
    }
    
    func dismissStickerView() {
        if messageInputView.textInputView.isFirstResponder {
            messageInputView.textInputView.resignFirstResponder()
        }
        
        let oldOrigin = inputWrapView.frame.origin
        let frameOfInvisibleView = self.view.convert(self.invisibleAccessoryView.frame, from: self.invisibleAccessoryView.superview)
        self.messageInputDistanceFromMinYToBottomView = frameOfInvisibleView.height
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.inputWrapView.frame.origin = CGPoint(x: oldOrigin.x, y: frameOfInvisibleView.origin.y)
            self.updateBottomCollectionViewInset()
            if self.shouldScrollToBottom() {
                self.scrollToBottom(animated: true)
            }
            self.messageInputView.changeStickerMode(shouldFireNotification: false)
        }) { (status) in
            self.pagingViewController.view.isHidden = true
        }
    }
}

// MARK: - Sticker

extension STEBaseConversationViewController: STEObservingInputAccessoryViewDelegate {
    func didChangeCenter(newCenter: CGPoint, observingView: STEObservingInputAccessoryView) {
//        print("didChangeCenter")
        if messageInputView.isStickerMode || !shouldChangeWrapViewFrame { return }
        
        let center = self.view.convert(self.invisibleAccessoryView.center, from: self.invisibleAccessoryView.superview)
        if center.y > (self.view.frame.maxY - (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom) * 0.5) {
            return
        }

        if self.inputWrapView != nil {
            let oldInputWrapViewFrame = self.inputWrapView.frame
            var newOriginY: CGFloat!
            if center.y > (self.view.frame.maxY - (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom)) {
                let inputViewHeight = self.messageInputView.frame.height + safeAreaInsets.bottom
                newOriginY = center.y + (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom) * 0.5 - inputViewHeight
            } else {
                newOriginY = center.y + (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom) * 0.5 - self.messageInputView.frame.height
            }
//            let inputViewHeight = self.messageInputView.frame.height + safeAreaInsets.bottom
//            newOriginY = center.y + (STEMessageInputViewDefaultHeight + safeAreaInsets.bottom) * 0.5 - inputViewHeight
            self.inputWrapView.frame.origin = CGPoint(x: oldInputWrapViewFrame.origin.x, y: newOriginY)
        }
    }
}

//extension STEBaseConversationViewController: PagingViewControllerDataSource {
//
//    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
//        return STEStickerViewController(title: icons[index].capitalized)
//    }
//
//    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
//        return IconItem(icon: icons[index], index: index) as! T
//    }
//
//    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int {
//        return icons.count
//    }
//
//}
