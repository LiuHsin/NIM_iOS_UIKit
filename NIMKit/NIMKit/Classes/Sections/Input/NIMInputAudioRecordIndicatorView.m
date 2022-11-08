//
//  NIMInputAudioRecordIndicatorView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputAudioRecordIndicatorView.h"
#import "UIImage+NIMKit.h"
#import "NIMGlobalMacro.h"

#define NIMKit_ViewWidth 163
#define NIMKit_ViewHeight 125

#define NIMKit_TimeFontSize 14
#define NIMKit_TipFontSize 14

@interface NIMInputAudioRecordIndicatorView(){
    UIImageView *_whiteView;
    UIImageView *_orangeView;
    UIButton *_cancelBtn;
}

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation NIMInputAudioRecordIndicatorView
- (instancetype)init {
    self = [super init];
    if(self) {
        self.frame = CGRectMake(0, 0, NIMKit_ViewWidth, NIMKit_ViewHeight);
        _whiteView = [[UIImageView alloc] initWithImage:[UIImage nim_imageInKit:@"icon_input_record_indicator"]];
        _whiteView.frame = CGRectMake(0, 0, NIMKit_ViewWidth, CGRectGetHeight(_whiteView.bounds));
        [self addSubview:_whiteView];
        
        _orangeView = [[UIImageView alloc] initWithImage:[UIImage nim_imageInKit:@"icon_input_record_indicator_cancel"]];
        _orangeView.hidden = YES;
        _orangeView.frame = CGRectMake(0, 0, NIMKit_ViewWidth, CGRectGetHeight(_orangeView.bounds));
        [self addSubview:_orangeView];
        
        _cancelBtn = [UIButton buttonWithType: UIButtonTypeCustom];
        [_cancelBtn setImage:[UIImage nim_imageInKit:@"icon_input_record_cancel"] forState:UIControlStateNormal];
        [_cancelBtn setImage:[UIImage nim_imageInKit:@"icon_input_record_cancel_selected"] forState:UIControlStateSelected];
        _cancelBtn.frame = CGRectMake((NIMKit_ViewWidth - 40)/2, 85, 40, 40);
        [self addSubview:_cancelBtn];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.font = [UIFont fontWithName:@"" size:NIMKit_TimeFontSize];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"00: 00";
        [_whiteView addSubview:_timeLabel];
        
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [UIFont fontWithName:@"" size:NIMKit_TipFontSize];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"取消 发送".nim_localized;
        [_orangeView addSubview:_tipLabel];
        
        self.phase = AudioRecordPhaseEnd;
    }
    return self;
}

- (void)setRecordTime:(NSTimeInterval)recordTime {
    NSInteger minutes = (NSInteger)recordTime / 60;
    NSInteger seconds = (NSInteger)recordTime % 60;
    _timeLabel.text = [NSString stringWithFormat:@"%02zd: %02zd", minutes, seconds];
}

- (void)setPhase:(NIMAudioRecordPhase)phase {
    if(phase == AudioRecordPhaseStart) {
        [self setRecordTime:0];
        _cancelBtn.selected = NO;
    } else if(phase == AudioRecordPhaseCancelling) {
        _tipLabel.text = @"取消 发送".nim_localized;
        _orangeView.hidden = NO;
        _cancelBtn.selected = YES;
    } else {
        _tipLabel.text = @"取消 发送".nim_localized;
        _orangeView.hidden = YES;
        _cancelBtn.selected = NO;
    }
}

- (void)layoutSubviews {
    CGSize size = [_timeLabel sizeThatFits:CGSizeMake(NIMKit_ViewWidth, MAXFLOAT)];
    _timeLabel.frame = CGRectMake(0, 0, NIMKit_ViewWidth, size.height);
    _timeLabel.center = CGPointMake(_whiteView.center.x, _whiteView.center.y - 3);
    size = [_tipLabel sizeThatFits:CGSizeMake(NIMKit_ViewWidth, MAXFLOAT)];
    _tipLabel.frame = CGRectMake(0, 0, NIMKit_ViewWidth, size.height);
    _tipLabel.center = CGPointMake(_orangeView.center.x, _orangeView.center.y - 3);
}


@end
