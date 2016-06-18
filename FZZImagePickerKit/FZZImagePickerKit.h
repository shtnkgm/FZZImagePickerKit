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

@property (strong, nonatomic) UIImagePickerController *picker;
@property (assign, nonatomic) BOOL isSquare;
@property (assign, nonatomic) BOOL isFrontCamera;

@property (weak, nonatomic) id<FZZImagePickerKitDelegate> delegate;

- (void)openCameraWithIsSquare:(BOOL)isSquare
                 isFrontCamera:(BOOL)isFrontCamera
                    delegate:(id)delegate;

- (void)openAlbumWithIsSquare:(BOOL)isSquare
                   delegate:(id)delegate;

+ (void)openSettingApp;

+ (BOOL)canAccessToPhoto;
+ (BOOL)canAccessToCamera;

+ (void)showDialogForNoCamera;
+ (void)showDialogForCameraAccessibilityInViewController:(UIViewController *)viewController;
+ (void)showDialogForPhotoAccessibilityInViewController:(UIViewController *)viewController;

@end

@protocol FZZImagePickerKitDelegate <NSObject>

- (void)FZZImagePickerKit:(FZZImagePickerKit *)imagePickerKit
                    image:(UIImage *)image
                   status:(FZZImagePickerStatus)status;

@end
