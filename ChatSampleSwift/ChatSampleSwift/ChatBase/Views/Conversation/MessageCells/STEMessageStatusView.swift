//
//  STEMessageStatusView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import SnapKit

let STEMessageStatusViewTopMargin: CGFloat = 5.0

let STEMessageStatusViewVerticalPadding: CGFloat = 2.0
let STEMessageStatusViewHorizontalPadding: CGFloat = 8.0

let STEMessageStatusViewLabelTimeColor: UIColor = .white
let STEMessageStatusViewLabelTimeFont: UIFont = UIFont.systemFont(ofSize: 11)
let STEMessageStatusViewBackgroundColor: UIColor = STEColor.darkGray

let STEMessageStatusViewCornerRadius: CGFloat = 10.0

let STEMessageStatusViewPendingImage = UIImage(named: "message_status_error")?.withRenderingMode(.alwaysTemplate)
let STEMessageStatusViewSendingImage = UIImage(named: "message_status_sending")?.withRenderingMode(.alwaysTemplate)
let STEMessageStatusViewSentImage = UIImage(named: "message_tick")?.withRenderingMode(.alwaysTemplate)
let STEMessageStatusViewDeliveredImage = UIImage(named: "message_double_tick")?.withRenderingMode(.alwaysTemplate)
let STEMessageStatusViewReadImage = UIImage(named: "message_double_tick")?.withRenderingMode(.alwaysTemplate)


class STEMessageStatusView: UIView {
    
    var ivStatusWidthContraint: Constraint? = nil
    var lbTimeRightToBorderContraint: Constraint? = nil

    
    let lbTime: UILabel = {
        let label = UILabel()
        label.font = STEMessageStatusViewLabelTimeFont
        label.textColor = STEMessageStatusViewLabelTimeColor
        label.text = "12:00 PM"
        label.numberOfLines = 1
        return label
    }()
    
    let ivStatus: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "message_double_tick")?.withRenderingMode(.alwaysTemplate))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = STEMessageStatusViewBackgroundColor
        
        addSubview(lbTime)
        addSubview(ivStatus)
    
        // Layout
        lbTime.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(STEMessageStatusViewHorizontalPadding)
            make.top.equalTo(self).offset(STEMessageStatusViewVerticalPadding)
            make.bottom.equalTo(self).offset(-STEMessageStatusViewVerticalPadding)
            make.right.equalTo(ivStatus.snp.left).offset(-STEMessageStatusViewHorizontalPadding / 2).priority(.high)
            lbTimeRightToBorderContraint = make.right.equalTo(self).offset(-STEMessageStatusViewHorizontalPadding).constraint
        }
        lbTimeRightToBorderContraint?.deactivate()
        
        ivStatus.snp.makeConstraints { (make) in
            make.right.equalTo(self).offset(-STEMessageStatusViewHorizontalPadding)
            make.top.equalTo(self).offset(STEMessageStatusViewVerticalPadding)
            make.bottom.equalTo(self).offset(-STEMessageStatusViewVerticalPadding)
//            ivStatusWidthContraint = make.width.equalTo(0).constraint
        }
//        ivStatusWidthContraint?.deactivate()
        
        update(status: .read, timeStamp: 0, tintColor: .white)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func displayMsgStatus(_ display: Bool) {
        if display {
//            ivStatusWidthContraint?.deactivate()
            lbTimeRightToBorderContraint?.deactivate()
        } else {
//            ivStatusWidthContraint?.activate()
            lbTimeRightToBorderContraint?.activate()
        }
        ivStatus.isHidden = !display
    }
    
    func update(status: StringeeMessageStatus, timeStamp: CLongLong, tintColor: UIColor) {
        let date = Date(timeIntervalSince1970: Double(timeStamp / 1000))
        lbTime.text = STEUtils.shortTimeFormatter.string(from: date)
        ivStatus.tintColor = tintColor
        
        switch status {
        case .pending:
            ivStatus.image = STEMessageStatusViewPendingImage
        case .sending:
            ivStatus.image = STEMessageStatusViewSendingImage
        case .sent:
            ivStatus.image = STEMessageStatusViewSentImage
        case .delivered:
            ivStatus.image = STEMessageStatusViewDeliveredImage
        case .read:
            ivStatus.image = STEMessageStatusViewReadImage
        }
    }
    
//    func update(status: StringeeMessageStatus, timeStamp: CLongLong, shouldChangeStatusColor: Bool = true) {
//        let date = Date(timeIntervalSince1970: Double(timeStamp / 1000))
//        lbTime.text = STEUtils.shortTimeFormatter.string(from: date)
//
//        switch status {
//        case .pending:
//            ivStatus.tintColor = shouldChangeStatusColor ? .red : .white
//            ivStatus.image = STEMessageStatusViewPendingImage
//        case .sending:
//            ivStatus.tintColor = shouldChangeStatusColor ? .darkGray : .white
//            ivStatus.image = STEMessageStatusViewSendingImage
//        case .sent:
//            ivStatus.tintColor = shouldChangeStatusColor ? .darkGray : .white
//            ivStatus.image = STEMessageStatusViewSentImage
//        case .delivered:
//            ivStatus.tintColor = shouldChangeStatusColor ? .darkGray : .white
//            ivStatus.image = STEMessageStatusViewDeliveredImage
//        case .read:
//            ivStatus.image = STEMessageStatusViewReadImage
//            ivStatus.tintColor = shouldChangeStatusColor ? STEColor.green : .white
//        }
//    }
    
}
