//
//  STEDataManager.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/21/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

enum DataManagerChangeType {
    case insert
    case delete
    case move
    case update
}

enum DataManagerDisplayType {
    case multiSections
    case multiObjectsInSection
}

enum DataManagerType {
    case conversation
    case message
}

protocol STEDataManagerDelegate: AnyObject {
    func willChangeContent(dataManager: STEDataManager)
    
    func didChangeObject(dataManager: STEDataManager, object: AnyObject, atIndexPath: IndexPath, changeType: DataManagerChangeType, newIndexPath: IndexPath?)
    
    func didChangeContent(dataManager: STEDataManager, shouldReload: Bool, isLoadMore: Bool, shouldMoveToBottom: Bool)
}

class STEDataManager {
    var client: StringeeClient!
    var conversation: StringeeConversation?
    weak var delegate: STEDataManagerDelegate?
    private var displayType: DataManagerDisplayType!
    private var managerType: DataManagerType!
    
    private var isSearching = false
    private var shouldGetLastObjects = true // cần lấy về conversation, message mới nhất từ server
    private var isLoadingData = false
    var hasOlderData = true // Có thể load thêm dữ liệu cũ hơn hay không
    private var hasUpdateNewestData = false // đã cập nhật dữ liệu mới từ server

    private var objectsSet: [AnyObject] = Array()
    private var searchingObjectsSet: [AnyObject] = Array()

    var messageCountShouldLoad: UInt = 50
    var conversationCountShouldLoad: UInt = 15
    
    let dataProcessingQueue = DispatchQueue(label: "STEDataProcessingQueue")
    
    init(client: StringeeClient, displayType: DataManagerDisplayType) {
        self.client = client
        self.displayType = displayType
        self.managerType = DataManagerType.conversation
        commonInit()
    }
    
