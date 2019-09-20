//
//  STECollectionReusableViewHeaderView.swift
//  IVND
//
//  Created by HoangDuoc on 5/15/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STECollectionReusableViewHeaderView: UICollectionReusableView {
    
    static let identifier = "STECollectionReusableViewHeaderView"
    
    let lbTime: UILabel = {
        let label = UILabel()
        label.text = "Time"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        return label
    }()
    
    let backview: UIView = {
        let view = UIView()
        view.backgroundColor = STEColor.darkGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {        
        addSubview(backview)
        backview.addSubview(lbTime)
        
        backview.snp.makeConstraints { (make) in
            make.center.equalTo(self)
        }
        
        lbTime.snp.makeConstraints { (make) in
            make.edges.equalTo(backview).inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }
    }
    
    func configure(timeStamp: CLongLong) {
        let time = Date(timeIntervalSince1970: Double(timeStamp) / 1000.0)
        lbTime.text = STEConversationTableViewCell.relativeDateFormatter.string(from: time)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backview.layer.cornerRadius = backview.frame.size.height * 0.5
        backview.clipsToBounds = true
    }
}
