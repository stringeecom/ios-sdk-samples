//
//  STEUtils.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/24/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation
import MBProgressHUD

// MARK: - Progress View

func STEShowProgress(description: String?, inView: UIView?) {
    DispatchQueue.main.async {
        let view = inView != nil ? inView : UIApplication.shared.keyWindow?.rootViewController?.view
        guard let targetView = view else {
            return
        }
        
        let progressView = MBProgressHUD.showAdded(to: targetView, animated: true)
        progressView.label.text = description
        progressView.isUserInteractionEnabled = true
        progressView.removeFromSuperViewOnHide = true
        progressView.hide(animated: true, afterDelay: 30.0)
    }
}

func STEHideProgress(ofView: UIView?) {
    DispatchQueue.main.async {
        let view = ofView != nil ? ofView : UIApplication.shared.keyWindow?.rootViewController?.view
        guard let targetView = view else {
            return
        }
        
        MBProgressHUD.hide(for: targetView, animated: true)
    }
}

func STEShowToast(description: String?, inView: UIView?) {
    DispatchQueue.main.async {
        let view = inView != nil ? inView : UIApplication.shared.keyWindow?.rootViewController?.view
        guard let targetView = view else {
            return
        }
        
        let progressView = MBProgressHUD.showAdded(to: targetView, animated: true)
        progressView.bezelView.backgroundColor = UIColor.black
        progressView.bezelView.style = MBProgressHUDBackgroundStyle.blur
        progressView.isOpaque = true
        progressView.mode = .text
        progressView.label.text = ""
        progressView.detailsLabel.text = description
        progressView.detailsLabel.font = UIFont.systemFont(ofSize: 15)
        progressView.detailsLabel.textColor = UIColor.white
        progressView.margin = 15.0
        progressView.removeFromSuperViewOnHide = true
        progressView.hide(animated: true, afterDelay: 1.5)
    }
}

struct STEUtils {
    static let relativeDateFormatter: DateFormatter = {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.dateStyle = .short
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter
    }()
    
    static let shortTimeFormatter: DateFormatter = {
        let shortTimeFormatter = DateFormatter()
        shortTimeFormatter.timeStyle = .short
        shortTimeFormatter.dateFormat = "HH:mm"
        return shortTimeFormatter
    }()
}

// MARK: - User Defaults

// Lưu 1 mảng object tới user default
func STESaveCustomObjectsToUserDefault<T: NSCoding>(objects: [T]?, key: String) {
    guard let objects = objects else {
        return
    }
    
    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: objects)
    
    let userDefaults = UserDefaults.standard
    userDefaults.set(encodedData, forKey: key)
    userDefaults.synchronize()
}

// Tải mảng object từ user default
func STELoadCustomObjectsFromUserDefault<T: NSCoding>(key: String) -> [T]? {
    guard let decoded  = UserDefaults.standard.object(forKey: key) as? Data else {
        return nil
    }
    return NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [T]
}
