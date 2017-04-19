//
//  CJFDebugMonitor.m
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//

#import "CJFDebugMonitor.h"
#import "CJFDebugMonitorTools.h"
#import <pthread.h>

static BOOL CJF_IS_IPHONE_IDOM = NO;

//logView相关预配置参数
static CGFloat CJF_init_log_height;
static CGFloat CJF_max_log_height;
static CGFloat CJF_min_log_height;
static CGFloat CJF_unit_log_height;

//iPad兼容横竖屏
static CGFloat const iPad_init_log_height = 300.0;
static CGFloat const iPad_max_log_height = 440.0;
static CGFloat const iPad_min_log_height = 240.0;
static CGFloat const iPad_unit_log_height = 20.0;

static CGFloat const iPad_textTrailingSpace = 60.0;
static CGFloat const iPad_btnWidth = 46.0;
static CGFloat const iPad_yBtnSpace = 10.0;

//iPhone兼容横竖屏
static CGFloat const iPhone_init_log_height = 230.0;
static CGFloat const iPhone_max_log_height = 280.0;
static CGFloat const iPhone_min_log_height = 180.0;
static CGFloat const iPhone_unit_log_height = 10.0;

static CGFloat const iPhone_textTrailingSpace = 40.0;
static CGFloat const iPhone_btnWidth = 30.0;
static CGFloat const iPhone_yBtnSpace = 10.0;

//预存储字符串
static NSAttributedString* CJF_early_attribute_string = nil;



@interface CJFDebugMonitor ()

@property (nonatomic, strong) UILabel *fpsLabel;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger scheduleTimes;
@property (nonatomic, assign) CFTimeInterval timestamp;
@property (nonatomic, assign) BOOL needShowMemory;
@property (nonatomic, strong) UIView* logView;
@property (nonatomic, strong) UITextView* textView;

@property (nonatomic, weak) UIView* containerView;
@property (nonatomic, strong) UIButton* lockBtn;
@property (nonatomic, strong) UIButton* clearBtn;
@property (nonatomic, strong) UIButton* addBtn;
@property (nonatomic, strong) UIButton* subBtn;
@property (nonatomic, assign) CGFloat logHeight;

@property (nonatomic,strong) NSLayoutConstraint* logViewHeight;

@end

@implementation CJFDebugMonitor

#pragma mark - life cycle
+ (CJFDebugMonitor *)sharedInstance
{
    static CJFDebugMonitor *indicator;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //决定设备差异赋值
        if( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ){
            CJF_IS_IPHONE_IDOM = YES;
            
            CJF_init_log_height = iPhone_init_log_height;
            CJF_max_log_height = iPhone_max_log_height;
            CJF_min_log_height = iPhone_min_log_height;
            CJF_unit_log_height = iPhone_unit_log_height;
        }else{
            CJF_IS_IPHONE_IDOM = NO;
            
            CJF_init_log_height = iPad_init_log_height;
            CJF_max_log_height = iPad_max_log_height;
            CJF_min_log_height = iPad_min_log_height;
            CJF_unit_log_height = iPad_unit_log_height;
        }
        
        
        indicator = [[super alloc] initUniqueInstance];
        CJF_early_attribute_string = [[NSAttributedString alloc] initWithString:@""];
    });
    
    return indicator;
}

- (instancetype)initUniqueInstance
{
    self = [super init];
    if(self){
        _containerView = nil;
        _frequency = CJFDebugMonitorRefreshFrequencyNormal;
        _needShowMemory = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillChangeOrientationNotification)
                                                     name: UIApplicationDidChangeStatusBarOrientationNotification
                                                   object: nil];
    }
    return self;
}

- (void)setupDisplayLink
{
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkTicks:)];
    [_displayLink setPaused:YES];
    
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -view

