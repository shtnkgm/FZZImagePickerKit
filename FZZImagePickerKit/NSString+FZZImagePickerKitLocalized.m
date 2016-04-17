//
//  NSString+Localized.m
//  FZZInfoKit
//
//  Created by Administrator on 2016/02/21.
//  Copyright © 2016年 Shota Nakagami. All rights reserved.
//

#import "NSString+FZZImagePickerKitLocalized.h"

@implementation NSString (FZZImagePickerKitLocalized)

- (instancetype)FZZImagePickerKitLocalized{
    NSString *localizedFileName = @"FZZImagePickerKitLocalizable";
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"FZZImagePickerKit" withExtension:@"bundle"];
    NSBundle *bundle;
    
    if (bundleURL) {
        bundle = [NSBundle bundleWithURL:bundleURL];
    } else {
        bundle = [NSBundle mainBundle];
    }
    
    NSString *localizedString = NSLocalizedStringFromTableInBundle(self,localizedFileName,bundle, nil);
    return localizedString;
}

@end
