//
//  STEStickerPackageTableViewCell.swift
//  IVND
//
//  Created by HoangDuoc on 5/16/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEStickerPackagePadding: CGFloat = 10
let STEStickerPackageContentMargin: CGFloat = 8

class STEStickerPackageTableViewCell: UITableViewCell {
    
    static let identifier = "STEStickerPackageTableViewCell"
    
    let lbTitle: UILabel = {
        let label = UILabel()
        label.text = "Stickers"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let lbCount: UILabel = {
        let label = UILabel()
        label.text = "30 Stickers"
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    }()

    let btAdd: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = STEColor.blue.cgColor
        button.setTitleColor(STEColor.blue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.backgroundColor = .clear
        button.setTitle("ADD", for: .normal)
        let defaultContentInset = button.contentEdgeInsets
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        return button
    }()
    
    let ivBanner: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    var package: STESTickerPackage?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        package = nil
    }
    
    private func commonInit() {
        addSubview(lbTitle)
        addSubview(lbCount)
        addSubview(btAdd)
        addSubview(ivBanner)

        lbTitle.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(STEStickerPackagePadding)
            make.left.equalTo(self).offset(STEStickerPackagePadding)
        }
        
        lbCount.snp.makeConstraints { (make) in
            make.top.equalTo(lbTitle.snp.bottom).offset(STEStickerPackagePadding / 3)
            make.left.equalTo(self).offset(STEStickerPackagePadding)
        }
        
        btAdd.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(STEStickerPackagePadding)
            make.right.equalTo(self).offset(-STEStickerPackagePadding)
        }
        
        ivBanner.snp.makeConstraints { (make) in
            make.top.equalTo(lbCount.snp.bottom).offset(STEStickerPackagePadding)
            make.left.equalTo(self).offset(STEStickerPackagePadding)
            make.right.equalTo(self).offset(-STEStickerPackagePadding)
            make.bottom.equalTo(self).offset(-STEStickerPackagePadding)
            make.height.equalTo(ivBanner.snp.width).multipliedBy(0.2)
        }
        
        backgroundColor = .clear
        selectionStyle = .none
        btAdd.addTarget(self, action: #selector(STEStickerPackageTableViewCell.handleAddButtonTapped), for: .touchUpInside)
    }
    
    func configure(package: STESTickerPackage) {
        self.package = package
        lbTitle.text = package.name.count > 0 ? package.name : "Stickers"
        lbCount.text = "\(package.numberOfStickers) " + "stickers"
        
        if let url = URL(string: package.coverUrl) {
            ivBanner.sd_setImage(with: url, placeholderImage: nil)
        }
        
        setupAddButton(isAvailable: package.isAvailable)
    }
    
    private func setupAddButton(isAvailable: Bool) {
        let color: UIColor = isAvailable ? .red : STEColor.blue
        let title = isAvailable ? "REMOVE" : "ADD"
        btAdd.layer.borderColor = color.cgColor
        btAdd.setTitleColor(color, for: .normal)
        btAdd.setTitle(title, for: .normal)
    }
    
    @objc private func handleAddButtonTapped() {
        print("handleAddButtonTapped")
        guard let package = package else {
            return
        }
        let tableView = self.tableView()
        if tableView != nil {
            STEShowProgress(description: nil, inView: tableView)
        }
        
        if package.isAvailable {
            // Có sẵn thì sẽ xoá
            STEStickerManager.shared.removePackage(package: package) { (status) in
                STEHideProgress(ofView: tableView)
            }
        } else {
            // Chưa có thì sẽ tải
            STEStickerManager.shared.addPackage(package: package) { (status) in
                STEHideProgress(ofView: tableView)
            }
        }
    }
}
