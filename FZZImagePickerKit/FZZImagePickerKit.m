//
//  FZZImagePickerKit.m
//  FZZImagePickerKit
//
//  Created by Administrator on 2016/03/06.
//  Copyright © 2016年 Shota Nakagami. All rights reserved.
//

#import "FZZImagePickerKit.h"
#import "SVProgressHUD.h"
#import "NSString+FZZImagePickerKitLocalized.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface FZZImagePickerKit()
<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property (nonatomic,copy) NSString *appName;

@end

@implementation FZZImagePickerKit

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        _isSquare = NO;
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleDisplayName"];
    }
    return self;
}

- (void)openCamera{
    //カメラ有無チェック
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [SVProgressHUD showErrorWithStatus:[@"This device has no camera." localized]];
        [_delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusFailForNoCamera];
        return;
    }
    
    //アクセス権チェック
    if(![FZZImagePickerKit canAccessToCamera]){
        [self showDialogForCameraAccessibility];
        [_delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusCancelForCameraAccessibility];
        return;
    }
    
    [self openImagePicker:UIImagePickerControllerSourceTypeCamera];
}

- (void)openAlbum{
    //アクセス権チェック
    if(![FZZImagePickerKit canAccessToPhoto]){
        [self showDialogForPhotoAccessibility];
        [_delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusCancelForPhotoAccessibility];
        return;
    }
    
    [self openImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    
}

- (void)showDialogForCameraAccessibility{
    NSString *title = [NSString stringWithFormat:[@"%@ does not have access to your camera." localized],_appName];
    NSString *message = [NSString stringWithFormat:@"%@%@",
                         [@"Please enable access to your camera in " localized],
                         [NSString stringWithFormat:[@"iOS Settings > %@ > Privacy > Camera" localized],_appName]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
        [alertController addAction:defaultAction];
    
    UIAlertAction* settingAction = [UIAlertAction actionWithTitle:[@"Open Settings" localized] style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                              [[UIApplication sharedApplication] openURL:url];
                                                          }];
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]){
        [alertController addAction:settingAction];
    }
    
    [(UIViewController *)_delegate presentViewController:alertController
                                                animated:YES
                                              completion:nil];
}

- (void)showDialogForPhotoAccessibility{
    NSString *title = [NSString stringWithFormat:[@"%@ does not have access to your photos." localized],_appName];
    NSString *message = [NSString stringWithFormat:@"%@%@",
                         [@"Please enable access to your photos in " localized],
                         [NSString stringWithFormat:[@"iOS Settings > %@ > Privacy > Photos" localized],_appName]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alertController addAction:defaultAction];
    
    UIAlertAction* settingAction = [UIAlertAction actionWithTitle:[@"Open Settings" localized] style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                              [[UIApplication sharedApplication] openURL:url];
                                                          }];
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]){
        [alertController addAction:settingAction];
    }
    
    [(UIViewController *)_delegate presentViewController:alertController
                                                animated:YES
                                              completion:nil];
}

- (void)openImagePicker:(int)sourceType {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    //イメージピッカーの設定
    _picker = [UIImagePickerController new];
    _picker.delegate = self;
    _picker.allowsEditing = _isSquare;
    _picker.sourceType = sourceType;//ソースタイプを選択
    
    //イメージピッカーを表示する
    [(UIViewController *)_delegate presentViewController:_picker animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [_delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusCancel];;
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    
    __weak typeof(self) weakSelf = self;
    
    if(!originalImage){
        //originalImageが取得できなかった場合
        
        [self loadImageFromAssertByUrl:[info objectForKey:UIImagePickerControllerReferenceURL]
                            completion:^(UIImage* image){
                                image = [weakSelf dontRotate:image];
                                
                                if(weakSelf.isSquare){
                                    CGRect originalRect;
                                    [info[UIImagePickerControllerCropRect] getValue:&originalRect];
                                    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], originalRect);
                                    image = [UIImage imageWithCGImage:imageRef];
                                    CGImageRelease(imageRef);
                                }
                                
                                //デリゲート通知
                                [weakSelf.delegate FZZImagePickerKit:weakSelf image:image status:FZZImagePickerStatusSuccess];
                            }];
    }else{
        //originalImageが取得できた場合
        
        originalImage = [self dontRotate:originalImage];
        
        if(_isSquare){
            CGRect originalRect;
            [info[UIImagePickerControllerCropRect] getValue:&originalRect];
            CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], originalRect);
            originalImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        
        //デリゲート通知
        [_delegate FZZImagePickerKit:self image:originalImage status:FZZImagePickerStatusSuccess];
    }
}

- (UIImage *)dontRotate:(UIImage *)image{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width,image.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

-(void) loadImageFromAssertByUrl:(NSURL *)url completion:(void (^)(UIImage*)) completion{
    __weak typeof(self) weakSelf = self;
    
    self.assetLibrary = [ALAssetsLibrary new];
    [self.assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc((unsigned int)rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0f length:(unsigned int)rep.size error:nil];
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        UIImage* img = [UIImage imageWithData:data];
        completion(img);
    } failureBlock:^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:nil];
        [weakSelf.delegate FZZImagePickerKit:weakSelf image:nil status:FZZImagePickerStatusCancelForALAssetsLibrary];
    }];
}


+ (BOOL)canAccessToPhoto{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    if (status == ALAuthorizationStatusNotDetermined){
        //まだ許可ダイアログ出たことない
        return YES;
    } else if (status == ALAuthorizationStatusRestricted){
        //機能制限(ペアレンタルコントロール)で許可されてない
        return NO;
    } else if (status == ALAuthorizationStatusDenied){
        //許可ダイアログで\"いいえ\"が押されています
        //設定アプリ -> プライバシー > 写真 -> 該当アプリを\"オン\"する必要があります
        return NO;
    } else if (status == ALAuthorizationStatusAuthorized){
        //写真へのアクセスが許可されています
        return YES;
    }
    
    return YES;
}

+ (BOOL)canAccessToCamera{
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusRestricted){
        //Restricted
        return NO;
    }else if(authStatus == AVAuthorizationStatusDenied){
        //Denied
        return NO;
    }else if(authStatus == AVAuthorizationStatusAuthorized){
        //Authorized
        return YES;
    }else if(authStatus == AVAuthorizationStatusNotDetermined){
        //Not Determined
        return YES;
    }
    return YES;
}

@end
