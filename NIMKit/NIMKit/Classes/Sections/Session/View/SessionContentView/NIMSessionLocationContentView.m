//
//  NIMSessionLocationContentView.m
//  NIMKit
//
//  Created by chris on 15/2/28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionLocationContentView.h"
#import "NIMMessageModel.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMKit.h"

@interface NIMSessionLocationContentView()

@property (nonatomic,strong) UIImageView * imageView;

@property (nonatomic,strong) UILabel * titleLabel;

@property (nonatomic, strong) UILabel * detailLabel;

@property (nonatomic, strong) UIImage * leftImage;

@property (nonatomic, strong) UIImage * rightImage;

@end

@implementation NIMSessionLocationContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        self.opaque = YES;
        _leftImage = [UIImage nim_imageInKit:@"icon_map_left"];
        _rightImage = [UIImage nim_imageInKit:@"icon_map_right"];
        _imageView = [[UIImageView alloc] init];
        
//        CALayer *maskLayer = [CALayer layer];
//        maskLayer.cornerRadius = 13.0;
//        maskLayer.backgroundColor = [UIColor blackColor].CGColor;
//        maskLayer.frame = _imageView.bounds;
//        _imageView.layer.mask = maskLayer;

        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor colorWithRed:40/255.0 green:50/255.0 blue:67/255.0 alpha:1.0];
        [self addSubview:_titleLabel];
        
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.textAlignment = NSTextAlignmentLeft;
        _detailLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _detailLabel.numberOfLines = 0;
        _detailLabel.textColor = [UIColor colorWithRed:139/255.0 green:146/255.0 blue:157/255.0 alpha:1.0];
        [self addSubview:_detailLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data
{
    [super refresh:data];
    NIMMessage * message = self.model.message;
    NIMLocationObject * locationObject = (NIMLocationObject*)message.messageObject;
    if (message.isOutgoingMsg) {
        _imageView.image = _rightImage;
    } else {
        _imageView.image = _leftImage;
    }
    NSString * localStr = locationObject.title;
    NSArray *strArray = [localStr componentsSeparatedByString:@"@"];
    if (strArray.count == 2) {
        self.titleLabel.text = strArray[0];
        self.detailLabel.text = strArray[1];
    } else if (strArray.count) {
        self.titleLabel.text = strArray[0];
    } else {
        
    }
    
//    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:data.message];
//
//    self.titleLabel.textColor  = setting.textColor;
//    self.titleLabel.font       = setting.font;
}

- (void)onTouchUpInside:(id)sender
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapContent;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _titleLabel.nim_width = self.nim_width - 30;
    _titleLabel.nim_height= 21.f;
    self.titleLabel.nim_top = 10.f;
    self.titleLabel.nim_left = 15;
//    self.titleLabel.nim_centerX = self.nim_width * .5f;
    
    _detailLabel.nim_width = self.nim_width - 30;
    _detailLabel.nim_height= 16.5f;
    self.detailLabel.nim_top = 36.f;
    self.detailLabel.nim_left = 15;
    
//    UIEdgeInsets contentInsets  = self.model.contentViewInsets;
//
//    CGFloat tableViewWidth = self.superview.nim_width;
//    CGSize contentsize          = [self.model contentSize:tableViewWidth];
    
//    CGRect imageViewFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.imageView.frame  = self.bounds;
}


@end