    init(client: StringeeClient, conversation: StringeeConversation, displayType: DataManagerDisplayType) {
        self.client = client
        self.conversation = conversation
        self.displayType = displayType
        self.managerType = DataManagerType.message
        commonInit()
    }
    
    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleObjectsChangeNotification(notification:)), name: Notification.Name.StringeeClientObjectsDidChange, object: self.client)
    }
    
    deinit {
        self.client = nil
        self.conversation = nil
        self.objectsSet.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Query

extension STEDataManager {
    func count() -> Int {
        return self.managedObjects().count
    }
    
    func numberOfSections() -> Int {
        if self.displayType == DataManagerDisplayType.multiSections {
            return self.managedObjects().count
        }
        
        return 1
    }
    
    func numberOfObjectsInSection() -> Int {
        if self.displayType == DataManagerDisplayType.multiObjectsInSection {
            return self.managedObjects().count
        }
        
        return 1
    }
    
    func objectAtIndexPath(indexPath: IndexPath) -> AnyObject? {
        if self.displayType == DataManagerDisplayType.multiSections {
            return self.managedObjects()[indexPath.section]
        } else {
            return self.managedObjects()[indexPath.row]
        }
    }
    
    func indexPath(object: AnyObject) -> IndexPath? {
        guard let index = self.managedObjects().firstIndex(where: { (loopObject) -> Bool in
            return loopObject === object
        }) else {
            return nil
        }

        return self.indexPath(index: index)
    }
    
    private func indexPath(index: Int) -> IndexPath {
        if self.displayType == DataManagerDisplayType.multiSections {
            return IndexPath(row: 0, section: index)
        }
        return IndexPath(row: index, section: 0)
    }
    
    func findNewConversationFor(oldConv: StringeeConversation?) -> StringeeConversation? {
        guard let oldConv = oldConv, managerType == DataManagerType.conversation else {
            return nil
        }
        
        guard let indexPath = self.indexPathForChangeObject(object: oldConv) else {
            return nil
        }
        
        let index = self.displayType == DataManagerDisplayType.multiSections ? indexPath.section : indexPath.row
        return self.managedObjects()[safe: index] as? StringeeConversation
    }
    
    func fillConversationsFor(searchText: String) -> [StringeeConversation]? {
        if managerType != .conversation || self.objectsSet.count == 0 {
            return nil
        }
        
        var results = [StringeeConversation]()
        
        for conv in self.objectsSet {
            guard let conv = conv as? StringeeConversation else {
                continue
            }
            
            let convName = STETitleFor(conversation: conv)
            let lastMsgText = STEDisplayTextForLastMessage(conversation: conv)
            
            let unAccentedName = convName.folding(options: .diacriticInsensitive, locale: .current).capitalized
            let unLastMsgText = lastMsgText.folding(options: .diacriticInsensitive, locale: .current).capitalized
            let nameIsExist = unAccentedName.range(of: searchText, options: .caseInsensitive)
            let lastMsgTextIsExist = unLastMsgText.range(of: searchText, options: .caseInsensitive)
            
            if nameIsExist != nil || lastMsgTextIsExist != nil {
                results.append(conv)
            }
        }
        
        return results
    }
    
    func conversationWith(convId: String) -> StringeeConversation? {
        guard convId.count > 0, managerType == DataManagerType.conversation else {
            return nil
        }
        
        guard let conversations = self.objectsSet as? [StringeeConversation], conversations.count > 0 else {
            return nil
        }
        
        let targetConv = conversations.first { (loopConv) -> Bool in
            return loopConv.identifier == convId
        }
        
        return targetConv
    }
    
    func countTotalUnreadMessage() -> Int {
        guard let conversations = self.objectsSet as? [StringeeConversation], managerType == .conversation, self.objectsSet.count > 0 else {
            return 0
        }
        
        let total = conversations.reduce(0) { (result, conversation) -> Int in
            return result + Int(conversation.unread)
        }
        return total
    }
}

// MARK: - Loading Data Actions

extension STEDataManager {
    func start() {
        guard let client = self.client else {
            return
        }
        if self.managerType == DataManagerType.conversation {
            // Lấy về local conversation
            self.isLoadingData = true
          client.getLocalConversations(withCount: conversationCountShouldLoad, userId: client.userId) { [weak self] (status, code, message, conversations) in
                if let self = self {
                    self.handleInsert(conversations: conversations)
                    self.isLoadingData = false
                }
            }
        } else {
            guard let conversation = self.conversation else {
                return
            }
            self.isLoadingData = true
            conversation.getLocalMessages(withCount: messageCountShouldLoad) { [weak self] (status, code, message, messages) in
                if let self = self {
                    print("======= Local Count \(String(describing: messages?.count))")
                    self.handleInsert(messages: messages?.reversed(), isLoadMore: false, shouldMoveToBottom: false)
                    self.isLoadingData = false
                    
                    // Load message mới
                    self.loadNewerMessages()
                }
            }
        }
    }
    
    func fetchNewContent() {
        if self.managerType == .conversation {
            self.loadNewerConversations()
        } else {
            self.loadNewerMessages()
        }
    }
    
    func canLoadOlderContent() -> Bool {
        if !self.hasUpdateNewestData || !self.hasOlderData {
            return false
        }
        return true
    }
    
}

// MARK: - Handle Object Change Notifications

extension STEDataManager {
    @objc func handleObjectsChangeNotification(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any], let objectChanges = userInfo[StringeeClientObjectChangesUserInfoKey] as? [StringeeObjectChange] else {
            return
        }
        if objectChanges.isEmpty {
            return
        }
        
        var objects: [AnyObject] = Array()
        
        for objectChange in objectChanges {
            objects.append(objectChange.object as AnyObject)
        }
        
        guard let firstObject = objects.first, let firstObjectChange = objectChanges.first else {
            return
        }
        
        if managerType == .conversation && firstObject.isKind(of: StringeeConversation.self) {
            switch firstObjectChange.type {
            case .delete:
                handleDelete(conversations: (objects as? [StringeeConversation]))
            case .create:
                handleInsert(conversations: (objects as? [StringeeConversation]))
            case .update:
                handleUpdate(conversations: (objects as? [StringeeConversation]), shouldReload: false)
            }
        } else if managerType == .message && firstObject.isKind(of: StringeeMessage.self) {
            guard let conversation = conversation, let message = firstObject as? StringeeMessage else {
                return
            }
            
            if message.convId != conversation.identifier {
                return
            }
            
            switch firstObjectChange.type {
            case .delete:
                handleDelete(messages: (objects as? [StringeeMessage]))
            case .create:
                handleInsert(messages: (objects as? [StringeeMessage]), isLoadMore: false)
            case .update:
                handleUpdate(messages: (objects as? [StringeeMessage]), shouldDeleteOld: false)
            }
        } else if managerType == .conversation && firstObject.isKind(of: StringeeMessage.self) && firstObjectChange.type == .create {
            // Có tin nhắn mới cần load lại list conversation
            loadNewerConversations()
        }
        
    }
}


