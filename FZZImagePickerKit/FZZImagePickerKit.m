//
//  FZZImagePickerKit.m
//  FZZImagePickerKit
//
//  Created by Administrator on 2016/03/06.
//  Copyright © 2016年 Shota Nakagami. All rights reserved.
//

#import "FZZImagePickerKit.h"

//Localize
#import "NSString+FZZImagePickerKitLocalized.h"

//iOS SDK
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

//OSS
#import "SVProgressHUD.h"
#import "RMUniversalAlert.h"

@interface FZZImagePickerKit()
<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;

@end

@implementation FZZImagePickerKit

-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        _isSquare = NO;
    }
    return self;
}

- (void)openCameraWithIsSquare:(BOOL)isSquare
                 isFrontCamera:(BOOL)isFrontCamera
                      delegate:(id)delegate{
    self.isSquare = isSquare;
    self.delegate = delegate;
    self.isFrontCamera = isFrontCamera;
    
    //カメラ有無チェック
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [self showDialogForNoCamera];
        [self.delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusFailForNoCamera];
        return;
    }
    
    //アクセス権チェック
    if(![FZZImagePickerKit canAccessToCamera]){
        [self showDialogForCameraAccessibility];
        [self.delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusCancelForCameraAccessibility];
        return;
    }
    
    [self openImagePicker:UIImagePickerControllerSourceTypeCamera];
}

- (void)openAlbumWithIsSquare:(BOOL)isSquare
                     delegate:(id)delegate{
    self.isSquare = isSquare;
    self.delegate = delegate;
    
    //アクセス権チェック
    if(![FZZImagePickerKit canAccessToPhoto]){
        [self showDialogForPhotoAccessibility];
        [self.delegate FZZImagePickerKit:self image:nil status:FZZImagePickerStatusCancelForPhotoAccessibility];
        return;
    }
    
    [self openImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    
}

- (void)showDialogForNoCamera{
    [self showErrorHUDForce:[@"This device has no camera." FZZImagePickerKitLocalized]];
}

- (void)showDialogForCameraAccessibility{
    [RMUniversalAlert showAlertInViewController:(UIViewController *)self.delegate
                                      withTitle:[@"This app can't access to your camera." FZZImagePickerKitLocalized]
                                        message:[@"Please enable access to your camera in Settings." FZZImagePickerKitLocalized]
                              cancelButtonTitle:[@"OK" FZZImagePickerKitLocalized]
                         destructiveButtonTitle:nil
                              otherButtonTitles:@[[@"Open Settings" FZZImagePickerKitLocalized]]
                                       tapBlock:^(RMUniversalAlert *alert, NSInteger buttonIndex){
                                           if(buttonIndex == alert.firstOtherButtonIndex){
                                               //設定画面を開く
                                               NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                               [[UIApplication sharedApplication] openURL:url];
                                           }
                                       }];
}

- (void)showDialogForPhotoAccessibility{
    [RMUniversalAlert showAlertInViewController:(UIViewController *)self.delegate
                                      withTitle:[@"This app can't access to your photos." FZZImagePickerKitLocalized]
                                        message:[@"Please enable access to your photos in Settings." FZZImagePickerKitLocalized]
                              cancelButtonTitle:[@"OK" FZZImagePickerKitLocalized]
                         destructiveButtonTitle:nil
                              otherButtonTitles:@[[@"Open Settings" FZZImagePickerKitLocalized]]
                                       tapBlock:^(RMUniversalAlert *alert, NSInteger buttonIndex){
                                           if(buttonIndex == alert.firstOtherButtonIndex){
                                               //設定画面を開く
                                               NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                               [[UIApplication sharedApplication] openURL:url];
                                           }
                                       }];
}

- (void)openImagePicker:(int)sourceType {
    //[self showHUDForce];
    
    //イメージピッカーの設定
    self.picker = [UIImagePickerController new];
    self.picker.delegate = self;
    self.picker.allowsEditing = self.isSquare;
    self.picker.sourceType = sourceType;//ソースタイプを選択
    
    if(self.picker.sourceType == UIImagePickerControllerSourceTypeCamera){
        if(self.isFrontCamera){
            self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }else{
            self.picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }
    }
    
    //イメージピッカーを表示する
    [(UIViewController *)self.delegate presentViewController:self.picker animated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    __weak typeof(self) weakSelf = self;
    
    //イメージピッカーを閉じる
    [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:^{
        [weakSelf.delegate FZZImagePickerKit:weakSelf image:nil status:FZZImagePickerStatusCancel];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSLog(@"1");
    
    [self showHUDForce];
    
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    
    __weak typeof(self) weakSelf = self;
    
    if(!originalImage){
        NSLog(@"2");
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
                                
                                //イメージピッカーを閉じる
                                [(UIViewController *)weakSelf.delegate dismissViewControllerAnimated:YES completion:^{
                                    [weakSelf dismissHUDForce];
                                    
                                    //デリゲート通知
                                    [weakSelf.delegate FZZImagePickerKit:weakSelf image:image status:FZZImagePickerStatusSuccess];
                                }];
                            }];
    }else{
        NSLog(@"3");
        //originalImageが取得できた場合
        originalImage = [self dontRotate:originalImage];
        
        if(self.isSquare){
            CGRect originalRect;
            [info[UIImagePickerControllerCropRect] getValue:&originalRect];
            CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], originalRect);
            originalImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        //イメージピッカーを閉じる
        [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:^{
            NSLog(@"4");
            [weakSelf dismissHUDForce];
            
            //デリゲート通知
            [weakSelf.delegate FZZImagePickerKit:weakSelf image:originalImage status:FZZImagePickerStatusSuccess];
        }];
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
        [weakSelf showErrorHUDForce:err.description];
        
        //デリゲート通知
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

- (void)requestCamera{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus != AVAuthorizationStatusNotDetermined){
        return;
    }
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            // 許可された場合の処理
            dispatch_async(dispatch_get_main_queue(), ^{
                // do something
            });
        } else {
            // 許可してもらえない場合
            dispatch_async(dispatch_get_main_queue(), ^{
                // do something
            });
        }
    }];
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

- (void)dismissHUDForce{
    if([NSThread isMainThread]){
        [SVProgressHUD dismiss];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }
}

- (void)showHUDForce{
    if([NSThread isMainThread]){
        [SVProgressHUD show];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD show];
        });
    }
}

- (void)showErrorHUDForce:(NSString *)message{
    if([NSThread isMainThread]){
        [SVProgressHUD showErrorWithStatus:message];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:message];
        });
    }
}


@end
