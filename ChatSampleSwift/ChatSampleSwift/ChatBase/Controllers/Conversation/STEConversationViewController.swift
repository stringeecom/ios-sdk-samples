//
//  STEConversationViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import AXPhotoViewer
import AVKit

struct ChangeObject {
    var type: DataManagerChangeType
    var currentIndex: Int
    var newIndex: Int
}

let STEOffsetToTriggerLoadMoreMessage: CGFloat = 2000
let STEConversationDefaultTitle = "Cuộc trò chuyện"

class STEConversationViewController: STEBaseConversationViewController {
    
    private var client: StringeeClient?
    var conversation: StringeeConversation?
    var dataManager: STEDataManager!
    var objectChanges = [ChangeObject]()
    var refresher: UIRefreshControl!
    var isFirstLoadMore = true
    
    var maxSeqMarked: UInt = 0
    
    // file
    var sendFileType = false
    var interactionController: UIDocumentInteractionController!

    // Image
    lazy var photos = [AXPhoto]()
    var previewingContext: UIViewControllerPreviewing?

    init(client: StringeeClient, conversation: StringeeConversation) {
        super.init(nibName: nil, bundle: nil)
        self.messageInputView.inputToolbarDelegate = self
        self.client = client
        self.conversation = conversation
        self.dataManager = STEDataManager(client: client, conversation: conversation, displayType: .multiSections)
        self.dataManager.delegate = self
        self.dataManager.start()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .clear
        let followLayout = UICollectionViewFlowLayout()
        self.collectionView = STEConversationCollectionView(frame: .zero, collectionViewLayout: followLayout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
//        self.collectionView.prefetchDataSource = self
        
    }
    
    deinit {
        self.dataManager = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.title = conversation != nil ? STETitleFor(conversation: conversation!) : STEConstant.converastionDefaultTitle
        self.view.backgroundColor = .white
        checkAndMarkMessageAsRead()
        
        self.registerNotifications()

        self.collectionView.bindHeadRefreshHandler({ [weak self] in
            guard let self = self else { return }
            print("============== bindHeadRefreshHandler")
            
            if !self.dataManager.hasOlderData {
                self.collectionView.headRefreshControl.endRefreshing()
                self.collectionView.headRefreshControl.isHidden = true
                return
            }
            self.dataManager.loadOlderMessages({ (status) in
                if !status {
                    self.collectionView.headRefreshControl.endRefreshing()
                }
            })

        }, themeColor: UIColor.darkGray, refreshStyle: .replicatorCircle)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            STEPlayerManager.shared.stopAndClear()
        }
    }
    
    // MARK: - Handle Notification
    
