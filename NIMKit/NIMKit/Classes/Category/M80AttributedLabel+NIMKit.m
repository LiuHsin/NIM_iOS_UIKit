//
//  M80AttributedLabel+NIMKit
//  NIM
//
//  Created by chris.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "M80AttributedLabel+NIMKit.h"
#import "NIMInputEmoticonParser.h"
#import "NIMInputEmoticonManager.h"
#import "UIImage+NIMKit.h"
#import "NSString+NIMKit.h"
#import <objc/runtime.h>

static char * kOriLineBreakMode = "kOriLineBreakMode";

@implementation M80AttributedLabel (NIMKit)
- (void)nim_setText:(NSString *)text
{
    [self setText:@""];
    NSArray *tokens = [[NIMInputEmoticonParser currentParser] tokens:text];
    BOOL containEmojiUnicode = NO;
    for (NIMInputTextToken *token in tokens)
    {
        if (token.type == NIMInputTokenTypeEmoticon)
        {
            NIMInputEmoticon *emoticon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:token.text];
            UIImage *image = nil;

            if(emoticon.filename &&
               emoticon.filename.length>0 &&
                (image = [UIImage nim_emoticonInKit:emoticon.filename])!= nil) {
                if (image)
                {
                    CGSize maxSize = CGSizeMake(self.font.lineHeight, self.font.lineHeight);
                    [self appendImage:image
                              maxSize:maxSize];
                }
            } else if (emoticon.unicode && emoticon.unicode.length>0){
                [self appendText:emoticon.unicode];
                containEmojiUnicode = YES;
            }
            else {
                [self appendText:@"[?]"];
            }
        }
        else
        {
            NSString *text = token.text;
//            NSAttributedString *attr = [self messageStringTransforAttributeString:text];
//            self.attributedText = attr;
            [self appendText:text];
            containEmojiUnicode = [text nim_containsEmoji];
        }
    }

    if (containEmojiUnicode) {
        //emoji unicode word折行计算有点问题，先强制使用char折行
        [self setOriLineBreakMode:self.lineBreakMode];
        self.lineBreakMode = kCTLineBreakByCharWrapping;
    } else {
        self.lineBreakMode = [self oriLineBreakMode];
    }
}

- (void)setOriLineBreakMode:(CTLineBreakMode)lineBreakModel{
    objc_setAssociatedObject(self, kOriLineBreakMode, @(lineBreakModel), OBJC_ASSOCIATION_ASSIGN);
}

- (CTLineBreakMode)oriLineBreakMode{
    return (CTLineBreakMode)[objc_getAssociatedObject(self, kOriLineBreakMode)integerValue];
}

- (NSAttributedString *)messageStringTransforAttributeString:(NSString *)string {
//    NSError *error;
//    NSString *regularStr = @"(https?|http)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]";
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
//    NSArray *arrayOfAllMatches = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
//
//    NSMutableArray *arr = [[NSMutableArray alloc] init];
//    for (NSTextCheckingResult *match in arrayOfAllMatches) {
//        NSString *substringForMatch;
//        substringForMatch = [string substringWithRange:match.range];
//        [arr addObject:substringForMatch];
//    }
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:string];
    [attStr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, 1)];
    return attStr;
}


@end
