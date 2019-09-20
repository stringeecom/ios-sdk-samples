//
//  STEDetailContactTableViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/4/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

enum STEDetailContactMode: String {
    case send = "Send"
    case received = "Add"
}

class STEDetailContactTableViewController: UITableViewController {
    
    let STEDetailContactCellIdentifier = "STEDetailContactCellIdentifier"
    var contact: STEVCard!
    var mode: STEDetailContactMode = .send
    
    init(contact: STEVCard, mode: STEDetailContactMode) {
        super.init(style: .plain)
        self.mode = mode
        self.contact = contact
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = self.contact.name.count > 0 ? self.contact.name : "Detail"
        if self.mode == .send {
            let optionItem = UIBarButtonItem(title: self.mode.rawValue, style: .plain, target: self, action: #selector(STEDetailContactTableViewController.optionTapped))
            navigationItem.rightBarButtonItem = optionItem
        }
        
        tableView.tableFooterView = UIView()
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contact.infos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: STEDetailContactCellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: STEDetailContactCellIdentifier)
            cell?.textLabel?.textColor = .blue
            cell?.detailTextLabel?.textColor = .darkGray
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
            cell?.selectionStyle = .none
        }
        let info = contact.infos[indexPath.row]
        
        cell?.textLabel?.text = info.keys.first
        cell?.detailTextLabel?.text = info.values.first as? String
        
        return cell!
    }
    
    // MARK: - Actions
    
    @objc private func optionTapped() {
        if self.mode == .send {
            let userInfo = ["object" : self.contact]
            NotificationCenter.default.post(name: Notification.Name.STEDidTapSendContactNotification, object: self, userInfo: userInfo as [AnyHashable : Any])
        } else {
            let sucess = addContact()
            let userInfo = ["object" : (sucess)]
            navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name: Notification.Name.STEDidTapAddContactNotification, object: self, userInfo: userInfo)
        }
    }
    
    private func addContact() -> Bool {
        guard let cnContact = self.contact.contact else { return false }
        
        let store = CNContactStore()
        let saveRequest = CNSaveRequest()
        let mutableContact = CNMutableContact()
        
        mutableContact.givenName = self.contact.name
        mutableContact.imageData = self.contact.contactImage?.pngData()
        mutableContact.phoneNumbers = cnContact.phoneNumbers
        mutableContact.emailAddresses = cnContact.emailAddresses
        
        saveRequest.add(mutableContact, toContainerWithIdentifier: nil)
        
        do {
            try store.execute(saveRequest)
            return true
        } catch {
            print("\(error.localizedDescription)")
            return false
        }
    }


}