    private func registerNotifications() {
        print("======== registerNotifications")
        
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.clientDidConnect(notification:)), name: .StringeeClientDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.clientDidDisconnect(notification:)), name: .StringeeClientDidDisconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleApplicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleAddContactTapped(notification:)), name: Notification.Name.STEDidTapAddContactNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleSendContactTapped(notification:)), name: Notification.Name.STEDidTapSendContactNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleSendMediaSourceTapped(notification:)), name: Notification.Name.STEDidTapSendMediaSourceNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleSendLocationTapped(notification:)), name: Notification.Name.STEDidTapSendLocationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEConversationViewController.handleSendStickerTapped(notification:)), name: Notification.Name.STEDidTapSendStickerNotification, object: nil)
    }
    
    @objc private func clientDidConnect(notification: Notification) {
        self.dataManager.fetchNewContent()
    }
    
    @objc private func clientDidDisconnect(notification: Notification) {
        
    }
    
    @objc private func handleApplicationDidBecomeActive(notification: Notification) {
        checkAndMarkMessageAsRead()
    }
    
    private func checkAndMarkMessageAsRead() {
        // Đánh dấu tất cả tin nhắn như đã đọc
        guard let conversation = self.conversation else {
            return
        }
        
        if (conversation.convLastSeq <= self.maxSeqMarked) {
            return
        }
        
        conversation.markAllMessagesAsSeen(completionHandler: { [weak self] (status, code, message) in
            if let self = self {
                if status && conversation.convLastSeq > self.maxSeqMarked {
                    self.maxSeqMarked = conversation.convLastSeq
                }
            }
        })
    }
    
    @objc private func handleSendContactTapped(notification: Notification) {
        if let contact = notification.userInfo?["object"] as? STEVCard, let cnContact = contact.contact {
            let contactMsg = StringeeContactMessage(cnContact: cnContact, metadata: nil)
            self.sendMessage(contactMsg)
        }
    }
    
    @objc private func handleAddContactTapped(notification: Notification) {
        if let success = notification.userInfo?["object"] as? Bool {
            let message = success ? "Thành công" : "Thất bại"
            STEShowToast(description: message, inView: self.view)
        }
    }
    
    @objc private func handleSendMediaSourceTapped(notification: Notification) {
        dismiss(animated: true, completion: nil)
        if let imageAsset = notification.userInfo?["imageAsset"] as? PHAsset {
            let imageManager = PHCachingImageManager()
            var shouldSendImageMsg = true
            imageManager.requestImage(for: imageAsset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) {[weak self] (image, infos) in
                guard let self = self, let image = image else { return }
                if shouldSendImageMsg {
                    // Request Image sẽ trả callback về nhiều lần
                    shouldSendImageMsg = false
                    let photoMsg = StringeePhotoMessage(image: image, metadata: nil)
                    self.sendMessage(photoMsg)
                }
            }
            
        } else if let videoUrl = notification.userInfo?["videoUrl"] as? URL {

            
            let url = URL(fileURLWithPath: videoUrl.relativePath)
            print("url \(url)")

            let videoMsg = StringeeVideoMessage(path: videoUrl, metadata: nil)
            self.sendMessage(videoMsg)

//            if let videoMsg = StringeeVideoMessage(referencePath: videoUrl.absoluteString, metadata: nil) {
//                self.sendMessage(videoMsg)
//            }
        }
    }
    
    @objc private func handleSendLocationTapped(notification: Notification) {
        if let latitude = notification.userInfo?["latitude"] as? Double, let longitude = notification.userInfo?["longitude"] as? Double {
            let locationMsg = StringeeLocationMessage(latitude: latitude, longitude: longitude, metadata: nil)
            self.sendMessage(locationMsg)
        }
    }
    
    @objc private func handleSendStickerTapped(notification: Notification) {
        if let userInfo = notification.userInfo as? [String: Any]  {
            let category = userInfo[STEStickerCategoryIdKey] as! String
            let name = userInfo[STEStickerNameKey] as! String
//            let url = userInfo[STEStickerUrlKey] as! String
//            let packageUrl = userInfo[STEStickerPackageUrlKey] as! String
            
            print("========= GỬI STICKER NÀO.....")
            
            let stickerMsg = StringeeStickerMessage(category: category, name: name, metadata: nil)
            self.sendMessage(stickerMsg)
        }
    }
    
}

// MARK: - UICollectionViewDataSource

