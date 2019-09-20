//
//  STEConversationListViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit


class STEConversationListViewController: UITableViewController {
    
    typealias Class = STEConversationListViewController
    static let STEConversationCellDefaultHeight: CGFloat = 70.0
    let dataManager = STEDataManager(client: StringeeImplement.shared.stringeeClient, displayType: .multiObjectsInSection)
    
    var insertedRowIndexPaths = [IndexPath]()
    var updatedRowIndexPaths = [IndexPath]()
    var deletedRowIndexPaths = [IndexPath]()
    
    var selectedConversation: StringeeConversation?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.tableView.register(STEConversationTableViewCell.self, forCellReuseIdentifier: STEConversationTableViewCell.identifier)
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        NotificationCenter.default.addObserver(self, selector: #selector(clientDidConnect(notification:)), name: .StringeeClientDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clientDidDisconnect(notification:)), name: .StringeeClientDidDisconnect, object: nil)
        
        self.dataManager.delegate = self
        self.dataManager.start()
        
        // Cấu hình loadmore
        self.tableView.addInfiniteScroll { (tableview) in
            if self.dataManager.canLoadOlderContent() {
                self.dataManager.loadOlderConversations({ (status) in
                    DispatchQueue.main.async {
                        tableview.finishInfiniteScroll()
                    }
                })
            }
        }
        
        self.tableView.setShouldShowInfiniteScrollHandler { (tableview) -> Bool in
            return self.dataManager.canLoadOlderContent()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataManager.fetchNewContent()
        
        // Reload lại cell for conversation vừa present
        reloadCellForConversation(conversation: selectedConversation)
        selectedConversation = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Handle Connection Notification
    @objc func clientDidConnect(notification: Notification) {
        self.dataManager.fetchNewContent()
    }
    
    @objc func clientDidDisconnect(notification: Notification) {
        
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataManager.numberOfObjectsInSection()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: STEConversationTableViewCell.identifier, for: indexPath)

        if let cell = cell as? STEConversationPresenting {
            self.configureCell(cell: cell, indexPath: indexPath)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Class.STEConversationCellDefaultHeight
    }
    
    func configureCell(cell: STEConversationPresenting, indexPath: IndexPath) {
        if let conversation: StringeeConversation = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeConversation {
            cell.presentConversation(conversation: conversation)
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - TableView Delegate

extension STEConversationListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let conversation = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeConversation {
            selectedConversation = conversation
            let conversationVC = SampleConversationViewController.init(client: StringeeImplement.shared.stringeeClient, conversation: conversation)
            conversationVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(conversationVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        
        let alert = UIAlertController(title: nil, message: "Bạn có chắc muốn xoá cuộc hội thoại", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
        
        let okAction = UIAlertAction(title: "Ok", style: .destructive) { (action) in
            // Lấy về conversation
            guard let conversation = self.dataManager.objectAtIndexPath(indexPath: indexPath) as? StringeeConversation else {
                return
            }
            STEShowProgress(description: nil, inView: self.view)
            
            conversation.delete { [weak self] (status, code, message) in
                guard let self = self else { return }
                
                STEHideProgress(ofView: self.view)
                
                if !status {
                    switch code {
                    case -1:
                        STEShowToast(description: "Vui lòng kiểm tra kết nối", inView: self.view)
                        break
                    case -2:
                        STEShowToast(description: "Không tìm thấy thông tin", inView: self.view)
                        break
                    case -3:
                        STEShowToast(description: "Bạn cần rời nhóm trước", inView: self.view)
                        break
                    default:
                        //                    STEShowToast(description: "Không thành công", inView: self.view)
                        break
                    }
                }
            }
            
            
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - DataManager

extension STEConversationListViewController: STEDataManagerDelegate {
    func willChangeContent(dataManager: STEDataManager) {
        print("willChangeContent")
    }
    
    func didChangeObject(dataManager: STEDataManager, object: AnyObject, atIndexPath: IndexPath, changeType: DataManagerChangeType, newIndexPath: IndexPath?) {
        switch changeType {
        case .insert:
            self.insertedRowIndexPaths.append(atIndexPath)
        case .update:
            self.updatedRowIndexPaths.append(atIndexPath)
        case .delete:
            self.deletedRowIndexPaths.append(atIndexPath)
        case .move:
            self.deletedRowIndexPaths.append(atIndexPath)
            self.insertedRowIndexPaths.append(newIndexPath!)
        }
    }
    
    func didChangeContent(dataManager: STEDataManager, shouldReload: Bool, isLoadMore: Bool, shouldMoveToBottom: Bool) {
        // Cập nhật lại conversation mới
        if selectedConversation != nil {
            print("======= RESET - conversation")
            if let newConv = self.dataManager.findNewConversationFor(oldConv: self.selectedConversation) {
                self.selectedConversation = newConv
                self.selectedConversation?.markAllMessagesAsSeen(completionHandler: { (status, code, message) in

                })
            }
        }
        
//        if AppStateManager.shared.dynamicConv != nil {
//            print("======= RESET - dynamicConv")
//            if let newConv = self.dataManager.findNewConversationFor(oldConv: AppStateManager.shared.dynamicConv) {
//                newConv.markAllMessagesAsSeen(completionHandler: { (status, code, message) in
//                })
//            }
//        }

        print("didChangeContent")
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: self.deletedRowIndexPaths, with: .none)
        self.tableView.insertRows(at: self.insertedRowIndexPaths, with: .none)
        self.tableView.reloadRows(at: self.updatedRowIndexPaths, with: .none)
        print("sắp endUpdates")
        self.tableView.endUpdates()
        print("endUpdates")
        
        self.deletedRowIndexPaths.removeAll()
        self.insertedRowIndexPaths.removeAll()
        self.updatedRowIndexPaths.removeAll()
    }

}

// MARK: - Utils

extension STEConversationListViewController {
    func reloadCellForConversation(conversation: StringeeConversation?) {
//        guard let conversation = conversation, let indexPath = self.dataManager.indexPath(object: conversation) else {
//            return
//        }
        
//        self.tableView.reloadRows(at: [indexPath], with: .none)
        
        self.tableView.reloadData()
    }
}
