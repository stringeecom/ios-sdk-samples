//
//  STEMessagingUtilities.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/4/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

let STEMaxCellWidth: CGFloat = 215.0
let STEMaxCellHeight: CGFloat = 300.0

let STEMessageNoContentString = "No content"
let STEMessageNoNameString = "No name"

let STEUnreadMessageCountKey = "STEUnreadMessageCountKey"

// MARK: - Layout

// Kích thước của tin nhắn với font và text
func STETextPlainSize(text: String, font: UIFont, width: CGFloat = STEMaxCellWidth, height: CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
    return NSString(string: text).boundingRect(with: CGSize(width: width, height: height),
                                                         options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                         attributes: [NSAttributedString.Key.font: font],
                                                         context: nil).size
}

func STESizeFor(attributeString: NSAttributedString, width: CGFloat = STEMaxCellWidth, height: CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
//    let framesetter = CTFramesetterCreateWithAttributedString(attributeString)
//    let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize(width: width, height: height), nil)
//
//    return textSize
    
    let ts = NSTextStorage(attributedString: attributeString)
    
    let size = CGSize(width:width, height:height)
    
    let tc = NSTextContainer(size: size)
    tc.lineFragmentPadding = 0.0
    
    let lm = NSLayoutManager()
    lm.addTextContainer(tc)
    
    ts.addLayoutManager(lm)
    lm.glyphRange(forBoundingRect: CGRect(origin:CGPoint(x:0,y:0),size:size), in: tc)
    
    let rect = lm.usedRect(for: tc)
    return rect.size
}

func heightForString(_ str : NSAttributedString, width : CGFloat) -> CGFloat {
    let ts = NSTextStorage(attributedString: str)
    
    let size = CGSize(width:width, height:CGFloat.greatestFiniteMagnitude)
    
    let tc = NSTextContainer(size: size)
    tc.lineFragmentPadding = 0.0
    
    let lm = NSLayoutManager()
    lm.addTextContainer(tc)
    
    ts.addLayoutManager(lm)
    lm.glyphRange(forBoundingRect: CGRect(origin:CGPoint(x:0,y:0),size:size), in: tc)
    
    let rect = lm.usedRect(for: tc)
    return rect.size.height
}


func STEContraintImageSizeToCellSize(ratio: CGFloat) -> CGSize {
    let imageWidth = STEMaxCellWidth
    let imageHeight = imageWidth / ratio
    let imageSize = CGSize(width: imageWidth, height: imageHeight)
    let maxSize = CGSize(width: STEMaxCellWidth, height: STEMaxCellHeight)
    
    return STESizeProportionallyConstrainedToSize(nativeSize: imageSize, maxSize: maxSize)
}

// Tính size sẽ hiện thị content dựa trên content size và max size có thể
func STESizeProportionallyConstrainedToSize(nativeSize: CGSize, maxSize: CGSize) -> CGSize {
    if nativeSize.width < maxSize.width && nativeSize.height < maxSize.height {
        return nativeSize
    }

    let widthScale = maxSize.width / nativeSize.width
    let heightScale = maxSize.height / nativeSize.height
    
    if heightScale < widthScale {
        return CGSize(width: nativeSize.width * heightScale, height: maxSize.height)
    } else {
        return CGSize(width: maxSize.width, height: nativeSize.height * widthScale)
    }
}

// MARK: - Location

func STEPinPhotoFor(snapshot: MKMapSnapshotter.Snapshot, location: CLLocationCoordinate2D) -> UIImage? {
    let pinImage = UIImage(named: "PinLocation")
    
    // draw location
    let snapImage = snapshot.image
    UIGraphicsBeginImageContextWithOptions(snapImage.size, true, snapImage.scale)
    snapImage.draw(at: .zero)
    
    
    // draw pin
    let point = snapshot.point(for: location)
    pinImage?.draw(at: CGPoint(x: point.x - (pinImage?.size.width ?? 0) * 0.5, y: point.y - (pinImage?.size.height ?? 0)))
    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return finalImage
}

// MARK: - Common

func STEDegreeToRadius(degree: CGFloat) -> CGFloat {
    return (CGFloat.pi * degree) / 180
}

func STEStringToDisplayFrom(duration: TimeInterval) -> String {
    let ti = Int(duration)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    return String(format: "%02d:%02d", minutes, seconds)
}

func STECheckSameDate(date1: Date, date2: Date) -> Bool {
    let unitFlags = Set<Calendar.Component>([.era, .year, .month, .day])
    let date1Components = NSCalendar.current.dateComponents(unitFlags, from: date1)
    let date2Components = NSCalendar.current.dateComponents(unitFlags, from: date2)
    return (date1Components.day == date2Components.day &&
        date1Components.month == date2Components.month &&
        date1Components.year == date2Components.year &&
        date1Components.era == date2Components.era)
}

// Detect link, phone trong string
func STETextCheckingResults(text: String, checkingTypes: NSTextCheckingResult.CheckingType) -> [NSTextCheckingResult]? {
    if text.count <= 0 { return nil }
    
    do {
        let detector = try NSDataDetector(types: checkingTypes.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches
    } catch {
        return nil
    }
}

// MARK: - Conversations

func STETitleFor(conversation: StringeeConversation) -> String {
    
    // Ưu tiên lấy tên trước
    if conversation.name.count > 0 { return conversation.name }
    
    if (conversation.isGroup) {
        // là nhóm thì cần lấy tên các thành viên
        var title = ""
        
        if let participants = conversation.participants as? Set<StringeeIdentity> {
            for part in participants {
                if part.userId == StringeeImplement.shared.userId {
                    continue
                }
                
                let username = STEDisplayNameFor(part: part)
                if title.count > 0 {
                    title += (", " + username)
                } else {
                    title += username
                }
            }
            
            return title.count > 0 ? title : STEConstant.converastionDefaultTitle
        }
    } else {
        // lấy tên của thằng kia
        if let participants = conversation.participants as? Set<StringeeIdentity> {
            for part in participants {
                if part.userId == StringeeImplement.shared.userId {
                    continue
                }
                return STEDisplayNameFor(part: part)
            }
        }
        
        
    }
    
    
    return STEConstant.converastionDefaultTitle
}

func STEDisplayNameFor(part: StringeeIdentity) -> String {
    if let name = part.displayName, name.count > 0 {
        // Có tên thì lấy
        return name
    } else if let userId = part.userId, userId.count > 0 {
        // Không tên thì lấy userId
        return userId
    }
    
    return STEConstant.noName
}

func STEDisplayTextForLastMessage(conversation: StringeeConversation) -> String {
    switch conversation.lastMsg.type {
    case .audio:
        return "[Audio]"
    case .video:
        return "[Video]"
    case .file:
        return "[File]"
    case .contact:
        return "[Contact]"
    case .location:
        return "[Location]"
    case .photo:
        return "[Photo]"
    case .createGroup:
        return "Group đã được tạo"
    case .renameGroup:
        return "Group đã được đổi tên"
    case .text:
        return conversation.lastMsg.content ?? ""
    case .link:
        return conversation.lastMsg.content
    case .notify:
        return "Notification"
    case .sticker:
        return "[Sticker]"
    default:
        return ""
    }
}