extension STEConversationViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("=============== numberOfSections")
        return self.dataManager.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierFor(indexPath: indexPath), for: indexPath) as! STEBaseCollectionViewCell
        cell.delegate = self
        
        if let message = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeMessage {
            let shouldDisplayAvatar = self.shouldDisplayAvatar(message: message)
            let shouldDisplaySender = self.shouldDisplaySender(message: message)
            let shouldDisplayMsgStatus = self.shouldDisplayMsgStatus(message: message)
            cell.present(message: message, conv: conversation!, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
            
            // Mark message as read
            if UIApplication.shared.applicationState == .active {
                checkAndMarkMessageAsRead()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: STECollectionReusableViewHeaderView.identifier, for: indexPath) as! STECollectionReusableViewHeaderView
        
        if let message = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeMessage, shouldDisplayDateLabel(section: indexPath.section) {
            header.configure(timeStamp: message.created)
        }
        
        return header
    }
    
    func shouldDisplayDateLabel(section: Int) -> Bool {
        // Section đầu thì cần hiển thị
        if section <= 0 {
            return true
        }
        
        let currentIndexPath = IndexPath(item: 0, section: section)
        // Không lấy được message thì ko hiển thị
        guard let currentMsg = self.dataManager.objectAtIndexPath(indexPath: currentIndexPath) as? StringeeMessage else {
            return false
        }
        
        let previousSection = section - 1
        let previousIndexPath = IndexPath(item: 0, section: previousSection)
        // Không lấy được privious message thì ko hiển thị
        guard let priviousMsg = self.dataManager.objectAtIndexPath(indexPath: previousIndexPath) as? StringeeMessage else {
            return false
        }
        
        let currentDate = Date(timeIntervalSince1970: Double(currentMsg.created) / 1000.0)
        let priviousDate = Date(timeIntervalSince1970: Double(priviousMsg.created) / 1000.0)
        
        return !STECheckSameDate(date1: currentDate, date2: priviousDate)
    }
    
    func reuseIdentifierFor(indexPath: IndexPath) -> String {
        guard let message = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeMessage else {
            return STETextIncomingMessageCollectionViewCell.identifier
        }
        
        switch message.type {
        case .createGroup, .renameGroup, .notify:
            return STENotifyCollectionViewCell.identifier
        case .text, .link:
            if message.sender == StringeeImplement.shared.userId {
                return STETextOutgoingMessageCollectionViewCell.identifier
            } else {
                return STETextIncomingMessageCollectionViewCell.identifier
            }
        case .photo:
            if message.sender == StringeeImplement.shared.userId {
                return STEPhotoOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEPhotoIncomingMessageCollectionViewCell.identifier
            }
        case .location:
            if message.sender == StringeeImplement.shared.userId {
                return STELocationOutgoingMessageCollectionViewCell.identifier
            } else {
                return STELocationIncomingMessageCollectionViewCell.identifier
            }
            
        case .contact:
            if message.sender == StringeeImplement.shared.userId {
                return STEContactOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEContactIncomingMessageCollectionViewCell.identifier
            }
        case .video:
            if message.sender == StringeeImplement.shared.userId {
                return STEVideoOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEVideoIncomingMessageCollectionViewCell.identifier
            }
        case .file:
            if message.sender == StringeeImplement.shared.userId {
                return STEFileOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEFileIncomingMessageCollectionViewCell.identifier
            }
        case .audio:
            if message.sender == StringeeImplement.shared.userId {
                return STEAudioOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEAudioIncomingMessageCollectionViewCell.identifier
            }
        case .sticker:
            if message.sender == StringeeImplement.shared.userId {
                return STEStickerOutgoingMessageCollectionViewCell.identifier
            } else {
                return STEStickerIncomingMessageCollectionViewCell.identifier
            }
        default:
            if message.sender == StringeeImplement.shared.userId {
                return STETextOutgoingMessageCollectionViewCell.identifier
            } else {
                return STETextIncomingMessageCollectionViewCell.identifier
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension STEConversationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return shouldDisplayDateLabel(section: section) ? CGSize(width: SCREEN_WIDTH, height: 40) : .zero
    }
    
}

// MARK: - UICollectionViewDataSourcePrefetching

//extension STEConversationViewController: UICollectionViewDataSourcePrefetching {
//    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
//
//    }
//}

// MARK: - UICollectionViewDelegateFlowLayout

extension STEConversationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentInset = collectionView.ste_adjustedContentInset()
        let width = collectionView.bounds.size.width - contentInset.left - contentInset.right
        var height: CGFloat!
        
        if let message = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeMessage {
            let shouldDisplayAvatar = self.shouldDisplayAvatar(message: message)
            let shouldDisplaySender = self.shouldDisplaySender(message: message)
            let shouldDisplayMsgStatus = self.shouldDisplayMsgStatus(message: message)
            
            height = STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conversation!, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).height
        } else {
            height = 300
        }
        
        return CGSize(width: width, height: height)
    }
    
    
}

// MARK: - STEDataManager

extension STEConversationViewController: STEDataManagerDelegate {
    func willChangeContent(dataManager: STEDataManager) {
        print("willChangeContent")
    }
    
