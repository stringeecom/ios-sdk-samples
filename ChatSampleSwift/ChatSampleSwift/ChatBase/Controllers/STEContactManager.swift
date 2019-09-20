//
//  SXContactManager.swift
//  stringeex
//
//  Created by HoangDuoc on 12/25/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation
import Contacts

let STELocalContactLoadedNotification = "STELocalContactLoadedNotification"

class STEContactManager {
    
    // MARK: - Init
    
    // Singleton
    static let shared = STEContactManager()
    
    // Local Contact
    var localKeys = Array<String>()
    var localSections = Dictionary<String, Array<Any>>()
    let allKeys = ["A" : "A",
                   "B" : "B",
                   "C" : "C",
                   "D" : "D",
                   "E" : "E",
                   "F" : "F",
                   "G" : "G",
                   "H" : "H",
                   "I" : "I",
                   "J" : "J",
                   "K" : "K",
                   "L" : "L",
                   "M" : "M",
                   "N" : "N",
                   "O" : "O",
                   "P" : "P",
                   "Q" : "Q",
                   "R" : "R",
                   "S" : "S",
                   "T" : "T",
                   "U" : "U",
                   "V" : "V",
                   "X" : "X",
                   "Y" : "Y",
                   "Z" : "Z",
                   "W" : "W"]
    var loadedLocalContact = false
    
    init() {
        
    }
    
    // MARK: - Local
    
    func getLocalContacts() {
        if loadedLocalContact {
            return
        }
        loadedLocalContact = !loadedLocalContact
        
        DispatchQueue.global(qos: .userInitiated).async {
            if #available(iOS 9.0, *) {
                let status = CNContactStore.authorizationStatus(for: .contacts)
                if status == .denied || status == .restricted {
                    self.handleNotAllowedContactPermission()
                    return
                }
                let contactStore = CNContactStore()
                contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) in
                    if !granted || error != nil {
                        print("Get Contacts failed iOS 9")
                        return
                    }
                    
                    let request = CNContactFetchRequest(keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
                    
                    do {
                        try contactStore.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                            let vcard = STEVCard(contact: contact)
                            self.addContact(contact: vcard, keys: &self.localKeys, sections: &self.localSections)
                            
                            // Bắn notifications
                            NotificationCenter.default.post(name: Notification.Name.STELocalContactLoadedNotification, object: nil)
                        })
                    } catch {
                        print("Get Contacts failed iOS 9")
                    }
                    
                })
            }
        }
    }
    
}

// MARK: - Utils

extension STEContactManager {
    func handleNotAllowedContactPermission() {

    }

    private func addContact(contact: STEVCard, keys: inout [String], sections: inout [String: [Any]]) {
        let name = contact.name
        var firstLetter: String!
        
        if name.count < 1 {
            firstLetter = "#"
        } else {
            firstLetter = String(name.prefix(1)).uppercased().ToAscii()
        }
        
        if allKeys[firstLetter] == nil && name.count >= 1 {
            firstLetter = "#"
        }
        
        var contacts: Array! = sections[firstLetter]
        if contacts == nil {
            contacts = [Any]()
        }
        contacts.append(contact)
        sections[firstLetter] = contacts
        
        keys = sections.keys.sorted()
        if let index = keys.firstIndex(of: "#") {
            keys.remove(at: index)
            keys.append("#")
        }
    }
}