// MARK: - Conversation

extension STEDataManager {
    
    private func loadNewerConversations() {
        if self.isLoadingData || self.client == nil {
            return
        }
        self.isLoadingData = !self.isLoadingData
        
        if self.shouldGetLastObjects {
            // Lấy dữ liệu mới nhất từ server
            self.client.getLastConversations(withCount: self.conversationCountShouldLoad) {[weak self] (status, code, message, conversations) in
                if let self = self {
                    self.handleUpdate(conversations: conversations, shouldReload: true)
                    self.isLoadingData = !self.isLoadingData
                    self.shouldGetLastObjects = !status
                    self.hasUpdateNewestData = status
                }
            }
        } else {
            // Lấy dữ liệu mới hơn cái hiện có
//            guard let newestConv = self.objectsSet.first as? StringeeConversation else {
//                self.isLoadingData = !self.isLoadingData
//                return
//            }
            
            // Sửa cho trường hợp thằng khác tạo conversation với mình thì không thấy load được, vì đã return ở trên do thằng user này ko có conversation nào
            var lastUpdate: Int64 = 0
            if let newestConv = self.objectsSet.first as? StringeeConversation {
                lastUpdate = newestConv.lastUpdate
            }
            
            self.client.getConversationsAfter(lastUpdate, withCount: self.conversationCountShouldLoad) { [weak self] (status, code, message, conversations) in
                if let self = self {
                    self.handleUpdate(conversations: conversations, shouldReload: false)
                    self.isLoadingData = !self.isLoadingData
                }
            }
        }
    }
    
    func loadOlderConversations(_ completion: @escaping (Bool) -> ()) {
        if self.isLoadingData || self.client == nil {
            completion(false)
            return
        }
        
        guard let oldestConv:StringeeConversation = self.objectsSet.last as? StringeeConversation else {
            completion(false)
            return
        }

        self.isLoadingData = !self.isLoadingData
        self.client.getConversationsBefore(oldestConv.lastUpdate, withCount: self.conversationCountShouldLoad) { [weak self] (status, code, message, conversations) in
            if let self = self {
                self.handleUpdate(conversations: conversations, shouldReload: false)
                self.isLoadingData = !self.isLoadingData
                if let conversations = conversations {
                    if conversations.count < self.conversationCountShouldLoad {
                        self.hasOlderData = false
                    }
                }
            }
            completion(true)
        }
    }
    
    private func handleDelete(conversations: [StringeeConversation]?) {
        guard let conversations = conversations else {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        if conversations.isEmpty {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            
            var removedIndexes = IndexSet()
            for conversation in conversations {
                guard let deletedIndexPath = self.indexPathForChangeObject(object: conversation) else {
                    continue
                }
                let index = self.displayType == DataManagerDisplayType.multiSections ? deletedIndexPath.section : deletedIndexPath.row
                removedIndexes.insert(index)
                delegate.didChangeObject(dataManager: self, object: conversation, atIndexPath: deletedIndexPath, changeType: .delete, newIndexPath: nil)
            }
            
            if self.isSearching {
                self.searchingObjectsSet.removeAtIndexes(indexes: removedIndexes)
            } else {
                self.objectsSet.removeAtIndexes(indexes: removedIndexes)
            }
            
            delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: false, shouldMoveToBottom: true)
            
            self.postUnreadMessageChangeNotification()
        }
    }
    