    func didChangeObject(dataManager: STEDataManager, object: AnyObject, atIndexPath: IndexPath, changeType: DataManagerChangeType, newIndexPath: IndexPath?) {
        //        print("didChangeObject \(changeType)")
        //        if self.collectionView.window == nil {
        //            return
        //        }
        
        let newIndex: Int
        if let newIndexPath = newIndexPath {
            newIndex = newIndexPath.section
        } else {
            newIndex = NSNotFound
        }
        
//        if let msg = object as? StringeeMessage {
//            print("didChangeObject \(changeType) ===  \(msg.created)")
//        }
        
        let changeObject = ChangeObject(type: changeType, currentIndex: atIndexPath.section, newIndex: newIndex)
        objectChanges.append(changeObject)
    }
    
    
    func didChangeContent(dataManager: STEDataManager, shouldReload: Bool, isLoadMore: Bool, shouldMoveToBottom: Bool) {
        print("didChangeContent")

        let objectChanges = self.objectChanges
        self.objectChanges.removeAll()
        
        if objectChanges.count == 0 {
            return
        }
        
        if self.collectionView == nil {
            print("'======== STEConversation = nil -> Ko làm gì")
            return
        }
        
        if self.collectionView.window == nil || shouldReload {
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            
            // Cần set contentOffset tới bottom ở đây
            let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize
            var contentOffset = self.bottomOffsetFor(contentSize: contentSize)
            contentOffset.x = self.collectionView.contentOffset.x
            self.collectionView.setContentOffset(contentOffset, animated: false)
            print("'======== STEConversation should reload")

            return
        }
        
        let priorContentHeight = self.collectionView.contentSize.height
        if isLoadMore {
            // Thay vì sử dụng performBatchUpdates cần sử dụng reloadData -> fix bug giật khi loadmore
            self.collectionView.headRefreshControl.endRefreshing()
            if !self.dataManager.hasOlderData {
                self.collectionView.headRefreshControl.isHidden = true
            }
            
            self.collectionView.reloadData()
            let contentHeightDifference = self.collectionView.collectionViewLayout.collectionViewContentSize.height - priorContentHeight
            // Thay vì setOffset thì chỉ cần thay đổi giá trị Y để quá trình moving tiếp tục diễn ra
            self.collectionView.contentOffset.y = self.collectionView.contentOffset.y + contentHeightDifference
            self.collectionView.flashScrollIndicators()
            return
        }
        
        // Ngăn chặn scroll to bottom
        let shouldScrollToBottom = self.shouldScrollToBottom()
        
        if let collectionView = self.collectionView {
            collectionView.performBatchUpdates({
                for object in objectChanges {
                    switch object.type {
                    case .delete:
                        collectionView.deleteSections(IndexSet(integer: object.currentIndex))
                    case .insert:
                        collectionView.insertSections(IndexSet(integer: object.currentIndex))
                    case .update:
                        collectionView.reloadSections(IndexSet(integer: object.currentIndex))
                    case .move:
                        collectionView.moveSection(object.currentIndex, toSection: object.newIndex)
                    }
                }
            }) { (finished) in
                
            }
        }
        
        // Cần set contentOffset tới bottom ở đây
        if shouldScrollToBottom {
            // Không thể lấy được contentSize từ collectionView vì nó ko còn đúng do update bên trên, nhưng có thể lấy từ layout của nó
            print("'======== STEConversation shouldScrollToBottom")
            let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize
            var contentOffset = self.bottomOffsetFor(contentSize: contentSize)
            contentOffset.x = self.collectionView.contentOffset.x
            
            if shouldMoveToBottom {
                // Sử dụng animation của uiview thay vì setContentOffset -> Fig bug giật nếu 2 lần update liên tiếp
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.contentOffset.y = contentOffset.y
                }
            } else {
                // Cho lần load message đầu tiên thì không cần animation
                self.collectionView.contentOffset.y = contentOffset.y
            }

        }
    }
    
}

// MARK: - STEMessageInputToolbarDelegate

