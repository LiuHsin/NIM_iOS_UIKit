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
        _label.numberOfLines = 2;
        _label.textAlignment = kCTTextAlignmentLeft;
        _label.lineBreakMode = kCTLineBreakByCharWrapping;
        _label.font = [UIFont systemFontOfSize:12];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor colorWithHex:0x8B929D alpha:1];
        [_blueView addSubview:_label];
        
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage nim_imageInKit:@"icon_reply_close"]
                      forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(onClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_blueView addSubview:_closeButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.blueView.nim_left = 65;
    self.blueView.nim_top = 0;
    self.blueView.nim_height = self.nim_height - 10;
    self.blueView.nim_width = self.nim_width - 80;
    
    self.closeButton.nim_size = CGSizeMake(20, 20);
    self.closeButton.nim_left = 0;
    self.closeButton.nim_centerY = self.blueView.nim_height * 0.5;
    
    
    self.label.nim_left = 25;
    self.label.nim_height = self.label.intrinsicContentSize.height;
    self.label.nim_width = self.blueView.nim_width - 35;
    self.label.nim_centerY = self.closeButton.nim_centerY + 1;
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