- (void)setupSubviews
{
    NSAssert(_containerView, @"containerView must not nil");
    _logView = [[UIView alloc] initWithFrame:_containerView.bounds];
    _logView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.3];
    _logHeight = CJF_init_log_height;
    [_containerView addSubview:_logView];
    _logView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint* logViewLeading =
    [NSLayoutConstraint constraintWithItem:_logView
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0];
    
    NSLayoutConstraint* logViewTralling =
    [NSLayoutConstraint constraintWithItem:_logView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0];
    
    _logViewHeight =
    [NSLayoutConstraint constraintWithItem:_logView
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:_logHeight];
    
    NSLayoutConstraint* logViewBottom =
    [NSLayoutConstraint constraintWithItem:_logView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0];
    
    [_containerView addConstraint:logViewLeading];
    [_containerView addConstraint:logViewTralling];
    [_containerView addConstraint:_logViewHeight];
    [_containerView addConstraint:logViewBottom];
    
    CGFloat textTrailingSpace = 0;
    CGFloat btnWidth = 0;
    CGFloat yBtnSpace = 0;
    
    if( CJF_IS_IPHONE_IDOM ){
        textTrailingSpace = iPhone_textTrailingSpace;
        btnWidth = iPhone_btnWidth;
        yBtnSpace = iPhone_yBtnSpace;
    }else{
        textTrailingSpace = iPad_textTrailingSpace;
        btnWidth = iPad_btnWidth;
        yBtnSpace = iPad_yBtnSpace;
    }
    CGFloat trailingSpace = (textTrailingSpace - btnWidth) / 2;
    
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.backgroundColor = [UIColor clearColor];
    [_logView addSubview:_textView];
    _textView.layoutManager.allowsNonContiguousLayout = NO;
    _textView.editable = NO;
    _textView.bounces = NO;
    _textView.attributedText = [[NSAttributedString alloc] initWithString:@""];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint* textViewLeading =
    [NSLayoutConstraint constraintWithItem:_textView
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_logView
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0];
    
    NSLayoutConstraint* textViewTralling =
    [NSLayoutConstraint constraintWithItem:_textView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_logView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:-textTrailingSpace];
    
    NSLayoutConstraint* textViewTop=
    [NSLayoutConstraint constraintWithItem:_textView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_logView
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0];
    
    NSLayoutConstraint* textViewBottom =
    [NSLayoutConstraint constraintWithItem:_textView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_logView
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:-10];
    
    [_logView addConstraint:textViewLeading];
    [_logView addConstraint:textViewTralling];
    [_logView addConstraint:textViewTop];
    [_logView addConstraint:textViewBottom];
    
    _lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _lockBtn.backgroundColor = [UIColor grayColor];
    _lockBtn.alpha = 0.8;
    _lockBtn.layer.cornerRadius = 5;
    _lockBtn.clipsToBounds = YES;
    _lockBtn.layer.shouldRasterize = YES;
    [_lockBtn setTitle:( CJF_IS_IPHONE_IDOM ? @"L" : @"lock" ) forState:UIControlStateNormal];
    [_lockBtn addTarget:self action:@selector(logViewBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_lockBtn];
    _lockBtn.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint* btnTrallingLayout =
    [NSLayoutConstraint constraintWithItem:_lockBtn
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:-trailingSpace];
    
    NSLayoutConstraint* btnWidthLayout =
    [NSLayoutConstraint constraintWithItem:_lockBtn
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    NSLayoutConstraint* btnHeightLayout =
    [NSLayoutConstraint constraintWithItem:_lockBtn
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    NSLayoutConstraint* btnBottomLayout =
    [NSLayoutConstraint constraintWithItem:_lockBtn
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:-yBtnSpace];
    
    [_containerView addConstraint:btnWidthLayout];
    [_containerView addConstraint:btnHeightLayout];
    [_containerView addConstraint:btnTrallingLayout];
    [_containerView addConstraint:btnBottomLayout];
    
    _clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _clearBtn.backgroundColor = [UIColor grayColor];
    _clearBtn.alpha = 0.8;
    _clearBtn.layer.cornerRadius = 5;
    _clearBtn.clipsToBounds = YES;
    _clearBtn.layer.shouldRasterize = YES;
    [_clearBtn setTitle:( CJF_IS_IPHONE_IDOM ? @"C" : @"clear") forState:UIControlStateNormal];
    [_clearBtn addTarget:self action:@selector(logViewBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_clearBtn];
    _clearBtn.translatesAutoresizingMaskIntoConstraints = NO;
    btnTrallingLayout =
    [NSLayoutConstraint constraintWithItem:_clearBtn
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:-trailingSpace];
    
    btnWidthLayout =
    [NSLayoutConstraint constraintWithItem:_clearBtn
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnHeightLayout =
    [NSLayoutConstraint constraintWithItem:_clearBtn
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnBottomLayout =
    [NSLayoutConstraint constraintWithItem:_clearBtn
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_lockBtn
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:-yBtnSpace];
    
    [_containerView addConstraint:btnWidthLayout];
    [_containerView addConstraint:btnHeightLayout];
    [_containerView addConstraint:btnTrallingLayout];
    [_containerView addConstraint:btnBottomLayout];
    
    _subBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _subBtn.backgroundColor = [UIColor grayColor];
    _subBtn.alpha = 0.8;
    _subBtn.layer.cornerRadius = 5;
    _subBtn.clipsToBounds = YES;
    _subBtn.layer.shouldRasterize = YES;
    [_subBtn setTitle:( CJF_IS_IPHONE_IDOM ? @"-" : @"sub" ) forState:UIControlStateNormal];
    [_subBtn addTarget:self action:@selector(logViewBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_subBtn];
    _subBtn.translatesAutoresizingMaskIntoConstraints = NO;
    btnTrallingLayout =
    [NSLayoutConstraint constraintWithItem:_subBtn
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:-trailingSpace];
    
    btnWidthLayout =
    [NSLayoutConstraint constraintWithItem:_subBtn
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnHeightLayout =
    [NSLayoutConstraint constraintWithItem:_subBtn
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnBottomLayout =
    [NSLayoutConstraint constraintWithItem:_subBtn
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_clearBtn
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:-yBtnSpace];
    
    [_containerView addConstraint:btnWidthLayout];
    [_containerView addConstraint:btnHeightLayout];
    [_containerView addConstraint:btnTrallingLayout];
    [_containerView addConstraint:btnBottomLayout];
    
    _addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _addBtn.backgroundColor = [UIColor grayColor];
    _addBtn.alpha = 0.8;
    _addBtn.layer.cornerRadius = 5;
    _addBtn.clipsToBounds = YES;
    _addBtn.layer.shouldRasterize = YES;
    [_addBtn setTitle:( CJF_IS_IPHONE_IDOM ? @"+" : @"add" ) forState:UIControlStateNormal];
    [_addBtn addTarget:self action:@selector(logViewBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_addBtn];
    _addBtn.translatesAutoresizingMaskIntoConstraints = NO;
    btnTrallingLayout =
    [NSLayoutConstraint constraintWithItem:_addBtn
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:-trailingSpace];
    
    btnWidthLayout =
    [NSLayoutConstraint constraintWithItem:_addBtn
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnHeightLayout =
    [NSLayoutConstraint constraintWithItem:_addBtn
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:0.0
                                  constant:btnWidth];
    
    btnBottomLayout =
    [NSLayoutConstraint constraintWithItem:_addBtn
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_subBtn
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:-yBtnSpace];
    
    [_containerView addConstraint:btnWidthLayout];
    [_containerView addConstraint:btnHeightLayout];
    [_containerView addConstraint:btnTrallingLayout];
    [_containerView addConstraint:btnBottomLayout];
    
    CGSize size = [self getFPSLabelSize];
    CGRect fpsRect = CGRectMake(_containerView.bounds.size.width - size.width - 50, 100, size.width, size.height);
    _fpsLabel = [[UILabel alloc] initWithFrame:fpsRect];
    _fpsLabel.numberOfLines = 6;
    _fpsLabel.font = [UIFont systemFontOfSize:12.f];
    _fpsLabel.textColor = [UIColor whiteColor];
    _fpsLabel.textAlignment = NSTextAlignmentCenter;
    _fpsLabel.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];
    [_containerView addSubview:_fpsLabel];
    [_containerView  bringSubviewToFront:_fpsLabel];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fpsLabelDidPan:)];
    [_fpsLabel addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fpsLabelDidTap:)];
    [_fpsLabel addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer* tapTwoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fpsLabelDidTapTwo:)];
    tapTwoGesture.numberOfTapsRequired = 2;
    [_fpsLabel addGestureRecognizer:tapTwoGesture];
    
    [tapGesture requireGestureRecognizerToFail:tapTwoGesture];
    
    _fpsLabel.userInteractionEnabled = YES;
    _fpsLabel.hidden = YES;
    [self setLogViewHidden:YES];
}

-(void)clearSubViews
{
    [_logView removeFromSuperview];
    [_addBtn removeFromSuperview];
    [_subBtn removeFromSuperview];
    [_clearBtn removeFromSuperview];
    [_lockBtn removeFromSuperview];
    [_fpsLabel removeFromSuperview];
    
    _logView = nil;
    _textView = nil;
    _addBtn = nil;
    _subBtn = nil;
    _clearBtn = nil;
    _lockBtn = nil;
    _fpsLabel = nil;
}

-(CGSize)getFPSLabelSize
{
    if( !_needShowMemory ){
        return CGSizeMake(60, 30);
    }else{
        return CGSizeMake(150, 120);
    }
}

//调整view在superView中的位置
-(void)adjustSubviewFrame:(CGRect)nowFrame withView:(UIView*)adjustView
{
    if( adjustView == nil || adjustView.superview == nil ){
        return;
    }
    
    UIView *superView = adjustView.superview;
    CGRect rect = superView.frame;
    CGRect newFrame = CGRectMake(MIN(rect.size.width - nowFrame.size.width, MAX(0, nowFrame.origin.x)),
                                 MIN(rect.size.height - nowFrame.size.height, MAX(0, nowFrame.origin.y)),
                                 nowFrame.size.width,
                                 nowFrame.size.height);
    
    [UIView animateWithDuration:0.2 animations:^{
        adjustView.frame = newFrame;
        adjustView.alpha = 1;
    }];
}

-(void)setLogViewHidden:(BOOL)hidden
{
    _logView.hidden = hidden;
    _addBtn.hidden = hidden;
    _subBtn.hidden = hidden;
    _clearBtn.hidden = hidden;
    _lockBtn.hidden = hidden;
}

#pragma mark - 对外接口
- (void)start:(UIView*)containerView
{
    NSAssert(pthread_main_np() > 0, @"CJFDebugMonitor: it's not main thread");
    NSAssert(containerView, @"CJFDebugMonitor: containerView must not nil");
    [self stop];
    _containerView = containerView;
    [self setupSubviews];
    [self setupDisplayLink];
    
    _scheduleTimes = 0;
    _timestamp = 0;
    [self setLogViewHidden:YES];
    [_displayLink setPaused:NO];
    _fpsLabel.hidden = NO;
    
    _textView.attributedText = CJF_early_attribute_string;
    CJF_early_attribute_string = [[NSAttributedString alloc] initWithString:@""];
}

- (void)stop
{
    NSAssert(pthread_main_np() > 0, @"CJFDebugMonitor: it's not main thread");
    
    [_displayLink setPaused:YES];
    if(_displayLink){
        [_displayLink invalidate];
        _displayLink = nil;
    }
    [self clearSubViews];
    _containerView = nil;
}

-(void)addLogStr:(NSString*)str andColor:(UIColor*)color
{
    NSAssert(pthread_main_np() > 0, @"CJFDebugMonitor: it's not main thread");
    
    if( ![str isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]  ){
        return;
    }
    NSAttributedString* attrStr = _textView ? _textView.attributedText : CJF_early_attribute_string;
    NSMutableAttributedString* mutAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:attrStr];
    NSAttributedString* newAttrStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName:color,NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0]}];
    [mutAttrStr appendAttributedString:newAttrStr];
    
    if( _textView ){
        CGFloat offsetY = _textView.contentOffset.y;
        CGFloat height = _textView.contentSize.height;
        _textView.attributedText = mutAttrStr;
        
        if( _textView.hidden == NO ){
            //当前用户在浏览历史内容时，不要自动滚动
            if( height - offsetY < 1.5 * _logHeight && _textView.contentSize.height - _logHeight  > 0 ){
                CGFloat height = _textView.contentSize.height;
                [_textView setContentOffset:CGPointMake(0, height - _logHeight)];
            }
        }
    }else{
        CJF_early_attribute_string = [mutAttrStr copy];
    }
}

#pragma mark - 定时器回调
- (void)linkTicks:(CADisplayLink *)link
{
    _scheduleTimes ++;
    
    if(_timestamp == 0){
        _timestamp = link.timestamp;
    }
    
    CFTimeInterval timePassed = link.timestamp - _timestamp;
    if(timePassed < 1.f/_frequency){
        return;
    }
    
    //fps
    int fps = MIN((int)round(_scheduleTimes/timePassed), 60);
    NSString*  memoryStr = @"";
    if( _needShowMemory ){
        static double s_allMemory = 0;
        if( s_allMemory == 0 ){
            s_allMemory = CJFFPS_AllMemory();
        }
        double allUseMemory = CJFFPS_usableMemory();
        double allFreeMemory = CJFFPS_freeMemory();
        double selfUseMemory = CJFFPS_usedMemory();
        memoryStr = [NSString stringWithFormat:@"\n---------\nallM:%.2f\nuseM:%.2f\nfreeM:%.2f\nselfM:%.2f",s_allMemory,allUseMemory,allFreeMemory,selfUseMemory];
    }
    
    //update label
    UIColor *fpsColor = nil;
    if(fps >= 55){
        fpsColor = [UIColor greenColor];
    }else if(fps >= 45){
        fpsColor = [UIColor yellowColor];
    }else{
        fpsColor = [UIColor redColor];
    }
    
    NSString *fpsStr = [NSString stringWithFormat:@"%ld", (long)fps];
    NSString *totalStr = [NSString stringWithFormat:@"%@ FPS%@",fpsStr,memoryStr];
    NSRange range = [totalStr rangeOfString:fpsStr];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:totalStr];
    [attributedString addAttribute:NSForegroundColorAttributeName value:fpsColor range:range];
    [_fpsLabel setAttributedText:attributedString];
    [_containerView bringSubviewToFront:_fpsLabel];
    
    //reset
    _timestamp = link.timestamp;
    _scheduleTimes = 0;
}