    private func handleInsert(conversations: [StringeeConversation]?) {
        guard let conversations = conversations else {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        if conversations.isEmpty {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            
            for conversation in conversations {
                let index = self.indexForInsertConversationToArray(objects: self.managedObjects(), conversation: conversation)
                if self.isSearching {
                    self.searchingObjectsSet.insert(conversation, at: index)
                } else {
                    self.objectsSet.insert(conversation, at: index)
                }
                let insertedIndexPath = self.indexPath(index: index)
                delegate.didChangeObject(dataManager: self, object: conversation, atIndexPath: insertedIndexPath, changeType: .insert , newIndexPath: nil)
            }
            
            delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: false, shouldMoveToBottom: true)
            
            self.postUnreadMessageChangeNotification()
        }
    }
    
    private func handleUpdate(conversations: [StringeeConversation]?, shouldReload: Bool) {
        guard let conversations = conversations else {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        if conversations.isEmpty {
            self.postUnreadMessageChangeNotification()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            
            // Xoá conversation cũ
            let deletedConversations = shouldReload ? self.managedObjects() : conversations
            var removedIndexes = IndexSet()
            for conversation in deletedConversations {
                guard let deletedIndexPath = self.indexPathForChangeObject(object: conversation) else {
                    continue
                }
                let index = self.displayType == DataManagerDisplayType.multiSections ? deletedIndexPath.section : deletedIndexPath.row
                removedIndexes.insert(index)
                delegate.didChangeObject(dataManager: self, object: conversation, atIndexPath: deletedIndexPath, changeType: .delete, newIndexPath: nil)
            }
            
            if self.isSearching {
                self.searchingObjectsSet.removeAtIndexes(indexes: removedIndexes)
            } else {
                self.objectsSet.removeAtIndexes(indexes: removedIndexes)
            }
            
            // Insert vào vị trí mới
            for conversation in conversations {
                let index = self.indexForInsertConversationToArray(objects: self.managedObjects(), conversation: conversation)
                if self.isSearching {
                    self.searchingObjectsSet.insert(conversation, at: index)
                } else {
                    self.objectsSet.insert(conversation, at: index)
                }
                let insertedIndexPath = self.indexPath(index: index)
                delegate.didChangeObject(dataManager: self, object: conversation, atIndexPath: insertedIndexPath, changeType: .insert , newIndexPath: nil)
            }
            
            delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: false, shouldMoveToBottom: true)
            
            self.postUnreadMessageChangeNotification()
        }
    }
    
}

// MARK: - Message

extension STEDataManager {
    
    private func loadNewerMessages() {
        if self.isLoadingData || self.client == nil || self.conversation == nil {
            return
        }
        self.isLoadingData = !self.isLoadingData
        
        if self.shouldGetLastObjects {
            // Lấy dữ liệu mới nhất từ server
          self.conversation?.getLastMessages(withCount: messageCountShouldLoad, loadDeletedMessage: false, loadDeletedMessageContent: false, completionHandler: {[weak self] (status, code, message, messages) in
                if let self = self {
                    print("======= Lase Message Count \(String(describing: messages?.count))")
                    self.handleUpdate(messages: messages, shouldDeleteOld: true)
                    self.isLoadingData = !self.isLoadingData
                    self.shouldGetLastObjects = !status
                    self.hasUpdateNewestData = status
                    if let oldestMessage = messages?.last {
                        if oldestMessage.seq == 1 {
                            self.hasOlderData = false
                        }
                    }
                }
            })
            
        } else {
            // Lấy dữ liệu mới hơn cái hiện có
            guard let lastMsg = findLastSentMessage() else {
                self.isLoadingData = !self.isLoadingData
                return
            }

          self.conversation?.getMessagesAfter(lastMsg.seq, withCount: messageCountShouldLoad, loadDeletedMessage: false, loadDeletedMessageContent: false, completionHandler: { [weak self] (status, code, message, messages) in
                if let self = self {
//                    self.handleInsert(messages: messages, isLoadMore: false)
                    self.handleUpdate(messages: messages, shouldDeleteOld: false)
                    self.isLoadingData = !self.isLoadingData
                }
            })
        }
    }
    
