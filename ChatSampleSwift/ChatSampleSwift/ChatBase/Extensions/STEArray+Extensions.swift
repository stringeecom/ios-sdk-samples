//
//  STEArrayExtension.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/24/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

extension Array {
    mutating func removeAtIndexes(indexes: IndexSet) {
        var i:Index? = indexes.last
        while i != nil {
            self.remove(at: i!)
            i = indexes.integerLessThan(i!)
        }
    }
}

// MARK: - Subscript

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
