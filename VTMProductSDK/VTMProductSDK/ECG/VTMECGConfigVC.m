//
//  VTMECGConfigVC.m
//  VTMProductSDK
//
//  Created by Viatom3 on 2021/2/25.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMECGConfigVC.h"

@interface VTMECGConfigVC ()<VTMURATUtilsDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *hrSwitch;
@property (weak, nonatomic) IBOutlet UITextField *maxHRTextField;
@property (weak, nonatomic) IBOutlet UITextField *minHRTextField;

@property (weak, nonatomic) IBOutlet UIView *MaxView;
@property (weak, nonatomic) IBOutlet UIView *minView;
@property (weak, nonatomic) IBOutlet UIButton *sureBtn;

@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation VTMECGConfigVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"ECG Config";
    _maxHRTextField.keyboardType = UIKeyboardTypeNumberPad;
    _minHRTextField.keyboardType = UIKeyboardTypeNumberPad;
    _sureBtn.layer.cornerRadius = 20.f;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [VTMProductURATUtils sharedInstance].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [VTMProductURATUtils sharedInstance].delegate = nil;
}



- (IBAction)sureClick:(id)sender {
    if (_minHRTextField.text.length == 0) {
        NSString *str = @"Enter the minimum value";
        [self showAlertWithTitle:str message:nil handler:nil];
    }else if (_maxHRTextField.text.length == 0){
        NSString *str = @"Enter the maximum value";
        [self showAlertWithTitle:str message:nil handler:nil];
    }else if (([_minHRTextField.text intValue] > 200) || ([_maxHRTextField.text intValue] > 200)) {
        NSString *str = @"The value cannot exceed 200";
        [self showAlertWithTitle:str message:nil handler:nil];
    }else if([_minHRTextField.text intValue] >= [_maxHRTextField.text intValue]){
        NSString *str = @"The minimum value cannot be greater than the maximum value";
        [self showAlertWithTitle:str message:nil handler:nil];
    }else{
        [self.progressHUD showAnimated:YES];
        VTMER1Config er1Config;
        er1Config.vibeSw =  _hrSwitch.on;
        er1Config.hrTarget1 = [_minHRTextField.text intValue];
        er1Config.hrTarget2 = [_maxHRTextField.text intValue];
        [[VTMProductURATUtils sharedInstance] syncER1Config:er1Config];
    }
}

- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response{
    switch (cmdType) {
        case VTMECGCmdSetConfig:
        {
            DLog(@"Config successfully");
            [self.progressHUD hideAnimated:YES];
            [self showAlertWithTitle:@"Config successfully" message:nil handler:nil];
        }
            break;
            
        default:
            break;
    }
}

- (void)util:(VTMURATUtils *)util commandFailed:(u_char)cmdType deviceType:(VTMDeviceType)deviceType failedType:(VTMBLEPkgType)type{
    switch (cmdType) {
        case VTMECGCmdSetConfig:
        {
            DLog(@"Config failure");
            [self.progressHUD hideAnimated:YES];
            [self showAlertWithTitle:@"Config failure" message:nil handler:nil];
        }
            break;
            
        default:
            break;
    }
}
- (void)showAlertWithTitle:(NSString *)title
                  message:(NSString *)message
                   handler:(void (^ __nullable)(UIAlertAction *action))handler{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:handler];
    [alertVC addAction:confirmAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _progressHUD.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}
@end
