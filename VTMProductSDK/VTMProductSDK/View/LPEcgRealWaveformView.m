//
//  LPEcgRealWaveformView.m
//  iwown
//
//  Created by fengye on 2020/5/24.
//  Copyright © 2020 LP. All rights reserved.
//

#import "LPEcgRealWaveformView.h"

#define RefreshTime 0.04

@interface LPEcgRealWaveformView ()

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;   // 进度指示
@property (nonatomic, strong) UILabel *rulerLab;  // 标尺
@property (nonatomic, strong) UIButton *rulerBtn;
@property (nonatomic, strong) UIView *rulerResponseView;  //标尺更新区域

@property (nonatomic, strong) CADisplayLink *refreshLink;
@property (nonatomic, strong) NSMutableArray *poolArray;  // 缓存池
@property (nonatomic, strong) NSMutableArray *pointArr;    // 坐标数据池
@property (nonatomic, strong) NSMutableArray *fliterPool;  // 滤波后的缓存池
@property (nonatomic, strong) NSMutableArray *arr1;    // 坐标数组1
@property (nonatomic, strong) NSMutableArray *arr2;    // 坐标数组2
@property (nonatomic, strong) CAShapeLayer *refreshLayer;  //刷新波形
@property (nonatomic, strong) CAShapeLayer *rulerLayer;  // 标尺

@property (nonatomic, assign) u_char runStatus; // 运行状态

@end

@implementation LPEcgRealWaveformView

{
    float pointX;  //画波形的点
    float pointY;
    int indexX;   // 标记
    bool isInvalid;
    float points_per_mm;       // 每mm 对应的pt
    float mm_per_value;              //两个值的间隔对应的 mm数      计算得来
    float points_per_value;           //两个点之间的距离对应的point点   决定点的x坐标
    int points_per_screen;           //    由屏宽除一个点对应的point点数   的来
    float mm_per_mV1;            // 每mV 对应的mm数  对应Y值
}

static int refreshPoint = 8;
static bool showRuler = false;
static float rulerLevel = 1;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
//        [self via_initParams];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self via_initParams];
}

- (void)via_initParams
{
    indexX = 0;
    pointX = 0.0;
    mm_per_mV1 = 10;
    points_per_mm = 1/(25.4/163);
    mm_per_value = 25.0/(125*1.0);   // 25 mm   125Hz  125 个点
    _hz = 125;
    points_per_value = points_per_mm*mm_per_value;
    _poolArray = [NSMutableArray array];
    _fliterPool = [NSMutableArray array];
    _pointArr = [NSMutableArray array];
    _arr1 = [NSMutableArray array];
    _arr2 = [NSMutableArray array];
    [self clearChache];
    
}

- (void)setIsBpWave:(BOOL)isBpWave {
    _isBpWave = isBpWave;
    
    if (isBpWave) {
        _hz = 250;
        mm_per_mV1 = 10;
        points_per_mm = 1.0/(25.4/163);
        mm_per_value = 25.0/(250*1.0);   // 25 mm   250  250 个点
        points_per_value = points_per_mm*mm_per_value;
        [self setNeedsDisplay];
    }
}


- (void)setReceiveArray:(NSArray *)receiveArray{

    _receiveArray = receiveArray;
    [_fliterPool addObjectsFromArray:receiveArray];
    
    if (receiveArray.count == 0) {
        isInvalid = YES;
    }else{
       
        isInvalid = NO;
        
    }
    [self startDisplayLink];
    
}

- (void)setIsConnected:(BOOL)isConnected{

    _rulerLab.hidden = YES;
    _rulerBtn.hidden = YES;
    _rulerLayer.hidden = YES;
    if (_pointArr.count > 0) {
        indexX = 0;
        [_pointArr removeAllObjects];
        [self drawRuler:NO];
        [self drawRealWaveRefresh];
    }

}


