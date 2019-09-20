//
//  STECollectionView+Extensions.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

extension UICollectionView {
    func ste_adjustedContentInset() -> UIEdgeInsets {
        if #available(iOS 11, *) {
            return self.adjustedContentInset
        } else {
            return self.contentInset
        }
    }
    
    func indexPathsForElementsIn(rect: CGRect) -> [IndexPath] {
        var indexPaths = [IndexPath]()

        if let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect) {
            for attribute in allLayoutAttributes {
                indexPaths.append(attribute.indexPath)
            }
        }

        return indexPaths
    }
}
