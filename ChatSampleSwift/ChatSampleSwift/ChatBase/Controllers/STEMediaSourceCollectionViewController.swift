//
//  STEMediaSourceCollectionViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/8/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"

class STEMediaSourceCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var fetchResults: PHFetchResult<PHAsset>!
    lazy var imageManger = PHCachingImageManager()
    lazy var previousPreheatRect: CGRect = .zero
    let sourceViewHeight: CGFloat = 180
    lazy var thumbnailSize: CGSize = {
        return CGSize(width: sourceViewHeight * UIScreen.main.scale, height: sourceViewHeight * UIScreen.main.scale)
    }()
    
    var selectedCell: STEMediaSourceCollectionViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(STEMediaSourceCollectionViewCell.self, forCellWithReuseIdentifier: STEMediaSourceCollectionViewCell.identifier)
        
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        
        resetCachedAssets()
        checkPhotoLibraryPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resetCachedAssets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: STEMediaSourceCollectionViewCell.identifier, for: indexPath) as! STEMediaSourceCollectionViewCell
        if let asset = fetchResults?[indexPath.item] {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                cell.representedAssetIdentifier = asset.localIdentifier
                self.imageManger.requestImage(for: asset, targetSize: self.thumbnailSize, contentMode: .default, options: nil) { (image, infos) in
                    if cell.representedAssetIdentifier == asset.localIdentifier || cell.ivMediaContent.image == nil {
                        DispatchQueue.main.async {
                            cell.present(asset: asset, image: image)
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if let cell = collectionView.cellForItem(at: indexPath) as? STEMediaSourceCollectionViewCell {
            cell.showSendButton()
            selectedCell = cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? STEMediaSourceCollectionViewCell {
            cell.hideSendButton()
        }
    }
    
    // MARK: - UICollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: sourceViewHeight, height: sourceViewHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    
    
    
    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        selectedCell?.hideSendButton()
        selectedCell = nil
    }

    // MARK: - Setup
    
    private func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            setupPhotoLibrary()
            break
        case .denied:
            self.collectionView.reloadData()
            break
        case .restricted:
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    self.setupPhotoLibrary()
                    break
                case .denied:
                    self.collectionView.reloadData()
                    break
                case .restricted:
                    break
                case .notDetermined:
                    break
                }
            }
            break
        }
    }
    
    private func setupPhotoLibrary() {
        PHPhotoLibrary.shared().register(self)
        if fetchResults == nil {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            fetchResults = PHAsset.fetchAssets(with: options)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: - Utils
    
    private func indexPathsFromIndexSet(indexSet: IndexSet?) -> [IndexPath]? {
        guard let indexSet = indexSet else {
            return nil
        }
        
        let indexPaths = indexSet.map { IndexPath(item: $0, section: 0) }
        return indexPaths
    }
}

// MARK: - Asset Caching

extension STEMediaSourceCollectionViewController {
    private func resetCachedAssets() {
        previousPreheatRect = .zero
        imageManger.stopCachingImagesForAllAssets()
    }
    
    private func updateCachedAssets() {
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            return
        }
        
        // Chỉ update nếu view is visible
        if !self.isViewLoaded || self.view.window == nil {
            return
        }
        
        // Check phần rect để tiền xử lý bằng 1/2 của visible rect
        let visibleRect = CGRect(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y, width: collectionView.bounds.width, height: collectionView.bounds.height)
        let preheatRect = visibleRect.insetBy(dx: -0.5 * visibleRect.size.width, dy: 0)
        
        // Chỉ tiền xử lý khi phần rect thay đổi lớn hơn 1 lượng nhất định
        let delta = (preheatRect.midX - previousPreheatRect.midX).magnitude

        if delta < self.view.bounds.width / 3 {
            return
        }
        
        // Lấy về các asset tương ứng trong phần rect để thực hiện cache hoặc remove cache
        var addedAssets = [PHAsset]()
        var removedAssets = [PHAsset]()
        
        let changeRects = differencesBetweenRects(old: previousPreheatRect, new: preheatRect)
        let addRects = changeRects["added"] as! [CGRect]
        let removeRects = changeRects["removed"] as! [CGRect]
        
        for add in addRects {
            let indexPaths = self.collectionView.indexPathsForElementsIn(rect: add)
            for indexPath in indexPaths {
                let asset = fetchResults.object(at: indexPath.item)
                addedAssets.append(asset)
            }
        }
        
        for remove in removeRects {
            let indexPaths = self.collectionView.indexPathsForElementsIn(rect: remove)
            for indexPath in indexPaths {
                let asset = fetchResults.object(at: indexPath.item)
                removedAssets.append(asset)
            }
        }
        
        // Caching
        imageManger.startCachingImages(for: addedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManger.stopCachingImages(for: removedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(old: CGRect, new: CGRect) -> Dictionary<String, Any> {
        var returnValues = [String: Any]()
        let intersection = old.intersection(new)
        if intersection != .zero {
            var added = [CGRect]()
            var removed = [CGRect]()
            
            if (new.maxX > old.maxX) {
                let add = CGRect(x: old.maxX, y: new.origin.y, width: new.maxX - old.maxX, height: new.size.height)
                added.append(add)
            }
            
            if old.minX > new.minX {
                let add = CGRect(x: new.minX, y: new.origin.y, width: old.minX - new.minX, height: new.size.height)
                added.append(add)
            }
            
            if new.maxX < old.maxX {
                let remove = CGRect(x: new.maxX, y: new.origin.y, width: old.maxX - new.maxX, height: new.size.height)
                removed.append(remove)
            }
            
            if old.minX < new.minX {
                let remove = CGRect(x: old.minX, y: new.origin.y, width: new.minX - old.minX, height: new.size.height)
                removed.append(remove)
            }
            
            returnValues["added"] = added
            returnValues["removed"] = removed
        } else {
            returnValues["added"] = [new]
            returnValues["removed"] = [old]
        }

        return returnValues
    }
}


// MARK: - PHPhotoLibraryChangeObserver

extension STEMediaSourceCollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResults) else {
            return
        }
        
        DispatchQueue.main.async {
            self.fetchResults = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges {
                if self.collectionView == nil {
                    return
                }
                
                self.collectionView.performBatchUpdates({
                    // Update theo thứ tự: delete, insert, reload, move
                    if let removedIndexes = changes.removedIndexes, let removed = self.indexPathsFromIndexSet(indexSet: removedIndexes) {
                        self.collectionView.deleteItems(at: removed)
                    }
                    
                    if let insertedIndexes = changes.insertedIndexes, let inserted = self.indexPathsFromIndexSet(indexSet: insertedIndexes) {
                        self.collectionView.insertItems(at: inserted)
                    }
                    
                    if let changedIndexes = changes.changedIndexes, let changed = self.indexPathsFromIndexSet(indexSet: changedIndexes) {
                        self.collectionView.reloadItems(at: changed)
                    }
                    
                }, completion: { (success) in
                    changes.enumerateMoves({ (fromIndex, toIndex) in
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0), to: IndexPath(item: toIndex, section: 0))
                    })
                })
            } else {
                // Sự thay đổi lớn mà ko thể mô tả được hết với từng đối tượng => Load lại cả collectionView
                self.collectionView.reloadData()
            }
        }
    }
    
}