- (CAShapeLayer *)refreshLayer{
    if (!_refreshLayer) {
        _refreshLayer = [CAShapeLayer layer];
        _refreshLayer.strokeColor = [UIColor colorWithRed:82/255.f green:211/255.f blue:106/255.f alpha:1].CGColor;
        _refreshLayer.fillColor = [UIColor clearColor].CGColor;
//        float scale = [UIScreen mainScreen].scale;
        _refreshLayer.lineWidth = 1.5;//scale;
        [self.layer addSublayer:_refreshLayer];
    }
    return _refreshLayer;
}

- (CAShapeLayer *)rulerLayer{
    if (!_rulerLayer) {
        _rulerLayer = [CAShapeLayer layer];
        _rulerLayer.fillColor = [UIColor clearColor].CGColor;
        _rulerLayer.strokeColor = [UIColor blackColor].CGColor;
        _rulerLayer.lineWidth = 1.0;
        [self.layer addSublayer:_rulerLayer];
    }
    return _rulerLayer;
}

- (UILabel *)rulerLab{
    if (!_rulerLab) {
        _rulerLab = [[UILabel alloc] init];
        _rulerLab.font = [UIFont systemFontOfSize:10];
        _rulerLab.textColor = [UIColor blackColor];
        _rulerLab.text = @"1mV";
        [self addSubview:_rulerLab];
    }
    return _rulerLab;
}

- (UIButton *)rulerBtn{
    if (!_rulerBtn) {
        _rulerBtn = [[UIButton alloc] init];
        [_rulerBtn setTitle:@"10mm/mV" forState:UIControlStateNormal];
        [_rulerBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_rulerBtn addTarget:self action:@selector(changeRate) forControlEvents:UIControlEventTouchUpInside];
        [_rulerBtn setBackgroundColor:[UIColor greenColor]];
        [_rulerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self addSubview:_rulerBtn];
    }
    return _rulerBtn;
}

- (UIView *)rulerResponseView{
    if (!_rulerResponseView) {
        _rulerResponseView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height*0.2, self.frame.size.width, self.frame.size.height*0.6)];
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeRate)];
//        [_rulerResponseView addGestureRecognizer:tap];
        _rulerResponseView.backgroundColor = [UIColor clearColor];
        [self addSubview:_rulerResponseView];
    }
    return _rulerResponseView;
}

- (void)changeRate{
    if (showRuler) {
        NSNumber *num;
        if (rulerLevel == 1) {
            rulerLevel = 2;
            num = @(20);
        }else if (rulerLevel == 2){
            rulerLevel = 0.5;
            num = @(5);
        }else if (rulerLevel == 0.5){
            rulerLevel = 1;
            num = @(10);
        }
        [_rulerBtn setTitle:[NSString stringWithFormat:@"%dmm/mV",num.intValue] forState:UIControlStateNormal];
        mm_per_mV1 = num.floatValue;
        [self drawRuler:YES];
        [self setNeedsDisplay];
        [self layoutSubviews];
    }
}

- (void)drawRect:(CGRect)rect {
    points_per_screen = rect.size.width / points_per_value;
    [self drawThinLines];
    [self drawThickLines];
    [self drawRealWaveRefresh];
}

//画细线
- (void)drawThinLines {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //纵细线
    for (float i = points_per_mm; i <= self.frame.size.width; i += points_per_mm) {
        CGPoint verticalPointStart = CGPointMake(i, 0);
//        CGPoint verticalPointEnd = CGPointMake(verticalPointStart.x, self.height);
        CGPoint verticalPointEnd = CGPointMake(verticalPointStart.x, 40*points_per_mm);
        [path moveToPoint:verticalPointStart];
        [path addLineToPoint:verticalPointEnd];
    }
    //横细线
//    for (float i = points_per_mm; i <= self.height; i += points_per_mm) {
    for (float i = points_per_mm; i <= 40*points_per_mm; i += points_per_mm) {
        CGPoint horizonPointStart = CGPointMake(0, i);
        CGPoint horizonPointEnd = CGPointMake(self.frame.size.width, horizonPointStart.y);
        [path moveToPoint:horizonPointStart];
        [path addLineToPoint:horizonPointEnd];
    }
    
    path.lineWidth = 0.1;
    [[UIColor grayColor] setStroke];
    [path stroke];
    
}
//画粗线
- (void)drawThickLines {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //纵粗线
    for (float i = 5 * points_per_mm; i <= self.frame.size.width; i += 5 * points_per_mm) {
        CGPoint verticalPointStart = CGPointMake(i, 0);
        CGPoint verticalPointEnd = CGPointMake(verticalPointStart.x, 40*points_per_mm);
        [path moveToPoint:verticalPointStart];
        [path addLineToPoint:verticalPointEnd];
    }
    //横粗线
    for (float i = 0; i <= 40*points_per_mm; i += 5 * points_per_mm) {
        CGPoint horizonPointStart = CGPointMake(0, i);
        CGPoint horizonPointEnd = CGPointMake(self.frame.size.width, horizonPointStart.y);
        [path moveToPoint:horizonPointStart];
        [path addLineToPoint:horizonPointEnd];
    }
    
    path.lineWidth = 0.5;
    [[UIColor grayColor] setStroke];
    [path stroke];
}


