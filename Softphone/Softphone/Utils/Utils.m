//
//  Utils.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "Utils.h"
#import <MBProgressHUD/MBProgressHUD.h>

typedef struct
{
    double h;       // angle in degrees [0 - 360]
    double s;       // percent [0 - 1]
    double v;       // percent [0 - 1]
} HSV;

@implementation Utils

// Set color với đầu vào HexString
+ (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (void)showToastWithString:(NSString *)text withView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView * targetView;
        if (view) {
            targetView = view;
        } else {
            targetView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        }
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:targetView animated:YES];
        hud.opaque = YES;
        hud.opacity = 0.75f;
        // Configure for text only and offset down
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"";
        hud.detailsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
        hud.detailsLabel.text = text;
        hud.margin = 15.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:1.5f];
    });
}

+ (void)showProgressViewWithString:(NSString *)text inView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView * targetView;
        
        if (view) {
            targetView = view;
        } else {
            UIViewController * rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            targetView = [rootVC view];
        }
        
        if (targetView) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:targetView animated:YES];
            hud.label.text = text;
            hud.userInteractionEnabled = YES;
            [hud removeFromSuperViewOnHide];
            [hud hideAnimated:YES afterDelay:30.0f];
        }
    });
}

+ (void)hideProgressViewInView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView * targetView;
        
        if (view) {
            targetView = view;
        } else {
            UIViewController * rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            targetView = [rootVC view];
        }
        
        if (targetView) {
            NSArray * targetSubviews = [targetView subviews];
            if (targetSubviews.count) {
                for (UIView * tempView in targetSubviews) {
                    if ([tempView isKindOfClass:MBProgressHUD.self]) {
                        MBProgressHUD * targetHud = (MBProgressHUD *) tempView;
                        [targetHud hideAnimated:YES];
                    }
                }
            }
        }
    });
}

+ (NSString *)getStrLetterWithName:(NSString *)text {
    
    NSMutableString *displayString = [NSMutableString stringWithString:@""];
    
    NSArray *words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([words count]) {
        NSString *firstWord = words[0];
        if ([firstWord length]) {
            [displayString appendString:[firstWord substringWithRange:NSMakeRange(0, 1)]];
        }
        
        if ([words count] >= 2) {
            NSString *lastWord = words[[words count] - 1];
            if ([lastWord length]) {
                [displayString appendString:[lastWord substringWithRange:NSMakeRange(0, 1)]];
            }
        }
    }
    return [displayString uppercaseString];
}

+ (UIImage *)getImageAvatarLetter:(CGRect)frame withString:(NSString *)text withColor:(UIColor *)color {
    //
    // Set up a temporary view to contain the text label
    //
    UIView *tempView = [[UIView alloc] initWithFrame:frame];
    
    UILabel *letterLabel = [[UILabel alloc] initWithFrame:frame];
    letterLabel.textAlignment = NSTextAlignmentCenter;
    letterLabel.backgroundColor = [UIColor clearColor];
    letterLabel.textColor = [UIColor whiteColor];
    letterLabel.adjustsFontSizeToFitWidth = YES;
    letterLabel.minimumScaleFactor = 8.0f / 65.0f;
    letterLabel.font = [UIFont systemFontOfSize:CGRectGetWidth(frame) * 0.48];;
    [tempView addSubview:letterLabel];
    
    letterLabel.text = text;
    
    //
    // Set the background color
    //
    //    tempView.backgroundColor = color ? color : [self randomColor:text];
    tempView.backgroundColor = [Utils randomGradientColor:text];
    //
    // Return an image instance of the temporary view
    //
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(UIGraphicsGetCurrentContext(),
                     [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:size.width].CGPath);
    CGContextTranslateCTM(context, -frame.origin.x, -frame.origin.y);
    CGContextClip(UIGraphicsGetCurrentContext());
    
    [tempView.layer renderInContext:context];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshot;
}

+ (UIColor *)randomGradientColor:(NSString *)inputString {
    float golden_ratio = 0.618033988749895f;
    float radius = 0.1f;
    float shift = 0.05f;
    float offset;
    if (inputString.length == 1) {
        offset = [inputString characterAtIndex:0];
        offset *= golden_ratio;
    }
    else if (inputString.length > 1) {
        offset = ([inputString characterAtIndex:0] + [inputString characterAtIndex:1]);
        offset *= golden_ratio;
    }
    else {
        offset = drand48()*100;
    }
    
    offset = fmodf((offset + golden_ratio), 1.0);
    offset = floor(offset/radius) * radius;
    offset += shift;
    
    HSV resultHSV1, resultHSV2;
    resultHSV1.h = offset;
    resultHSV1.s = 1.0;
    resultHSV1.v = 0.7;
    resultHSV2.h = resultHSV1.h;
    resultHSV2.s = resultHSV1.s;
    resultHSV2.v = resultHSV1.v + 0.15;
    UIColor *resultColor1;
    
    resultColor1 = [UIColor colorWithHue:resultHSV1.h saturation:resultHSV1.s brightness:resultHSV1.v alpha:0.75];
    
    return resultColor1;
}

+ (void)delayCallback:(void(^)(void))callback forTotalSeconds:(double)delayInSeconds {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

+ (NSString *)getCurrentSystemDate {
    NSString * currentTime = @"";
    
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"dd/MM/yyyy"];
    currentTime = [outputFormatter stringFromDate:now];
    
    return currentTime;
}

+ (NSString *)getCurrentSystemHour {
    NSString * currentTime = @"";
    
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm"];
    currentTime = [outputFormatter stringFromDate:now];
    
    return currentTime;
}

+ (void)writeCustomObjToUserDefaults:(NSString *)keyName object:(id)object {
    if (object) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        [defaults setObject:data forKey:keyName];
        [defaults synchronize];
    }
}

+ (id)readCustomObjFromUserDefaults:(NSString*)keyName {
    id object;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults dictionaryRepresentation].allKeys containsObject:keyName]) {
        NSData *data = [defaults objectForKey:keyName];
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    [defaults synchronize];
    return object;
}

+ (BOOL)validateString:(NSString *)string withPattern:(NSString *)pattern {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSRange textRange = NSMakeRange(0, string.length);
    NSRange matchRange = [regex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:textRange];
    
    BOOL didValidate = NO;
    
    if (matchRange.location != NSNotFound)
        didValidate = YES;
    
    return didValidate;
}

+ (NSString *)convertUTF8ToAscii:(NSString *)unicode {
    NSString *standard = [unicode stringByReplacingOccurrencesOfString:@"đ" withString:@"d"];
    standard = [standard stringByReplacingOccurrencesOfString:@"Đ" withString:@"D"];
    NSData *decode = [standard dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *ansi = [[NSString alloc] initWithData:decode encoding:NSASCIIStringEncoding];
    return ansi;
}

+ (NSString *)getPhoneForCall:(NSString *)phone {
    NSString *strResult = @"";
    NSString *prefixPhone = @"84";
    
    if (phone.length) {
        strResult = [phone stringByReplacingOccurrencesOfString:@"+" withString:@""];
        
        NSString *firstChar = [strResult substringToIndex:1];
        if ([firstChar isEqualToString:@"0"]) {
            strResult = [prefixPhone stringByAppendingString:[strResult substringFromIndex:1]];
        }
    }
    
    return strResult;
}




@end
