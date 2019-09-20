
import UIKit

let STEStickerViewControllerMinimumLineSpacing: CGFloat = 10
let STEStickerViewControllerMinimumInteritemSpacing: CGFloat = 10
let STEStickerViewControllerNumberOfItemsOnLine: CGFloat = 5

class STEStickerViewController: UIViewController {
    
    var collectionView: UICollectionView!
    let lbTitle: UILabel = {
        let label = UILabel()
        label.text = "Stickers"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    var package: STESTickerPackage?
    
    init(package: STESTickerPackage?) {
        super.init(nibName: nil, bundle: nil)
        self.package = package
    }
    
    override func loadView() {
        super.loadView()
        
        let followLayout = UICollectionViewFlowLayout()
        followLayout.minimumLineSpacing = STEStickerViewControllerMinimumLineSpacing
        followLayout.minimumInteritemSpacing = STEStickerViewControllerMinimumInteritemSpacing
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: followLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(STEStickerCollectionViewCell.self, forCellWithReuseIdentifier: STEStickerCollectionViewCell.identifier)
        
        view.addSubview(lbTitle)
        view.addSubview(collectionView)
        
        lbTitle.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(5)
            make.left.equalTo(view).offset(5)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(lbTitle.snp.bottom).offset(2)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        // Data
        lbTitle.text = package?.name.count ?? 0 > 0 ? package?.name : "Stickers"
    }
    
    override func viewDidLoad() {
        print("======== Sticker viewDidLoad")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("======== Sticker viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("======== Sticker viewWillDisappear")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension STEStickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let packake = self.package, let id = packake.id, id.count > 0 {
            let stickerId = String(format: "%02d.png", indexPath.item + 1)
            let imageName = STEStickerDefaultPrefix + stickerId

//            let url = URL(string: baseStickerUrl)?.appendingPathComponent(imageName).absoluteString ?? ""
            
            let userInfos = [
                STEStickerCategoryIdKey: id,
                STEStickerNameKey: imageName
//                STEStickerUrlKey: url,
//                STEStickerPackageUrlKey: packageUrl
            ] as [String : Any]
            
            NotificationCenter.default.post(name: Notification.Name.STEDidTapSendStickerNotification, object: nil, userInfo: userInfos)
            
            print("1. CategoryId: \(id)")
            
            print("2. StickerId: \(stickerId)")
            
        }
    }
}

extension STEStickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let package = self.package {
            return package.numberOfStickers
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: STEStickerCollectionViewCell.identifier, for: indexPath) as! STEStickerCollectionViewCell
        if let packake = self.package, let id = packake.id, id.count > 0 {
            let index = String(format: "%02d.png", indexPath.item + 1)
            let imageName = STEStickerDefaultPrefix + index
            let imagePath = URL(fileURLWithPath: STEStickerManager.shared.stickerDirectory).appendingPathComponent(id).appendingPathComponent(imageName).path
            cell.configure(imagePath: imagePath)
        }
        
        return cell
    }
}

extension STEStickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth = collectionView.frame.size.width
        let inset = collectionView.contentInset
        let width = (maxWidth - inset.left - inset.right - (STEStickerViewControllerNumberOfItemsOnLine - 1) * STEStickerViewControllerMinimumInteritemSpacing) / STEStickerViewControllerNumberOfItemsOnLine
        let roundWidth = width.rounded(.down)
        return CGSize(width: roundWidth, height: roundWidth)
    }
}