- (void)drawCenterLine{
    int verticalGird = self.frame.size.height / points_per_mm / 5;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint horizonPointStart = CGPointMake(0, verticalGird/2*points_per_mm*5);
    CGPoint horizonPointEnd = CGPointMake(self.frame.size.width, horizonPointStart.y);
    [path moveToPoint:horizonPointStart];
    [path addLineToPoint:horizonPointEnd];
    path.lineWidth = 1.0;
    [[UIColor whiteColor] setStroke];
    [path stroke];
}



- (void)startDisplayLink
{
    if (!self.refreshLink) {
        self.refreshLink = [CADisplayLink displayLinkWithTarget:self
                                                       selector:@selector(handleDisplayLink:)];
        self.refreshLink.frameInterval = 4;
        [self.refreshLink addToRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
    }
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink
{
    [self refreshWave];
}

- (void)stopDisplayLink
{
    if (self.refreshLink) {
        [self.refreshLink invalidate];
        self.refreshLink = nil;
    }
}

- (void)refreshWave{

    
    NSMutableArray *tempArr = [NSMutableArray array];
    if (_fliterPool.count >= _hz * 0.5) {
        refreshPoint = ceil(_hz / 14.0) ;
    } else{
        refreshPoint = floor(_hz / 25.0) ;
    }
    
    if (_fliterPool.count >= refreshPoint) {
  
        [tempArr addObjectsFromArray:[_fliterPool subarrayWithRange:NSMakeRange(0, refreshPoint)]];
        [_fliterPool removeObjectsInRange:NSMakeRange(0, refreshPoint)];
    }
        if (tempArr.count >= refreshPoint) {
            if (!showRuler) {
                [self drawRuler:YES];
            }
            for (int i = 0; i < refreshPoint; i++) {  //1次取refreshPoint个点
                // x坐标
                if (indexX == 0) {
                    pointX = 0;
                }
                pointX += points_per_value;   //一个数值点占用的像素
                // y坐标
                NSNumber *num = [tempArr objectAtIndex:i];   //取realTimeDataArr的前*个点
                pointY = num.floatValue;
                CGPoint point = {pointX, pointY};    //  生成像素点
                NSValue *value = [NSValue valueWithCGPoint:point];
                
                if (_pointArr.count < points_per_screen) {
                    [_pointArr addObject:value];    // 每次取到的5个点放进数组
                } else {   //当点达到满屏时  根据indexX即可找到跳跃的那个点  indexX和indexX+1那两个点
                    [_pointArr replaceObjectAtIndex:indexX withObject:value];
                    if (indexX == 0) {
                        [_arr1 removeAllObjects];
                        [_arr1 addObject:_pointArr[0]];
                        [_arr2 removeAllObjects];
                        for (int i =(indexX+10); i<_pointArr.count; i++) {
                            [_arr2 addObject:[_pointArr objectAtIndex:i]];
                        }
                    }
                    
                    if (indexX > 0 && indexX < points_per_screen) {
                        [_arr1 addObject:_pointArr[indexX]];
                        if (_arr2.count != 0) {
                            [_arr2 removeObjectAtIndex:0];
                        }
                    }
                }
                indexX ++;
                if (indexX >= points_per_screen) {
                    indexX = 0;
                }
            }
        }
    [self drawRealWaveRefresh];    //取到*个点 重绘一次
}

- (void)clearChache{
    indexX = 0;
    [_pointArr removeAllObjects];
    [_arr1 removeAllObjects];
    [_arr2 removeAllObjects];
    [self drawRuler:NO];
    [self drawRealWaveRefresh];
    [self stopDisplayLink];
}

- (void)drawRealWaveRefresh{
    CGMutablePathRef pathA = CGPathCreateMutable();
    if (_pointArr.count < points_per_screen) {   //点少于一屏的点数时
        //第一个点
        NSValue *value = _pointArr.firstObject;
        CGPoint f_point = [self transferOriginalPointToNewPointWith:value.CGPointValue];
        CGPathMoveToPoint(pathA, nil, f_point.x, f_point.y);
        //其他点
        for (NSValue *value1 in _pointArr) {
            CGPoint o_Point = [self transferOriginalPointToNewPointWith:value1.CGPointValue];
            CGPathAddLineToPoint(pathA, nil, o_Point.x, o_Point.y);
        }
        
    } else {  //点达到一屏时 画线的方式改变
        //arr1
        CGPoint f_Point1 = [self transferOriginalPointToNewPointWith:[_arr1.firstObject CGPointValue]];
        CGPathMoveToPoint(pathA, nil, f_Point1.x, f_Point1.y);
        for (NSValue *value1 in _arr1) {
            CGPoint o_Point1 = [self transferOriginalPointToNewPointWith:value1.CGPointValue];
            CGPathAddLineToPoint(pathA, nil, o_Point1.x, o_Point1.y);
        }
        
        //arr2
        CGPoint f_Point2 = [self transferOriginalPointToNewPointWith:[_arr2.firstObject CGPointValue]];
        CGPathMoveToPoint(pathA, nil, f_Point2.x, f_Point2.y);
        for (NSValue *value2 in _arr2) {
            CGPoint o_Point2 = [self transferOriginalPointToNewPointWith:value2.CGPointValue];
            CGPathAddLineToPoint(pathA, nil, o_Point2.x, o_Point2.y);
        }
    }

    self.refreshLayer.path = pathA;
    CGPathRelease(pathA);

}

- (void)drawRuler:(BOOL)isDrawWave{
    
    if (isDrawWave) {
        self.rulerLayer.hidden = NO;
        showRuler = true;
        int verticalGird = self.frame.size.height / points_per_mm / 5;
        CGMutablePathRef pathB = CGPathCreateMutable();

        CGPoint veriPointStart = CGPointMake(points_per_mm*2, verticalGird/2*points_per_mm*5 + points_per_mm*5*rulerLevel);
        CGPoint veriPointEnd = CGPointMake(veriPointStart.x, verticalGird/2*points_per_mm*5 - points_per_mm*5*rulerLevel);
        
        CGPathMoveToPoint(pathB, nil, veriPointStart.x, veriPointStart.y);
        CGPathAddLineToPoint(pathB, nil, veriPointEnd.x, veriPointEnd.y);
        self.rulerLayer.path = pathB;
        CGPathRelease(pathB);
        [self.rulerLab setHidden:NO];
        [self.rulerBtn setHidden:NO];
        _rulerBtn.layer.cornerRadius = CGRectGetHeight(_rulerBtn.frame)*0.5;
        _rulerLab.frame = CGRectMake(veriPointEnd.x+1.0, veriPointStart.y - 10, 50, 20);
    }else{
        showRuler = false;
        self.rulerLayer.hidden = YES;
        [self.rulerLab setHidden:YES];
        [self.rulerBtn setHidden:YES];
    }
}


- (CGPoint)transferOriginalPointToNewPointWith:(CGPoint)point
{
    CGPoint newPoint;
    newPoint.x = point.x;
    int verticalGird = self.frame.size.height / points_per_mm / 5;
    newPoint.y = verticalGird/2*points_per_mm*5 - point.y*mm_per_mV1*points_per_mm;    // point.y  mV值
    
    return newPoint;
}

@end
