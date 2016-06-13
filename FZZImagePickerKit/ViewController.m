//
//  ViewController.m
//  FZZImagePickerKit
//
//  Created by Administrator on 2016/03/06.
//  Copyright © 2016年 Shota Nakagami. All rights reserved.
//

#import "ViewController.h"
#import "FZZImagePickerKit.h"

@interface ViewController ()
<FZZImagePickerKitDelegate>

@property(nonatomic, strong) FZZImagePickerKit *imagePickerKit;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.imagePickerKit = [FZZImagePickerKit new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)FZZImagePickerKit:(FZZImagePickerKit *)imagePickerKit image:(UIImage *)image status:(FZZImagePickerStatus)status{
    
}

@end
