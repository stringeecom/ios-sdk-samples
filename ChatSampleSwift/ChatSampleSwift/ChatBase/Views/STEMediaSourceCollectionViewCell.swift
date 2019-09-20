//
//  STEMediaSourceCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/8/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import Photos

let btSendWidth: CGFloat = 60

class STEMediaSourceCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "STEMediaSourceCollectionViewCell"
    var representedAssetIdentifier: String?
    var asset: PHAsset?
    
    let ivMediaContent: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let ivType: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "video_icon"))
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        return imageView
    }()
    
    let lbTime: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        label.isHidden = true
        return label
    }()
    
    let effectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.isHidden = true
        effectView.alpha = 0
        return effectView
    }()
    
    let vibrantView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        let vibrancy = UIVibrancyEffect(blurEffect: blur)
        let effectView = UIVisualEffectView(effect: vibrancy)
        effectView.isHidden = true
        effectView.alpha = 0
        return effectView
    }()
    
    let btSend: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = btSendWidth / 2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.isHidden = true
        button.alpha = 0
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.asset = nil
        self.ivMediaContent.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        btSend.addTarget(self, action: #selector(STEMediaSourceCollectionViewCell.handleSendButtonTapped), for: .touchUpInside)
        
        addSubview(ivMediaContent)
        ivMediaContent.addSubview(ivType)
        ivMediaContent.addSubview(lbTime)
        ivMediaContent.addSubview(effectView)
        ivMediaContent.addSubview(vibrantView)
        addSubview(btSend)
        
        ivMediaContent.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        ivType.snp.makeConstraints { (make) in
            make.leading.equalTo(self).offset(5)
            make.bottom.equalTo(self).offset(-5)
        }
        
        lbTime.snp.makeConstraints { (make) in
            make.trailing.equalTo(self).offset(-5)
            make.bottom.equalTo(self).offset(-5)
        }
        
        effectView.snp.makeConstraints { (make) in
            make.edges.equalTo(ivMediaContent)
        }
        
        vibrantView.snp.makeConstraints { (make) in
            make.edges.equalTo(ivMediaContent)
        }
        
        btSend.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.equalTo(btSendWidth)
            make.height.equalTo(btSendWidth)
        }
    }
    
    func present(asset: PHAsset, image: UIImage?) {
        self.asset = asset
        self.ivMediaContent.image = image
        
        if self.asset?.mediaType == PHAssetMediaType.video {
            ivType.isHidden = false
            lbTime.isHidden = false
            lbTime.text = STEStringToDisplayFrom(duration: asset.duration)
        } else {
            ivType.isHidden = true
            lbTime.isHidden = true
        }
    }
    
    func showSendButton() {
        if btSend.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.effectView.isHidden = false
                self.vibrantView.isHidden = false
                self.btSend.isHidden = false
                self.effectView.alpha = 1
                self.vibrantView.alpha = 1
                self.btSend.alpha = 1
            }, completion: nil)
        } else {
            hideSendButton()
        }
    }
    
    func hideSendButton() {
        UIView.animate(withDuration: 0.3, animations: {
            self.effectView.alpha = 0
            self.vibrantView.alpha = 0
            self.btSend.alpha = 0
        }) { (success) in
            self.effectView.isHidden = true
            self.vibrantView.isHidden = true
            self.btSend.isHidden = true
        }
    }
    
    @objc private func handleSendButtonTapped() {
        hideSendButton()
        var userInfos = [String: Any]()
        if self.asset?.mediaType == PHAssetMediaType.video {
            if let asset = self.asset {
                DispatchQueue.global(qos: .userInitiated).async {
                    PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (avAsset, avAudioMix, infos) in
                        if let avUrl = (avAsset as? AVURLAsset)?.url {
                            userInfos["videoUrl"] = avUrl
                            
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name.STEDidTapSendMediaSourceNotification, object: self, userInfo: userInfos)
                            }
                        }
                        
                    }
                    
                }
            }
        } else {
            if let asset = self.asset {
                userInfos["imageAsset"] = asset
                NotificationCenter.default.post(name: Notification.Name.STEDidTapSendMediaSourceNotification, object: self, userInfo: userInfos)
            }
        }
        
    }
}
