//
//  STEStringExtension.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/24/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

struct HSV {
    var h: Double      // angle in degrees [0 - 360]
    var s: Double       // percent [0 - 1]
    var v: Double       // percent [0 - 1]
}

extension String {
    func toPresentativeImage() -> UIImage? {
        guard let letters = self.representativeLetters() else {
            return nil
        }
        
        return self.imageSnap(text: letters, color: UIColor.random, circular: false)
    }
    
    private func representativeLetters() -> String? {
        var returnStr = ""
        let words = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        if !words.isEmpty {
            if let firtWord = words.first {
                if firtWord.count != 0 {
                    returnStr.append(String(firtWord.prefix(1)))
                }
            }
            
            if words.count >= 2 {
                if let lastWord = words.last {
                    if lastWord.count != 0 {
                        returnStr.append(String(lastWord.prefix(1)))
                    }
                }
            }
            
            return returnStr.uppercased()
        }
        
        return nil
    }
    
    private func imageSnap(text: String?, color: UIColor, size: CGSize = CGSize(width: 120, height: 120), circular: Bool) -> UIImage? {

        let scale = Float(UIScreen.main.scale)

        UIGraphicsBeginImageContextWithOptions(size, false, CGFloat(scale))
        let context = UIGraphicsGetCurrentContext()
        if circular {
            let path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: size.width, height: size.height), transform: nil)
            context?.addPath(path)
            context?.clip()
        }

        // Fill
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // Text
        if let text = text {
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: size.width * 0.4)]

            let textSize = text.size(withAttributes: attributes)
            let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let rect = CGRect(x: bounds.size.width/2 - textSize.width/2, y: bounds.size.height/2 - textSize.height/2, width: textSize.width, height: textSize.height)

            text.draw(in: rect, withAttributes: attributes)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
    
    func ToAscii() -> String? {
        var standard = self.replacingOccurrences(of: "đ", with: "d")
        standard = standard.replacingOccurrences(of: "Đ", with: "D")
        let decode = standard.data(using: .ascii, allowLossyConversion: true)
        return String(data: decode!, encoding: String.Encoding.ascii)
    }
    
    func toDictionary() -> [String: Any]? {
        let data = Data(self.utf8)
        do {
            // make sure this JSON is in the format we expect
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return json
            }
        } catch {
            return nil
        }
        
        return nil
    }
}
