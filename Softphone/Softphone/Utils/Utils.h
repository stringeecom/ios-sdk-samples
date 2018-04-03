//
//  Utils.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject

+ (UIColor *)colorWithHexString:(NSString *)hexString;

+ (void)showToastWithString:(NSString *)text withView:(UIView *)view;

+ (void)showProgressViewWithString:(NSString *)text inView:(UIView *)view;

+ (void)hideProgressViewInView:(UIView *)view;

+ (NSString *)getStrLetterWithName:(NSString *)text;

+ (UIImage *)getImageAvatarLetter:(CGRect)frame withString:(NSString *)text withColor:(UIColor *)color;

+ (void)delayCallback:(void(^)(void))callback forTotalSeconds:(double)delayInSeconds;

+ (NSString *)getCurrentSystemDate;

+ (NSString *)getCurrentSystemHour;

+ (BOOL)validateString:(NSString *)string withPattern:(NSString *)pattern;

+ (NSString *)convertUTF8ToAscii:(NSString *)unicode;

+ (NSString *)getPhoneForCall:(NSString *)phone;


+ (void)writeCustomObjToUserDefaults:(NSString *)keyName object:(id)object;

+ (id)readCustomObjFromUserDefaults:(NSString*)keyName;

@end
