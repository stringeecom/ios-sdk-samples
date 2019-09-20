//
//  STEStickerPackageViewController.swift
//  IVND
//
//  Created by HoangDuoc on 5/16/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEStickerPackageViewController: UIViewController {
    
    var tableView: UITableView!
    
    override func loadView() {
        super.loadView()
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(STEStickerPackageTableViewCell.self, forCellReuseIdentifier: STEStickerPackageTableViewCell.identifier)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        print("======== Package viewDidLoad")
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(STEStickerPackageViewController.handleAddSticker(notification:)), name: Notification.Name.STEStickerManagerDidEditStickerNotification, object: nil)
        
        STEShowProgress(description: nil, inView: view)
        STEStickerManager.shared.fetchAllPackages {[weak self] (packages) in
            guard let self = self else {
                return
            }
            STEHideProgress(ofView: self.view)
            
            STEStickerManager.shared.allPackages = packages
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("======== Package viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("======== Package viewWillDisappear")
    }
    
    @objc private func handleAddSticker(notification: Notification) {
        self.tableView.reloadData()
    }

}

extension STEStickerPackageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return STEStickerManager.shared.allPackages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: STEStickerPackageTableViewCell.identifier, for: indexPath) as! STEStickerPackageTableViewCell
        if let package = STEStickerManager.shared.allPackages?[indexPath.row] {
            cell.configure(package: package)
        }
        return cell
    }
}

extension STEStickerPackageViewController: UITableViewDelegate {

}