#pragma mark - notification
- (void)applicationDidBecomeActiveNotification {
    [_displayLink setPaused:NO];
}

- (void)applicationWillResignActiveNotification {
    [_displayLink setPaused:YES];
}

- (void)applicationWillChangeOrientationNotification {
    [self adjustSubviewFrame:_fpsLabel.frame withView:_fpsLabel];
}

#pragma mark - panGesture
- (void)fpsLabelDidPan:(UIPanGestureRecognizer *)sender
{
    UIView *superView = _fpsLabel.superview;
    if( superView  == nil ){
        return;
    }
    CGPoint position = [sender locationInView:superView];
    if(sender.state == UIGestureRecognizerStateBegan){
        _fpsLabel.alpha = 0.5;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        _fpsLabel.center = position;
    }else if(sender.state == UIGestureRecognizerStateEnded){
        [self adjustSubviewFrame:_fpsLabel.frame withView:_fpsLabel];
    }
}

- (void)fpsLabelDidTap:(UITapGestureRecognizer *)sender
{
    _needShowMemory = !_needShowMemory;
    CGRect rect = _fpsLabel.frame;
    CGSize size = [self getFPSLabelSize];
    rect.size.width = size.width;
    rect.size.height = size.height;
    [self adjustSubviewFrame:rect withView:_fpsLabel];
}

