//
//  STEUITableView+Extension.swift
//  IVND
//
//  Created by HoangDuoc on 5/17/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

extension UITableViewCell {
    func tableView() -> UITableView? {
        var view = self.superview
        while view != nil && !(view?.isKind(of: UITableView.self) ?? false) {
            view = view?.superview
        }
        
        return view as? UITableView
    }
}