    func loadOlderMessages (_ completion: ((Bool) -> ())?) {
        if self.isLoadingData || self.client == nil || self.conversation == nil {
            if let completion = completion {
                completion(false)
            }
            return
        }
        
        guard let oldestMsg = findOldSentMessage() else {
            if let completion = completion {
                completion(false)
            }
            return
        }
        
        self.isLoadingData = !self.isLoadingData
        
      self.conversation?.getMessagesBefore(oldestMsg.seq, withCount: messageCountShouldLoad, loadDeletedMessage: false, loadDeletedMessageContent: false, completionHandler: {[weak self] (status, code, message, messages) in
            if let self = self {
                self.handleInsert(messages: messages, isLoadMore: true)
                self.isLoadingData = !self.isLoadingData
                if status {
                    // nếu không load được tin nhắn thì kết thúc
                    if messages == nil || (messages?.count == 0) {
                        self.hasOlderData = false
                    }
                    
                    // Nếu tin nhắn cuối cùng có seq = 1 thì kết thúc
                    if let oldestMessage = messages?.last {
                        if oldestMessage.seq == 1 {
                            self.hasOlderData = false
                        }
                    }
                }
                
                if let completion = completion {
                    completion(true)
                }
            }
        })
    }
    
    // Tìm nhắn mới nhất được gửi thành công đến group
    func findLastSentMessage() -> StringeeMessage? {
        for message in self.objectsSet.reversed() {
            if let message = message as? StringeeMessage {
                if message.seq != 0 {
                    return message
                }
            }
        }
        
        return nil
    }
    
    // Tìm nhắn cũ nhất được gửi thành công đến group
    func findOldSentMessage() -> StringeeMessage? {
        for message in self.objectsSet {
            if let message = message as? StringeeMessage {
                if message.seq != 0 {
                    return message
                }
            }
        }
        
        return nil
    }
    
    private func handleInsert(messages: [StringeeMessage]?, isLoadMore: Bool, shouldMoveToBottom: Bool = true) {
        guard let messages = messages else {
            return
        }
        
        if messages.isEmpty {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            
            for message in messages {
                let index = self.indexForInsertMessageToArray(objects: self.objectsSet, message: message)
                self.objectsSet.insert(message, at: index)
                let insertedIndexPath = self.indexPath(index: index)
                delegate.didChangeObject(dataManager: self, object: message, atIndexPath: insertedIndexPath, changeType: .insert , newIndexPath: nil)
            }
            
            delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: isLoadMore, shouldMoveToBottom: shouldMoveToBottom)
        }
    }
    
    private func handleUpdate(messages: [StringeeMessage]?, shouldDeleteOld: Bool) {
        guard let messages = messages else {
            return
        }
        
        if messages.isEmpty {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            if shouldDeleteOld {
                // Xoá các phần tử cũ
                for message in self.objectsSet {
                    guard let deletedIndexPath = self.indexPathForChangeObject(object: message) else {
                        continue
                    }

                    delegate.didChangeObject(dataManager: self, object: message, atIndexPath: deletedIndexPath, changeType: .delete, newIndexPath: nil)
                }
                self.objectsSet.removeAll()
                
                // Thêm các phần tử mới
                for message in messages {
                    let index = self.indexForInsertMessageToArray(objects: self.objectsSet, message: message)
                    self.objectsSet.insert(message, at: index)
                    let insertedIndexPath = self.indexPath(index: index)
                    delegate.didChangeObject(dataManager: self, object: message, atIndexPath: insertedIndexPath, changeType: .insert , newIndexPath: nil)
                }
                
                delegate.didChangeContent(dataManager: self, shouldReload: true, isLoadMore: false, shouldMoveToBottom: true)
            } else {
                // Cập nhật trạng thái các tin nhắn
                for message in messages {
//                    guard let index = self.objectsSet.firstIndex(where: { (object) -> Bool in
//                        return object === message
//                    }) else {
//                        continue
//                    }
                    
                    if let index = self.objectsSet.firstIndex(where: { (object) -> Bool in
                        return object === message || (object as! StringeeMessage).identifier == message.identifier
                    }) {
                        // Nếu tìm thấy tin nhắn thì update
                        let updatedIndexPath = self.indexPath(index: index)
                        delegate.didChangeObject(dataManager: self, object: message, atIndexPath: updatedIndexPath, changeType: .update , newIndexPath: nil)
                    } else {
                        // Không tìm thấy tin nhắn thì insert
                        let index = self.indexForInsertMessageToArray(objects: self.objectsSet, message: message)
                        self.objectsSet.insert(message, at: index)
                        let insertedIndexPath = self.indexPath(index: index)
                        delegate.didChangeObject(dataManager: self, object: message, atIndexPath: insertedIndexPath, changeType: .insert , newIndexPath: nil)
                    }
                }

                delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: false, shouldMoveToBottom: true)
            }
            
        }
    }
    
    private func handleDelete(messages: [StringeeMessage]?) {
        guard let messages = messages else {
            return
        }
        
        if messages.isEmpty {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.delegate, let self = self else {
                return
            }
            
            delegate.willChangeContent(dataManager: self)
            
            var removedIndexes = IndexSet()
            for message in messages {
                guard let deletedIndexPath = self.indexPathForChangeObject(object: message) else {
                    continue
                }
                let index = self.displayType == DataManagerDisplayType.multiSections ? deletedIndexPath.section : deletedIndexPath.row
                removedIndexes.insert(index)
                delegate.didChangeObject(dataManager: self, object: message, atIndexPath: deletedIndexPath, changeType: .delete, newIndexPath: nil)
            }
            
            self.objectsSet.removeAtIndexes(indexes: removedIndexes)
            
            delegate.didChangeContent(dataManager: self, shouldReload: false, isLoadMore: false, shouldMoveToBottom: true)
        }
    }
}

