//
//  VTDataDetailTableViewController.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/7/6.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTDataDetailTableViewController.h"

@interface VTDataDetailTableViewController ()

@property (nonatomic, strong) NSMutableArray *detailList;

@end

@implementation VTDataDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    
    NSString *fileName = self.dataDict.allKeys.firstObject;
    NSData *rawdata = self.dataDict.allValues.firstObject;
    __weak typeof(self) weakself = self;
    if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeECG) {
        if ([fileName hasPrefix:@"a"]) {
            [VTMBLEParser parseFileA:rawdata result:^(VTMDuoEKFileAHead head, VTMDuoEKFileAResult * _Nonnull results) {
                
            }];
        }else{
            [VTMBLEParser parseWaveHeadAndTail:rawdata result:^(VTMFileHead head, VTMER2FileTail tail) {
                [weakself.detailList addObject:@{@"Duration": [NSString stringWithFormat:@"%d s", tail.recording_time]}];
            }];
            
            // 125hz
            NSData *wavePointsData = [VTMBLEParser pointDataFromOriginalData:rawdata];
            NSArray *originalWaveArr = [VTMBLEParser parseOrignalPoints:wavePointsData];
            NSArray *mVWaveArr = [VTMBLEParser parsePoints:wavePointsData];
            
            
            
            
        }
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeBP) {
        Byte *b = rawdata.bytes;
        u_char type = b[1];
        if (type == 1) {
            
            VTMBPBPResult result = [VTMBLEParser parseBPResult:rawdata];
            
            [self.detailList addObject:@{@"DIA": [NSString stringWithFormat:@"%d mmHg", result.diastolic_pressure]}];
            [self.detailList addObject:@{@"SYS": [NSString stringWithFormat:@"%d mmHg", result.systolic_pressure]}];
            [self.detailList addObject:@{@"MAP": [NSString stringWithFormat:@"%d mmHg", result.mean_pressure]}];
            [self.detailList addObject:@{@"PR": [NSString stringWithFormat:@"%d /min", result.pulse_rate]}];
            
            
        } else if (type == 2) {
            
            NSData *resultData = [rawdata subdataWithRange:NSMakeRange(0, sizeof(VTMBPECGResult))];
            VTMBPECGResult result = [VTMBLEParser parseECGResult:resultData];
            [self.detailList addObject:@{@"Duration": [NSString stringWithFormat:@"%d s", result.recording_time]}];
            [self.detailList addObject:@{@"HR": [NSString stringWithFormat:@"%d /min", result.hr]}];
            
            // sample rate 125hz
            NSData *waveformData = [rawdata subdataWithRange:NSMakeRange(sizeof(VTMBPECGResult), rawdata.length - sizeof(VTMBPECGResult))];
            NSArray *ecgWaveArr = [VTMBLEParser parseBPPoints:waveformData];
            
            
        } else {
            DLog(@"An error occurred.");
        }
        
        
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeScale) {
        
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeWOxi) {

        [VTMBLEParser oxi_parseFile:rawdata completion:^(VTMOxiFileHead head, VTMOxiPoint * _Nonnull points, VTMOxiFileTail tail) {

            [weakself.detailList addObject:@{@"Avg. SpO2": [NSString stringWithFormat:@"%d %%", tail.result.average_spo2]}];
            [weakself.detailList addObject:@{@"Lowest SpO2": [NSString stringWithFormat:@"%d %%", tail.result.lowest_spo2]}];
            [weakself.detailList addObject:@{@"3% drops": [NSString stringWithFormat:@"%d", tail.result.percent3_drops]}];
            [weakself.detailList addObject:@{@"4% drops": [NSString stringWithFormat:@"%d", tail.result.percent4_drops]}];
            [weakself.detailList addObject:@{@"T90": [NSString stringWithFormat:@"%d", tail.result.t90]}];
            [weakself.detailList addObject:@{@"Drops duration": [NSString stringWithFormat:@"%d", tail.result._90percent_time]}];
            [weakself.detailList addObject:@{@"Drops numbers": [NSString stringWithFormat:@"%d", tail.result._90percent_drops]}];
            [weakself.detailList addObject:@{@"O2 score": [NSString stringWithFormat:@"%.1f", tail.result.o2_score / 10.0]}]; // 255 is invalid
            [weakself.detailList addObject:@{@"Avg. PR": [NSString stringWithFormat:@"%d /min", tail.result.average_pr]}];
            
            for (int i = 0; i < tail.records; i ++) {
                VTMOxiPoint p = points[i];
                // plot trend 
            }
            
        }];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
}

#pragma mark - getter
- (NSMutableArray *)detailList {
    if (!_detailList) {
        _detailList = [NSMutableArray array];
    }
    return _detailList;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.detailList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"detailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    NSDictionary *dict = self.detailList[indexPath.row];
    cell.textLabel.text = dict.allKeys.firstObject;
    cell.detailTextLabel.text = dict.allValues.firstObject;
    return cell;
    
}



@end
