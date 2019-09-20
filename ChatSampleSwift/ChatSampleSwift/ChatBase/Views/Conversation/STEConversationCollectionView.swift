//
//  STEConversationCollectionView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEConversationCollectionView: UICollectionView {

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        self.backgroundColor = .clear
        self.alwaysBounceVertical = true
        self.bounces = true
        self.keyboardDismissMode = .interactive
        registerReuseIdentifiers()
    }
    
    private func registerReuseIdentifiers() {
        // Text
        self.register(STETextIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STETextIncomingMessageCollectionViewCell.identifier)
        self.register(STETextOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STETextOutgoingMessageCollectionViewCell.identifier)
        
        // Notify
        self.register(STENotifyCollectionViewCell.self, forCellWithReuseIdentifier: STENotifyCollectionViewCell.identifier)
        
        // Photo
        self.register(STEPhotoIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEPhotoIncomingMessageCollectionViewCell.identifier)
        self.register(STEPhotoOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEPhotoOutgoingMessageCollectionViewCell.identifier)
        
        // Location
        self.register(STELocationOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STELocationOutgoingMessageCollectionViewCell.identifier)
        self.register(STELocationIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STELocationIncomingMessageCollectionViewCell.identifier)
        
        // Contact
        self.register(STEContactOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEContactOutgoingMessageCollectionViewCell.identifier)
        self.register(STEContactIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEContactIncomingMessageCollectionViewCell.identifier)
        
        // Video
        self.register(STEVideoOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEVideoOutgoingMessageCollectionViewCell.identifier)
        self.register(STEVideoIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEVideoIncomingMessageCollectionViewCell.identifier)
        
        // File
        self.register(STEFileOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEFileOutgoingMessageCollectionViewCell.identifier)
        self.register(STEFileIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEFileIncomingMessageCollectionViewCell.identifier)
        
        // Audio
        self.register(STEAudioOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEAudioOutgoingMessageCollectionViewCell.identifier)
        self.register(STEAudioIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEAudioIncomingMessageCollectionViewCell.identifier)
        
        // Sticker
        self.register(STEStickerOutgoingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEStickerOutgoingMessageCollectionViewCell.identifier)
        self.register(STEStickerIncomingMessageCollectionViewCell.self, forCellWithReuseIdentifier: STEStickerIncomingMessageCollectionViewCell.identifier)
        
        // Header
        self.register(STECollectionReusableViewHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: STECollectionReusableViewHeaderView.identifier)
    }

}