- (void)fpsLabelDidTapTwo:(UITapGestureRecognizer *)sender
{
    BOOL hidden = !_logView.hidden;
    [self setLogViewHidden:hidden];
    if( hidden == NO && _textView.contentSize.height > _logHeight ){
        [_textView setContentOffset:CGPointMake(0, _textView.contentSize.height - _logHeight)];
    }
}

-(void)logViewBtnClick:(UIButton*)sender
{
    if( sender == _lockBtn ){
        BOOL enabled = _logView.userInteractionEnabled;
        if( !enabled ){
            [sender setTitle:( CJF_IS_IPHONE_IDOM ? @"L" : @"lock") forState:UIControlStateNormal];
        }else{
            [sender setTitle:( CJF_IS_IPHONE_IDOM ? @"U" : @"unlk") forState:UIControlStateNormal];
        }
        _logView.userInteractionEnabled = !enabled;
    }else if ( sender == _clearBtn ){
        _textView.attributedText = [[NSAttributedString alloc] initWithString:@""];
        [_textView setContentOffset:CGPointZero];
    }else if ( sender == _subBtn ){
        if(_logHeight > CJF_min_log_height){
            _logHeight -= CJF_unit_log_height;
            _logViewHeight.constant = _logHeight;
            [_logView layoutIfNeeded];
        }
    }else if ( sender == _addBtn ){
        if(_logHeight < CJF_max_log_height){
            _logHeight += CJF_unit_log_height;
            _logViewHeight.constant = _logHeight;
            [_logView layoutIfNeeded];
        }
    }
}


@end
