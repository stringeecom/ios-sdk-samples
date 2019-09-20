import UIKit
import Parchment

struct IconPagingCellViewModel {
    let image: UIImage?
    let selected: Bool
    let tintColor: UIColor
    let selectedTintColor: UIColor
    
    init(image: UIImage?, selected: Bool, options: PagingOptions) {
        self.image = image
        self.selected = selected
        self.tintColor = options.textColor
        self.selectedTintColor = options.selectedTextColor
    }
}

class IconPagingCell: PagingCell {
    
    fileprivate var viewModel: IconPagingCellViewModel?
    
    fileprivate lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(10)
            make.bottom.equalTo(contentView).offset(-10)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        if let item = pagingItem as? IconItem {
            
            let viewModel = IconPagingCellViewModel(
                image: item.image,
                selected: selected,
                options: options)
            
            imageView.image = viewModel.image
            
//                  if viewModel.selected {
//                    imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
//                    imageView.tintColor = viewModel.selectedTintColor
//                  } else {
//                    imageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
//                    imageView.tintColor = viewModel.tintColor
//                  }
            
            self.viewModel = viewModel
        }
    }
    
//    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
//        guard let viewModel = viewModel else { return }
//        if let attributes = layoutAttributes as? PagingCellLayoutAttributes {
//            //      let scale = (0.4 * attributes.progress) + 0.6
//            //      imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
////            imageView.tintColor = UIColor.interpolate(
////                from: viewModel.tintColor,
////                to: viewModel.selectedTintColor,
////                with: attributes.progress)
//        }
//    }
    
}
