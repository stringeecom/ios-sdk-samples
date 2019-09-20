//
//  STESampleConversationListViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class SampleConversationListViewController: STEConversationListViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "Conversations"
        StringeeImplement.shared.connectToStringeeServer()
        AppStateManager.shared.convList = self
        
        let createItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(createTapped))
        navigationItem.rightBarButtonItem = createItem
    }
    
    @objc private func createTapped() {
        let alertVC = UIAlertController(title: "Tạo Conversation", message: "Nhập vào userId của user muốn tạo.", preferredStyle: .alert)
        
        let createAction = UIAlertAction(title: "Tạo", style: .default) { (action) in
            let tfUserId = alertVC.textFields![0] as UITextField
            if let userId = tfUserId.text, userId.count > 0 {
                self.createNewConversation(touser: userId)
            }
        }
        let cancelAction = UIAlertAction(title: "Huỷ", style: .default, handler: nil)
        
        alertVC.addTextField { (textField) in
            textField.placeholder = "userId"
        }
        
        alertVC.addAction(createAction)
        alertVC.addAction(cancelAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(touser: String) {
        let strIden = StringeeIdentity()
        strIden.userId = touser
        
        let options = StringeeConversationOption()
        options.isGroup = true
        options.distinctByParticipants = true
        
        StringeeImplement.shared.stringeeClient.createConversation(withName: "Demo Conversation", participants: [strIden], options: options) { (status, code, message, conversation) in
            if let conversation = conversation {
                DispatchQueue.main.async {
                    let conversationVC = SampleConversationViewController.init(client: StringeeImplement.shared.stringeeClient, conversation: conversation)
                    conversationVC.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(conversationVC, animated: true)
                }
            }
        }
    }
}
