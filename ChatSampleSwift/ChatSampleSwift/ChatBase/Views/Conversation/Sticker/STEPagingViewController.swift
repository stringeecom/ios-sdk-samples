//
//  STEPagingViewController.swift
//  IVND
//
//  Created by HoangDuoc on 5/15/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import Parchment

let STEPagingViewControllerDefaultIcon = "PaintStickersIcon"

class STEPagingViewController: PagingViewController {
    
    lazy var packages = [STESTickerPackage]()
    
    lazy var stickerPackageViewController = STEStickerPackageViewController()
    
    override func loadView() {
        super.loadView()
        
        self.register(IconPagingCell.self, for: IconItem.self)
        self.menuItemSize = .fixed(width: 45, height: 45)
        self.textColor = UIColor(red: 0.51, green: 0.54, blue: 0.56, alpha: 1)
        self.selectedTextColor = UIColor(red: 0.14, green: 0.77, blue: 0.85, alpha: 1)
        self.indicatorColor = UIColor(red: 232, green: 235, blue: 240)
        self.menuBackgroundColor = STEMessageInputToolbarBackgroundColor
        self.view.backgroundColor = UIColor(red: 232, green: 235, blue: 240)
        self.dataSource = self
        self.select(pagingItem: IconItem(icon: STEPagingViewControllerDefaultIcon, index: 0))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(STEPagingViewController.handleAddStickerPackage(notification:)), name: Notification.Name.STEStickerManagerDidEditStickerNotification, object: nil)
        
        packages = STEStickerManager.shared.availablePackages != nil ? STEStickerManager.shared.availablePackages! : [STESTickerPackage]()
        reloadData()
        if packages.count > 0 {
            let package = packages.first!
            let imageName = STEStickerDefaultPrefix + STEStickerIconSuffix
            let localPath = URL(fileURLWithPath: STEStickerManager.shared.stickerDirectory).appendingPathComponent(package.id).appendingPathComponent(imageName).path
            self.select(pagingItem: IconItem(icon: localPath, index: 1))
        }
    }
    
    @objc private func handleAddStickerPackage(notification: Notification) {
        packages = STEStickerManager.shared.availablePackages != nil ? STEStickerManager.shared.availablePackages! : [STESTickerPackage]()
        reloadData()
    }
}

extension STEPagingViewController: PagingViewControllerDataSource {
  func pagingViewController(_: Parchment.PagingViewController, pagingItemAt index: Int) -> any Parchment.PagingItem {
    if index == 0 {
      return IconItem(icon: STEPagingViewControllerDefaultIcon, index: index) 
    }
    // Lấy về iconURL from local
    let package = packages[index - 1]
    let imageName = STEStickerDefaultPrefix + STEStickerIconSuffix
    let localPath = URL(fileURLWithPath: STEStickerManager.shared.stickerDirectory).appendingPathComponent(package.id).appendingPathComponent(imageName).path
    
    return IconItem(icon: localPath, index: index) 
  }
    
  func pagingViewController(_ pagingViewController: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        if index == 0 {
            // Sticker Packages
            return stickerPackageViewController
        }
        let package = packages[index - 1]
        return STEStickerViewController.init(package: package)
    }
    
    func numberOfViewControllers(in: PagingViewController) -> Int {
        return packages.count + 1
    }
    
}
