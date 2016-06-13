//
//  FZZImagePickerKit.h
//  FZZImagePickerKit
//
//  Created by Administrator on 2016/03/06.
//  Copyright © 2016年 Shota Nakagami. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol  FZZImagePickerKitDelegate;

typedef enum : NSInteger{
    FZZImagePickerStatusSuccess,
    FZZImagePickerStatusFailForNoCamera,
    FZZImagePickerStatusFail,
    FZZImagePickerStatusCancel,
    FZZImagePickerStatusCancelForALAssetsLibrary,
    FZZImagePickerStatusCancelForPhotoAccessibility,
    FZZImagePickerStatusCancelForCameraAccessibility
}FZZImagePickerStatus;

@interface FZZImagePickerKit : NSObject

@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, assign) BOOL isSquare;
@property (nonatomic, assign) BOOL isFrontCamera;

@property (nonatomic, weak) id<FZZImagePickerKitDelegate> delegate;

- (void)openCameraWithIsSquare:(BOOL)isSquare
                 isFrontCamera:(BOOL)isFrontCamera
                    delegate:(id)delegate;

- (void)openAlbumWithIsSquare:(BOOL)isSquare
                   delegate:(id)delegate;

+ (BOOL)canAccessToPhoto;
+ (BOOL)canAccessToCamera;

- (void)showDialogForPhotoAccessibility;
- (void)showDialogForCameraAccessibility;

@end

@protocol FZZImagePickerKitDelegate <NSObject>

- (void)FZZImagePickerKit:(FZZImagePickerKit *)imagePickerKit
                    image:(UIImage *)image
                   status:(FZZImagePickerStatus)status;

@end