extension STEConversationViewController: STEMessageInputToolbarDelegate {
    func didTapLeftAccessoryButton(leftButton: UIButton, messageInputToolbar: STEMessageInputToolbar) {
        print("didTapLeftAccessoryButton")
        if self.messageInputView.textInputView.isFirstResponder {
            self.messageInputView.textInputView.resignFirstResponder()
        }
        
        let attachAlert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        
        // Media source VC
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let mediaSourceVC = STEMediaSourceCollectionViewController.init(collectionViewLayout: flowLayout)
        
        attachAlert.addChild(mediaSourceVC)
        attachAlert.view.addSubview(mediaSourceVC.view)
        mediaSourceVC.didMove(toParent: attachAlert)
        
        mediaSourceVC.view.translatesAutoresizingMaskIntoConstraints = false
        attachAlert.view.translatesAutoresizingMaskIntoConstraints = false
        
        mediaSourceVC.view.topAnchor.constraint(equalTo: attachAlert.view.topAnchor, constant: 7).isActive = true
        mediaSourceVC.view.leadingAnchor.constraint(equalTo: attachAlert.view.leadingAnchor, constant: 7).isActive = true
        mediaSourceVC.view.trailingAnchor.constraint(equalTo: attachAlert.view.trailingAnchor, constant: -7).isActive = true
        mediaSourceVC.view.heightAnchor.constraint(equalToConstant: 180).isActive = true
        
        let contactAction = UIAlertAction(title: "Contact", style: .default) { (action) in
            let contactVC = STEContactTableViewController()
            let navi = UINavigationController(rootViewController: contactVC)
            navi.modalPresentationStyle = .fullScreen
            self.present(navi, animated: true, completion: nil)
        }
        
        let locationAction = UIAlertAction(title: "Location", style: .default) { (action) in
            let locationVC = STELocationViewController(isSendingMode: true)
            let navi = UINavigationController(rootViewController: locationVC)
            navi.modalPresentationStyle = .fullScreen
            self.present(navi, animated: true, completion: nil)
        }
        
        let fileAction = UIAlertAction(title: "File", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.sendFileType = true
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                picker.allowsEditing = true
                picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
                picker.modalPresentationStyle = .fullScreen
                self.present(picker, animated: true, completion: nil)
            }
        }
        
        let photoOrVideoAction = UIAlertAction(title: "Photo or Video", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.sendFileType = false
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                picker.allowsEditing = true
                picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
                picker.modalPresentationStyle = .fullScreen
                self.present(picker, animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        attachAlert.addAction(photoOrVideoAction)
        attachAlert.addAction(fileAction)
        attachAlert.addAction(locationAction)
        attachAlert.addAction(contactAction)
        attachAlert.addAction(cancelAction)
        
        self.present(attachAlert, animated: true, completion: nil)
    }
    
    func didTapRightAccessoryButton(rightButton: UIButton, messageInputToolbar: STEMessageInputToolbar) {
        print("didTapRightAccessoryButton")
        if var content = self.messageInputView.textInputView.text, content.count > 0 {
            // Gửi tin
            content = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let message = StringeeTextMessage(text: content, metadata: nil)
            self.sendMessage(message)
        } else {
            // Nếu đang show sticker thì ẩn đi
            if messageInputView.isStickerMode {
                self.dismissStickerView()
            }
            
            // Show Audio VC
            let alertVC = UIAlertController(title: "\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
            alertVC.addAction(cancelAction)
            
            let audioVC = STEAudioViewController()
            audioVC.delegate = self
            audioVC.view.translatesAutoresizingMaskIntoConstraints = false
            alertVC.view.translatesAutoresizingMaskIntoConstraints = false
            alertVC.addChild(audioVC)
            alertVC.view.addSubview(audioVC.view)
            audioVC.didMove(toParent: alertVC)
            
            audioVC.view.topAnchor.constraint(equalTo: alertVC.view.topAnchor, constant: 7).isActive = true
            audioVC.view.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 7).isActive = true
            audioVC.view.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -7).isActive = true
            audioVC.view.heightAnchor.constraint(equalToConstant: 168).isActive = true
            present(alertVC, animated: true, completion: nil)
        }
    }
}

// MARK: - STEMessageCellDelegate