// MARK: - Utils

extension STEDataManager {
    
    func managedObjects() -> [AnyObject] {
        return self.isSearching ? self.searchingObjectsSet : self.objectsSet
    }
    
    func indexPathForChangeObject(object: AnyObject) -> IndexPath? {
        let objects = self.isSearching ? self.searchingObjectsSet : self.objectsSet

        if self.managerType == DataManagerType.conversation {
            guard let conversation = object as? StringeeConversation else {
                return nil
            }
            
            guard let index = objects.firstIndex(where: { (loopConv) -> Bool in
                guard let loopConv = loopConv as? StringeeConversation else {
                    return false
                }
                return loopConv.identifier == conversation.identifier
            }) else {
                return nil
            }
            
            return self.indexPath(index: index)
        } else {
            guard let message = object as? StringeeMessage else {
                return nil
            }
            
            guard let index = objects.firstIndex(where: { (loopMsg) -> Bool in
                guard let loopMsg = loopMsg as? StringeeMessage else {
                    return false
                }
                return (loopMsg.identifier == message.identifier) || (loopMsg.localIdentifier == message.localIdentifier)
            }) else {
                    return nil
            }
            
            return self.indexPath(index: index)
        }
    }
    
    func indexForInsertConversationToArray(objects: [AnyObject], conversation: StringeeConversation) -> Int {
        var index = 0
        var topIndex = objects.count
        while index < topIndex {
            let midIndex = (index + topIndex) / 2
            let midConv = objects[midIndex] as! StringeeConversation
            if conversation.lastUpdate < midConv.lastUpdate {
                index = midIndex + 1
            } else {
                topIndex = midIndex
            }
        }
        
        return index
    }
    
    func indexForInsertMessageToArray(objects: [AnyObject], message: StringeeMessage) -> Int {
//        var index = 0
//        var topIndex = objects.count
//        while index < topIndex {
//            let midIndex = (index + topIndex) / 2
//            let midMsg = objects[midIndex] as! StringeeMessage
//            if message.created > midMsg.created {
//                index = midIndex + 1
//            } else {
//                topIndex = midIndex
//            }
//        }
//
//        return index
        
        var index = 0
        var topIndex = objects.count
        if message.seq == 0 {
            // Tin nhắn chưa được gửi đi => thêm vào đầu
            return topIndex
        }
        
        while index < topIndex {
            let midIndex = (index + topIndex) / 2
            let midMsg = objects[midIndex] as! StringeeMessage
            
            if message.created > midMsg.created {
                index = midIndex + 1
            } else {
                topIndex = midIndex
            }
            
        }
        
        return index
    }

    func postUnreadMessageChangeNotification() {
        let totalUnreadCount = countTotalUnreadMessage()
        let userInfo = [STEUnreadMessageCountKey: totalUnreadCount] as [String: Any]
        NotificationCenter.default.post(name: Notification.Name.STEUnreadMessageChangeNotification, object: nil, userInfo: userInfo)
    }
}
