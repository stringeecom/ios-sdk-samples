//
//  STEStickerManager.swift
//  IVND
//
//  Created by HoangDuoc on 5/16/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import SSZipArchive

let STEStickerBaseUrl = ""
let STEStickerListPackageUrl = ""
let STEAvailablePackageKey = "STEAvailablePackageKey" // key save các package có sẵn

let STEStickerDefaultPrefix = "default_sticker_"
let STEStickerIconSuffix = "icon.png"
let STEStickerCoverSuffix = "cover.png"

let STEStickerCategoryIdKey = "category"
let STEStickerNameKey = "name"
let STEStickerUrlKey = "url"
let STEStickerPackageUrlKey = "packageUrl"

class STEStickerManager {
    static let shared = STEStickerManager()
    
    lazy var availablePackages: [STESTickerPackage]? = {
        return STELoadCustomObjectsFromUserDefault(key: STEAvailablePackageKey)
    }()
    
    lazy var stickerDirectory: String = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("StringeeStickers")
        print("documentsDirectory \(documentsDirectory.path)")
        return documentsDirectory.path
    }()
    
    var allPackages: [STESTickerPackage]?
    
    init() {
        // Tạo thư mục chưa sticker nếu chưa có
        if !FileManager.default.fileExists(atPath: stickerDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: stickerDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("===== Tạo thư mục chứa Sticker ko thành công. \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAllPackages(completion: @escaping ([STESTickerPackage]?) -> Void) {
        // Lấy package về từ server
        getListStickerPackage { [unowned self] (packages) in
            guard let packages = packages, packages.count > 0 else {
                completion(nil)
                return
            }
            
            guard let availablePackages = self.availablePackages, availablePackages.count > 0 else {
                completion(packages)
                return
            }
            
            let returnPackages = packages.map({ (value) -> STESTickerPackage in
                let isAvailable = availablePackages.contains(where: { (availablePackage) -> Bool in
                    value.id == availablePackage.id
                })
                value.isAvailable = isAvailable
                return value
            })
            
            completion(returnPackages)
        }
    }
    
    func addPackage(package: STESTickerPackage, completion: @escaping (Bool) -> Void) {
        // Tải package về
        downloadPackage(package: package) { [unowned self] (status) in
            if !status {
                completion(false)
                return
            }
            
            // Lưu thông tin sticker mới vào
            if self.availablePackages == nil {
                self.availablePackages = [STESTickerPackage]()
            }
            self.availablePackages?.append(package)
            STESaveCustomObjectsToUserDefault(objects: self.availablePackages, key: STEAvailablePackageKey)
            
            // Thay đổi trạng thai của package
            package.isAvailable = true
            
            // Bắn noti thay đổi để cập nhật UI
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.STEStickerManagerDidEditStickerNotification, object: nil, userInfo: nil)
            }
            
            completion(true)
        }
    }
    
    func removePackage(package: STESTickerPackage, completion: @escaping (Bool) -> Void) {
        // Xoá thông tin package có sẵn đang lưu
        self.availablePackages?.removeAll(where: { (value) -> Bool in
            return value.id == package.id
        })
        STESaveCustomObjectsToUserDefault(objects: self.availablePackages, key: STEAvailablePackageKey)
        
        // Xoá file trong DB
        let filePath = URL(fileURLWithPath: stickerDirectory).appendingPathComponent(package.id).path
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            print("======= Không thể xoá Sticker \(error.localizedDescription)")
        }
        
        // Thay đổi trạng thai của package
        package.isAvailable = false
        
        // Bắn noti thay đổi để cập nhật UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.STEStickerManagerDidEditStickerNotification, object: nil, userInfo: nil)
        }
        
        completion(true)
    }
    
}

// MARK: - Network

extension STEStickerManager {
    
    // Lấy list từ server
    private func getListStickerPackage(completion: @escaping ([STESTickerPackage]?) -> Void) {
        guard let url = URL(string: STEStickerListPackageUrl) else { return }
        
        Alamofire.request(url, method: .get, parameters: nil, headers: nil).validate().responseJSON { (response) in
            guard response.result.isSuccess else {
                print("Get method error \(String(describing: response.result.error))")
                completion(nil)
                return
            }
            
            guard let value = response.result.value else {
                print("Get action error)")
                completion(nil)
                return
            }
            guard let packageDatas = JSON(value).array else {
                completion(nil)
                return
            }
//            print("Value \(packageDatas)")
            var packages = [STESTickerPackage]()
            for packageData in packageDatas {
                packages.append(STESTickerPackage(data: packageData))
            }
            completion(packages)
        }
        
    }
}

// MARK: - Database

extension STEStickerManager {
    private func downloadPackage(package: STESTickerPackage, completion: @escaping (Bool) -> Void) {
        // Lấy đường dẫn tạm thời cho file zip
        let fileUrl = self.getSaveFileLocalUrl(fileUrl: package.zipUrl)
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(package.zipUrl, to: destination).response {[unowned self] (defaultDownloadResponse) in
            if defaultDownloadResponse.error != nil {
                // Fail
                completion(false)
                return
            }
            
            // Unzip tới thư mục lưu sticker
            SSZipArchive.unzipFile(atPath: defaultDownloadResponse.destinationURL?.path ?? "", toDestination: self.stickerDirectory)
            
            // Xoá file zip
            do {
                try FileManager.default.removeItem(atPath: defaultDownloadResponse.destinationURL?.path ?? "")
            } catch {
                print("======= Không thể xoá file \(error.localizedDescription)")
            }
            
            completion(true)
        }
    }
    
    private func getSaveFileLocalUrl(fileUrl: String) -> URL {
        let temDicUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        let nameUrl = URL(string: fileUrl)
        let fileURL = temDicUrl.appendingPathComponent((nameUrl?.lastPathComponent)!)
        print(fileURL.absoluteString)
        return fileURL;
    }
}