extension STEConversationViewController: STEMessageCellDelegate {
    func didTapContactDetailButton(cell: STEBaseCollectionViewCell, contact: STEVCard) {
        let detailContactVC = STEDetailContactTableViewController(contact: contact, mode: .received)
        navigationController?.pushViewController(detailContactVC, animated: true)
    }
    
    func didTapFile(cell: STEBaseCollectionViewCell, fileUrl: URL, name: String) {
        
        self.interactionController = UIDocumentInteractionController(url: fileUrl)
        self.interactionController.delegate = self
        self.interactionController.name = name
        self.interactionController.presentPreview(animated: true)
    }
    
    func didTapImage(cell: STEBaseCollectionViewCell, image: UIImage) {
        let photo = AXPhoto(attributedTitle: nil, attributedDescription: nil, attributedCredit: nil, imageData: nil, image: image, url: nil)
        photos.removeAll()
        photos.append(photo)
        
        let dataSource = AXPhotosDataSource(photos: photos)
        
        let transitionInfo = AXTransitionInfo(interactiveDismissalEnabled: true, startingView: (cell as? STEPhotoCollectionViewCell)?.ivPhoto) { (photo, index) -> UIImageView? in
            guard let cell = cell as? STEPhotoCollectionViewCell else { return nil }
            
            // adjusting the reference view attached to our transition info to allow for contextual animation
            return cell.ivPhoto
        }
        
        let photosViewController = AXPhotosViewController(dataSource: dataSource, pagingConfig: nil, transitionInfo: transitionInfo)
        photosViewController.delegate = self
        photosViewController.modalPresentationStyle = .fullScreen
        self.present(photosViewController, animated: true)
    }

    func didTapPlayVideo(cell: STEBaseCollectionViewCell, url: URL) {
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.view.frame = self.view.bounds
        self.present(playerVC, animated: true) {
            playerVC.player?.play()
        }
    }
    
    func didTapLocation(cell: STEBaseCollectionViewCell, location: CLLocationCoordinate2D) {
        let locationVC = STELocationViewController(isSendingMode: false, destinationLocation: location)
        navigationController?.pushViewController(locationVC, animated: true)
    }
    
    func didBeginLongGesture(message: StringeeMessage) {
        let alert = UIAlertController(title: nil, message: "Bạn có chắc chắn muốn xoá tin nhắn.", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Xoá", style: .destructive) { (action) in
            message.delete(completionHandler: { (status, code, message) in
                print("======== Xoá \(String(describing: message))")
            })
        }
        let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func didTapLinkOrPhone(cell: STEBaseCollectionViewCell, content: Any, isLink: Bool) {
        print("didTapLinkOrPhone \(content) ==== \(isLink)")
        var url: URL?
        if let link = content as? URL, isLink {
            url = link
        } else if let phone = content as? String, phone.count > 0, !isLink, let phoneUrl = URL(string: "tel://\(phone)") {
            url = phoneUrl
        }
        
        guard let unwrapedUrl = url else {
            return
        }
        
        if UIApplication.shared.canOpenURL(unwrapedUrl) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(unwrapedUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(unwrapedUrl)
            }
        }
    }
}

// MARK: - STEAudioViewControllerDelegate

extension STEConversationViewController: STEAudioViewControllerDelegate {
    func audioControllerSendAudio(filePath: URL) {
        print("=========== Ghi am thanh cong \(filePath)")
        let audioMsg = StringeeAudioMessage(path: filePath, metadata: nil)
        self.sendMessage(audioMsg)
    }
}


// MARK: - InteractionControllerDelegate

extension STEConversationViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return navigationController!
    }
}


// MARK: - ScrollviewDelegate

extension STEConversationViewController {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        let offset: CGFloat = isFirstLoadMore ? 500 : STEOffsetToTriggerLoadMoreMessage
//        isFirstLoadMore = false
//        if self.dataManager.hasOlderData && scrollView.contentOffset.y < offset {
//            self.dataManager.loadOlderMessages(nil)
//        }
        
