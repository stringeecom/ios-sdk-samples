//
//  AvatarControl.h
//  Biin
//
//  Created by Hoang Duoc on 2/23/17.
//  Copyright © 2017 Dau Ngoc Huy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AvatarControl : NSObject

+ (AvatarControl *) instance;
@property (nonatomic, strong) NSMutableDictionary * dic;
- (UIImage *) getAvatar: (NSString *) str;

@end
