//
//  NIMReplyContentView.m
//  NIMKit
//
//  Created by He on 2020/4/3.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMReplyContentView.h"
#import "UIView+NIM.h"
#import "UIColor+NIMKit.h"
#import "UIImage+NIMKit.h"

@interface NIMReplyContentView ()

@end

@implementation NIMReplyContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _blueView = [[UIView alloc] init];
        _blueView.backgroundColor = [UIColor colorWithHex:0xEFF2F9 alpha:1];
        _blueView.layer.cornerRadius = 10;
        _blueView.layer.masksToBounds = YES;
        [self addSubview:_blueView];
        
        _label = [[M80AttributedLabel alloc] init];
        _label.numberOfLines = 1;
        _label.textAlignment = kCTTextAlignmentLeft;
        _label.lineBreakMode = kCTLineBreakByTruncatingTail;
        _label.font = [UIFont systemFontOfSize:12];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor colorWithHex:0x8B929D alpha:1];
        [self addSubview:_label];
        
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage nim_imageInKit:@"icon_reply_close"]
                      forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];
        
//        _divider = [[UIView alloc] init];
//        _divider.backgroundColor = [UIColor colorWithHex:0xBFBFBF alpha:1];
//        _divider.nim_width = 1;
//        [self addSubview:_divider];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.closeButton.nim_size = CGSizeMake(20, 20);
    self.closeButton.nim_left = 0;
    self.closeButton.nim_centerY = self.nim_height * 0.5;
    
//    self.divider.nim_left = self.closeButton.nim_right + 2;
    
    self.label.nim_height = self.label.intrinsicContentSize.height + 5;
    self.label.nim_width = self.nim_width - 35;
    self.label.nim_left = 25;
    self.label.nim_centerY = self.nim_height * 0.5;
    
//    self.divider.nim_height = self.label.nim_height;
//    self.divider.nim_centerY = self.nim_height * .5f;
}

- (void)dismiss
{
    [self.closeButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)onClicked:(id)sender
{
    self.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(onClearReplyContent:)])
    {
        [self.delegate onClearReplyContent:sender];
    }
}

@end
