//
//  NIMLocationContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMLocationContentConfig.h"
#import "NIMKit.h"
@implementation NIMLocationContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    return CGSizeMake(260.f, 131.5f);
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionLocationContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    return [[NIMKit sharedKit].config setting:message].contentInsets;
}

@end
