//
//  VTDataListTableViewController.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/7/5.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTDataListTableViewController.h"
#import "VTDataDetailTableViewController.h"
#import "VTRealDataViewController.h"
#import "VTSettingsTableViewController.h"

/// Localizes the tab bar items of the oximeter tab bar (storyboard id `myTabBarController`).
///
/// In Main.storyboard every tab is a plain UINavigationController whose root is one of the
/// Oxygen view controllers, and the `tabBarItem` belongs to that navigation controller, not to
/// the root VC. The root VC cannot reach it in `awakeFromNib` (navigationController is still nil),
/// so each root VC calls this from `viewDidLoad`. The selected tab's root view loads before the
/// tab bar is first rendered, so all three items are localized up front no matter which tab
/// loads first. Items are matched by root VC class, so tab order does not matter. Idempotent.
/// Also declared (extern) in VTRealDataViewController.m and VTSettingsTableViewController.m.
FOUNDATION_EXTERN void VTOxiLocalizeTabBarItems(UITabBarController * _Nullable tabBarController);
void VTOxiLocalizeTabBarItems(UITabBarController * _Nullable tabBarController) {
    for (UIViewController *child in tabBarController.viewControllers) {
        UIViewController *root = child;
        if ([child isKindOfClass:[UINavigationController class]]) {
            root = ((UINavigationController *)child).viewControllers.firstObject;
        }
        NSString *key = nil;
        if ([root isKindOfClass:[VTDataListTableViewController class]]) {
            key = @"oxi.tab.history";
        } else if ([root isKindOfClass:[VTRealDataViewController class]]) {
            key = @"oxi.tab.dashboard";
        } else if ([root isKindOfClass:[VTSettingsTableViewController class]]) {
            key = @"oxi.tab.settings";
        }
        if (key) {
            child.tabBarItem.title = VTMLocalized(key);
        }
    }
}

@interface VTDataListTableViewController ()

@property (nonatomic, copy) NSArray *dataList;

@property (nonatomic, strong) NSMutableDictionary *listDict;



@end

@implementation VTDataListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = VTMLocalized(@"oxi.nav.history");
    VTOxiLocalizeTabBarItems(self.tabBarController);
    
    self.tableView.tableFooterView = [UIView new];
    
    __weak typeof(self) weakself = self;
    
    [[VTCOMMPresenter sharedInstance] requestDataListHandle:^(NSArray * _Nullable dataList) {
        
        dataList = [dataList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2] == NSOrderedAscending;
        }];
        
        weakself.dataList = dataList;
        [weakself.tableView reloadData];
    }];
    
    
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"dataListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.dataList[indexPath.row];
    
    NSDictionary *dict = [self storeDataWithFileName:cell.textLabel.text];
    CGFloat progress = 0.0;
    if (dict.allKeys.count > 0) {
        NSData *rawdata = [dict objectForKey:@"rawdata"];
        u_int fileLen = [[dict objectForKey:@"fileLen"] unsignedIntValue];
        progress = rawdata.length * 1.0 / fileLen;
        
    }
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.progressTintColor = [UIColor blueColor];
    progressView.progress = progress;
    if (progress == 1) {
        progressView.progressTintColor = [UIColor greenColor];
    }
    
    cell.accessoryView = progressView;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *fileName = self.dataList[indexPath.row];
    NSDictionary *dict = [self storeDataWithFileName:fileName];
    CGFloat progress = 0.0;
    NSData *rawdata = nil;
    if (dict.allKeys.count > 0) {
        rawdata = [dict objectForKey:@"rawdata"];
        u_int fileLen = [[dict objectForKey:@"fileLen"] unsignedIntValue];
        progress = rawdata.length * 1.0 / fileLen;
    }
    if (progress == 1) {
        
        VTDataDetailTableViewController *vc = [[VTDataDetailTableViewController alloc] init];
        
        vc.dataDict = @{fileName: rawdata};
        [self.navigationController pushViewController:vc animated:YES];
        
        
    } else {
        __block NSString *fileName = self.dataList[indexPath.row];
        __weak typeof (self) weakself = self;
        [[VTCOMMPresenter sharedInstance] requestFileLength:fileName handle:^(u_int fileLen, NSString *curFileName) {
            [weakself readFileContentWithFileName:curFileName fileLen:fileLen];
        }];
    }
}


#pragma mark -- getter && setter


- (NSMutableDictionary *)listDict {
    if (!_listDict) {
        _listDict = [NSMutableDictionary dictionary];
    }
    return _listDict;
}

#pragma mark -- private

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   handler:(void (^ __nullable)(UIAlertAction *action))handler{
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:VTMLocalized(@"common.ok") style:UIAlertActionStyleDefault handler:handler];
    [alertVC addAction:confirmAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}



- (NSDictionary *)storeDataWithFileName:(NSString *)fileName {
    NSDictionary *dict = [NSDictionary dictionary];
    if ([self.listDict.allKeys containsObject:fileName]) {
        // resume
        dict = [self.listDict objectForKey:fileName];
    }
    return dict;
}

- (void)readFileContentWithFileName:(NSString *)fileName fileLen:(u_int)fileLen{
    
    NSDictionary *dict = [self storeDataWithFileName:fileName];
    
    NSInteger row = [self.dataList indexOfObject:fileName];
    __block UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    __block UIProgressView *progressView = (UIProgressView *)cell.accessoryView;
    
    __block NSMutableData *tempData = [NSMutableData dataWithData:[dict objectForKey:@"rawdata"]];
    
    __weak typeof (self) weakself = self;
    [[VTCOMMPresenter sharedInstance] requestFileContent:tempData.length handle:^(NSData * _Nonnull fileContent) {
            
        [tempData appendData:fileContent];
        
        NSDictionary *tempDict = @{@"rawdata": tempData.copy, @"fileLen": @(fileLen)};
        
        [self.listDict setValue:tempDict forKey:fileName];
        
        if (tempData.length < fileLen) {
            
            progressView.progress = tempData.length*1.0/fileLen;
            // continue
            [weakself readFileContentWithFileName:fileName fileLen:fileLen];
            
        } else {
            
            // done
            progressView.progress = 1.0;
            progressView.progressTintColor = [UIColor greenColor];
            
            [[VTCOMMPresenter sharedInstance] endRequestFileHandle:^{ }];
            
        }
        
        
    }];
    
}





@end
