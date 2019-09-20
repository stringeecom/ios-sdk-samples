//
//  STETickerPackage.swift
//  IVND
//
//  Created by HoangDuoc on 5/16/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation
import SwiftyJSON

class STESTickerPackage: NSObject, NSCoding {
    var id: String!
    var name: String!
    var numberOfStickers: Int
    var unzipUrl: String!
    var zipUrl: String!
    var iconUrl: String!
    var coverUrl: String!
    var isAvailable: Bool
    
    init(data: JSON) {
        id = data["id"].string ?? ""
        name = data["name"].string ?? ""
        numberOfStickers = data["number_of_stickers"].intValue
        unzipUrl = data["unzip_url"].string ?? ""
        zipUrl = data["zip_url"].string ?? ""
        iconUrl = data["icon_url"].string ?? ""
        coverUrl = data["cover_url"].string ?? ""
        isAvailable = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        id = aDecoder.decodeObject(forKey: "id") as? String ?? ""
        name = aDecoder.decodeObject(forKey: "name") as? String ?? ""
        numberOfStickers = Int(aDecoder.decodeInt64(forKey: "numberOfStickers"))
        unzipUrl = aDecoder.decodeObject(forKey: "unzipUrl") as? String ?? ""
        zipUrl = aDecoder.decodeObject(forKey: "zipUrl") as? String ?? ""
        iconUrl = aDecoder.decodeObject(forKey: "iconUrl") as? String ?? ""
        coverUrl = aDecoder.decodeObject(forKey: "coverUrl") as? String ?? ""
        isAvailable = aDecoder.decodeBool(forKey: "isAvailable")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(numberOfStickers, forKey: "numberOfStickers")
        aCoder.encode(unzipUrl, forKey: "unzipUrl")
        aCoder.encode(zipUrl, forKey: "zipUrl")
        aCoder.encode(iconUrl, forKey: "iconUrl")
        aCoder.encode(coverUrl, forKey: "coverUrl")
        aCoder.encode(isAvailable, forKey: "isAvailable")
    }
}