        checkLoadMoreData()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkLoadMoreData()

    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        checkLoadMoreData()
    }
    
    private func checkLoadMoreData() {
        if !self.collectionView.headRefreshControl.isRefresh && self.collectionView.contentOffset.y < 250 && self.dataManager.hasOlderData {
            self.dataManager.loadOlderMessages { (status) in
                if !status {
                    self.collectionView.headRefreshControl.endRefreshing()
                }
            }
            print("=========== Trigger headRefreshControl")
//            self.collectionView.headRefreshControl.beginRefreshing()
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension STEConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaUrl = info[.mediaURL] {
            let path = URL(fileURLWithPath: (mediaUrl as! URL).path)
            print("============ mediaUrl")
            if self.sendFileType {
                // Gửi dạng file
                let fileMsg = StringeeFileMessage(path: path, metadata: nil)
                self.sendMessage(fileMsg)
            } else {
                // Gửi dạng video
                let videoMsg = StringeeVideoMessage(path: path, metadata: nil)
                self.sendMessage(videoMsg)
            }
            
        } else if let referenceUrl = info[.referenceURL] as? URL {
            print("============ referenceUrl")
            let imageName = referenceUrl.lastPathComponent
            let temDicUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            let fileUrl = temDicUrl.appendingPathComponent(imageName)
            print("========== fileUrl: \(fileUrl.absoluteString)")
            if !FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
                // Nếu chưa tồn tại file thì mới copy
                if let image = info[.originalImage] as? UIImage, let imageData = image.pngData() {
                    try? imageData.write(to: fileUrl)
                }
            }
            
            
            if !FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
                let fileMsg = StringeeFileMessage(path: fileUrl, metadata: nil)
                self.sendMessage(fileMsg)
            }
        } else
            if let image = info[.originalImage] as? UIImage {
                print("============ image")
                let photoMsg = StringeePhotoMessage(image: image, metadata: nil)
                self.sendMessage(photoMsg)
            } else {
                return
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
        self.view.becomeFirstResponder()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        navigationController?.dismiss(animated: true, completion: nil)
        self.view.becomeFirstResponder()
    }
}

// MARK: - Present photos

extension STEConversationViewController: AXPhotosViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.forceTouchCapability == .available {
            if self.previewingContext == nil {
                self.previewingContext = self.registerForPreviewing(with: self, sourceView: self.collectionView)
            }
        } else if let previewingContext = self.previewingContext {
            self.unregisterForPreviewing(withContext: previewingContext)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.collectionView.indexPathForItem(at: location),
            let cell = self.collectionView.cellForItem(at: indexPath) as? STEPhotoCollectionViewCell else {
                return nil
        }
        let imageView = cell.ivPhoto
        
        previewingContext.sourceRect = self.collectionView.convert(imageView.frame, from: imageView.superview)
        
        let dataSource = AXPhotosDataSource(photos: photos, initialPhotoIndex: 0)
        let previewingPhotosViewController = AXPreviewingPhotosViewController(dataSource: dataSource)
        
        return previewingPhotosViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let previewingPhotosViewController = viewControllerToCommit as? AXPreviewingPhotosViewController {
            self.present(AXPhotosViewController(from: previewingPhotosViewController), animated: false)
        }
    }

}


// MARK: - Utils

extension STEConversationViewController {
    func shouldDisplayAvatar(message: StringeeMessage) -> Bool {
        if let conversation = self.conversation, !conversation.isGroup {
            return false
        }

        if message.sender == StringeeImplement.shared.userId {
            return false
        }
        return true
    }
    
    func shouldDisplaySender(message: StringeeMessage) -> Bool {
        if let conversation = self.conversation, !conversation.isGroup {
            return false
        }
        
        if message.sender == StringeeImplement.shared.userId {
            return false
        }
        return true
    }
    
    func shouldDisplayMsgStatus(message: StringeeMessage) -> Bool {
        if message.sender == StringeeImplement.shared.userId {
            return true
        }
        return false
    }
    
    private func sendMessage(_ message: StringeeMessage?) {
        guard let conversation = self.conversation, let message = message else { return }
        conversation.send(message, error: nil)
    }
}
