//
//  STEVCard.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

class STEVCard {
    var contact: CNContact?
    var contactImage: UIImage?
    var name = ""
    lazy var infos = [[String: Any]]()
    
    init(contact: CNContact) {
        self.contact = contact
        
        self.name = contact.givenName + " " + contact.familyName
        print("\(self.name)")
        
        if let imageData = contact.imageData {
            self.contactImage = UIImage(data: imageData)
        }
        
        for phoneNumber in contact.phoneNumbers {
            if let digits = phoneNumber.value.value(forKey: "digits"), let label = phoneNumber.label {
                let strLabel = CNLabeledValue<NSString>.localizedString(forLabel: label)
                infos.append([strLabel: digits])
            }
        }
        
        for email in contact.emailAddresses {
            if let label = email.label {
                let strLabel = CNLabeledValue<NSString>.localizedString(forLabel: label)
                let strEmail = email.value as String
                infos.append([strLabel: strEmail])
            }
        }
    }
}
