//
//  NIMInputView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputView.h"
#import <AVFoundation/AVFoundation.h>
#import "NIMInputMoreContainerView.h"
#import "NIMInputEmoticonContainerView.h"
#import "NIMInputAudioRecordIndicatorView.h"
#import "UIView+NIM.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMInputEmoticonManager.h"
#import "NIMInputToolBar.h"
#import "UIImage+NIMKit.h"
#import "NIMGlobalMacro.h"
#import "NIMContactSelectViewController.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMKitKeyboardInfo.h"
#import "NSString+NIMKit.h"
#import "NIMReplyContentView.h"
#import "M80AttributedLabel+NIMKit.h"


@interface NIMInputView()<NIMInputToolBarDelegate,NIMInputEmoticonProtocol,NIMContactSelectDelegate,NIMReplyContentViewDelegate>
{
    UIView  *_emoticonView;
}

@property (nonatomic, strong) NIMInputAudioRecordIndicatorView *audioRecordIndicator;
@property (nonatomic, assign) NIMAudioRecordPhase recordPhase;
@property (nonatomic, weak) id<NIMSessionConfig> inputConfig;
@property (nonatomic, weak) id<NIMInputDelegate> inputDelegate;
@property (nonatomic, weak) id<NIMInputActionDelegate> actionDelegate;

@property (nonatomic, assign) CGFloat keyBoardFrameTop; //键盘的frame的top值，屏幕高度 - 键盘高度，由于有旋转的可能，这个值只有当 键盘弹出时才有意义。

@end


@implementation NIMInputView

@synthesize emoticonContainer = _emoticonContainer;
@synthesize moreContainer = _moreContainer;

- (instancetype)initWithFrame:(CGRect)frame
                       config:(id<NIMSessionConfig>)config
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _recording = NO;
        _recordPhase = AudioRecordPhaseEnd;
        _atCache = [[NIMInputAtCache alloc] init];
        _allCache = [[NSMutableArray alloc] init];
        _inputConfig = config;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)didMoveToWindow
{
    [self setup];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    //这里不做.语法 get 操作，会提前初始化组件导致卡顿
    CGFloat replyedContentHeight = _replyedContent.hidden ? 0 : _replyedContent.nim_height;
    CGFloat toolBarHeight = _toolBar.nim_height;
    CGFloat containerHeight = 0;
    switch (self.status)
    {
        case NIMInputStatusEmoticon:
        {
            containerHeight = _emoticonContainer.nim_height;
            break;
        }
        case NIMInputStatusMore:
        {
            containerHeight = _moreContainer.nim_height;
            break;
        }
        default:
        {
            UIEdgeInsets safeArea = UIEdgeInsetsZero;
            if (@available(iOS 11.0, *))
            {
                safeArea = self.superview.safeAreaInsets;
            }
            //键盘是从最底下弹起的，需要减去安全区域底部的高度
            CGFloat keyboardDelta = [NIMKitKeyboardInfo instance].keyboardHeight - safeArea.bottom;
            
            //如果键盘还没有安全区域高，容器的初始值为0；否则则为键盘和安全区域的高度差值，这样可以保证 toolBar 始终在键盘上面
            containerHeight = keyboardDelta>0 ? keyboardDelta : 0;
        }
           break;
    }
    CGFloat height = replyedContentHeight + toolBarHeight + containerHeight;
    CGFloat width = self.superview? self.superview.nim_width : self.nim_width;
    return CGSizeMake(width, height);
}


- (void)setInputDelegate:(id<NIMInputDelegate>)delegate
{
    _inputDelegate = delegate;
}

- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate
{
    _actionDelegate = actionDelegate;
}

- (void)reset
{
    self.nim_width = self.superview.nim_width;
    [self refreshStatus:NIMInputStatusText];
    [self sizeToFit];
}

- (void)refreshStatus:(NIMInputStatus)status
{
    self.status = status;
    [self.toolBar update:status];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.moreContainer.hidden = status != NIMInputStatusMore;
        self.emoticonContainer.hidden = status != NIMInputStatusEmoticon;
    });
}

- (NIMInputAudioRecordIndicatorView *)audioRecordIndicator {
    if(!_audioRecordIndicator) {
        _audioRecordIndicator = [[NIMInputAudioRecordIndicatorView alloc] init];
    }
    return _audioRecordIndicator;
}

- (void)setRecordPhase:(NIMAudioRecordPhase)recordPhase {
    NIMAudioRecordPhase prevPhase = _recordPhase;
    _recordPhase = recordPhase;
    self.audioRecordIndicator.phase = _recordPhase;
    if(prevPhase == AudioRecordPhaseEnd) {
        if(AudioRecordPhaseStart == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStartRecording)]) {
                [_actionDelegate onStartRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseStart || prevPhase == AudioRecordPhaseRecording) {
        if (AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStopRecording)]) {
                [_actionDelegate onStopRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseCancelling) {
        if(AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onCancelRecording)]) {
                [_actionDelegate onCancelRecording];
            }
        }
    }
}

- (void)setup
{
    if (!_toolBar)
    {
        _toolBar = [[NIMInputToolBar alloc] initWithFrame:CGRectMake(0, 0, self.nim_width, 0)];
    }
    [self addSubview:_toolBar];
    //设置placeholder
    NSString *placeholder = [NIMKit sharedKit].config.placeholder;
    [_toolBar setPlaceHolder:placeholder];
    
    //设置input bar 上的按钮
    if ([_inputConfig respondsToSelector:@selector(inputBarItemTypes)]) {
        NSArray *types = [_inputConfig inputBarItemTypes];
        [_toolBar setInputBarItemTypes:types];
    }
    
    _toolBar.delegate = self;
    [_toolBar.emoticonBtn addTarget:self action:@selector(onTouchEmoticonBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.moreMediaBtn addTarget:self action:@selector(onTouchMoreBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.voiceButton addTarget:self action:@selector(onTouchVoiceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    _toolBar.nim_size = [_toolBar sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_toolBar.recordButton setTitle:@"按住 说话".nim_localized forState:UIControlStateNormal];
    [_toolBar.recordButton setTitle:@"松开 发送" forState:UIControlStateHighlighted];
    [_toolBar.recordButton setTitleColor:[UIColor colorWithRed:40/255.0 green:50/255.0 blue:67/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_toolBar.recordButton setTitleColor:[UIColor colorWithRed:40/255.0 green:50/255.0 blue:67/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [_toolBar.recordButton.titleLabel setFont: [UIFont fontWithName:@"PingFangSC-Medium" size:14]];
    [_toolBar.recordButton setAdjustsImageWhenHighlighted: NO];
    [_toolBar.recordButton setHidden:YES];
    
    //设置最大输入字数
    NSInteger textInputLength = [NIMKit sharedKit].config.inputMaxLength;
    self.maxTextLength = textInputLength;
    
    [self refreshStatus:NIMInputStatusText];
    [self sizeToFit];
}

- (void)checkMoreContainer
{
    if (!_moreContainer) {
        NIMInputMoreContainerView *moreContainer = [[NIMInputMoreContainerView alloc] initWithFrame:CGRectZero];
        moreContainer.nim_size = [moreContainer sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        moreContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        moreContainer.hidden   = YES;
        moreContainer.config   = _inputConfig;
        moreContainer.actionDelegate = self.actionDelegate;
        _moreContainer = moreContainer;
    }
    
    //可能是外部主动设置进来的，统一放在这里添加 subview
    if (!_moreContainer.superview)
    {
        [self addSubview:_moreContainer];
    }
}

- (void)setMoreContainer:(UIView *)moreContainer
{
    _moreContainer = moreContainer;
    [self sizeToFit];
}

- (void)checkEmoticonContainer
{
    if (!_emoticonContainer) {
        NIMInputEmoticonContainerView *emoticonContainer = [[NIMInputEmoticonContainerView alloc] initWithFrame:CGRectZero];
        
        emoticonContainer.nim_size = [emoticonContainer sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        emoticonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        emoticonContainer.delegate = self;
        emoticonContainer.hidden = YES;
        emoticonContainer.config = _inputConfig;
        
        _emoticonContainer = emoticonContainer;
    }
    
    //可能是外部主动设置进来的，统一放在这里添加 subview
    if (!_emoticonContainer.superview)
    {
        [self addSubview:_emoticonContainer];
    }
}

- (void)setEmoticonContainer:(UIView *)emoticonContainer
{
    _emoticonContainer = emoticonContainer;
    [self sizeToFit];
}

- (void)setRecording:(BOOL)recording
{
    if(recording)
    {
        self.audioRecordIndicator.center = CGPointMake(NIMKit_UIScreenWidth / 2, NIMKit_UIScreenHeight - 189);
        [self.superview addSubview:self.audioRecordIndicator];
        self.recordPhase = AudioRecordPhaseRecording;
    }
    else
    {
        [self.audioRecordIndicator removeFromSuperview];
        self.recordPhase = AudioRecordPhaseEnd;
    }
    _recording = recording;
}

#pragma mark - 外部接口
- (void)setInputTextPlaceHolder:(NSString*)placeHolder
{
    [_toolBar setPlaceHolder:placeHolder];
}

- (void)updateAudioRecordTime:(NSTimeInterval)time {
    self.audioRecordIndicator.recordTime = time;
}

- (void)updateVoicePower:(float)power {
    
}

- (void)refreshReplyedContent:(NIMMessage *)message
{
//    NSString *text = [NSString stringWithFormat:@"%@", [[NIMKit sharedKit] replyedContentWithMessage:message]];
    NSString *labelText = nil;
    NSString *sendName = [[[NIMKit sharedKit] infoByUser:message.from option:nil] showName];
    NSString *content = [message text];
    if (message.messageType == NIMMessageTypeText || message.messageType == NIMMessageTypeCustom) {
        NSString *text = [sendName stringByAppendingFormat:@"：%@", content];
        labelText = text;
    } else if (message.messageType == NIMMessageTypeImage) {
        NSString *text = [sendName stringByAppendingFormat:@"：%@", @"[图片]"];
        labelText = text;
    } else if (message.messageType == NIMMessageTypeVideo) {
        NSString *text = [sendName stringByAppendingFormat:@"：%@", @"[视频]"];
        labelText = text;
    } else {
        labelText = @"";
    }
    [self.replyedContent.label nim_setText:labelText];

    self.replyedContent.hidden = NO;
    [self.replyedContent setNeedsLayout];
}

- (void)dismissReplyedContent
{
    self.replyedContent.label.text = nil;
    self.replyedContent.hidden = YES;
    [self setNeedsLayout];
}

- (void) atGroup {
    if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(atGroup)]) {
        [self.inputDelegate atGroup];
    }
}

#pragma mark - private methods

- (void)setFrame:(CGRect)frame
{
    CGFloat height = self.frame.size.height;
    [super setFrame:frame];
    if (frame.size.height != height)
    {
        [self callDidChangeHeight];
    }
}

- (void)callDidChangeHeight
{
    if (_inputDelegate && [_inputDelegate respondsToSelector:@selector(didChangeInputHeight:)])
    {
        if (self.status == NIMInputStatusMore || self.status == NIMInputStatusEmoticon || self.status == NIMInputStatusAudio)
        {
            //这个时候需要一个动画来模拟键盘
            [UIView animateWithDuration:0.25 delay:0 options:7 animations:^{
                [_inputDelegate didChangeInputHeight:self.nim_height];
            } completion:nil];
        }
        else
        {
            [_inputDelegate didChangeInputHeight:self.nim_height];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    //这里不做.语法 get 操作，会提前初始化组件导致卡顿
    if (!_replyedContent.hidden && _replyedContent != nil)
    {
        NSString *text = _replyedContent.label.text;
        CGSize size = [text nim_stringSizeWithFont: [UIFont systemFontOfSize:12]];
        CGFloat textW = size.width;
        CGFloat maxW = NIMKit_UIScreenWidth - 80;
        if (textW > maxW) {
            _replyedContent.nim_height = 47;
        } else {
            _replyedContent.nim_height = 30;
        }
        self.toolBar.nim_top = 0.f;
        _replyedContent.nim_top = self.toolBar.nim_bottom;
        _moreContainer.nim_top     = _replyedContent.nim_bottom;
        _emoticonContainer.nim_top = _replyedContent.nim_bottom;
    }
    else
    {
        self.toolBar.nim_top = 0.f;
        _moreContainer.nim_top     = self.toolBar.nim_bottom;
        _emoticonContainer.nim_top = self.toolBar.nim_bottom;
    }
}

- (NIMReplyContentView *)replyedContent
{
    if (!_replyedContent)
    {
        _replyedContent = [[NIMReplyContentView alloc] initWithFrame:CGRectMake(0, 0, self.nim_width, 30)];
        _replyedContent.hidden = YES;
        _replyedContent.delegate = self;
        [self addSubview:_replyedContent];
    }
    return _replyedContent;
}

- (void)setStatus:(NIMInputStatus)status
{
    if (_status != status)
    {
        _status = status;
        switch (_status) {
            case NIMInputStatusEmoticon:
                [self checkEmoticonContainer];
                break;
            case NIMInputStatusMore:
                [self checkMoreContainer];
            default:
                break;
        }
    }
}


#pragma mark - button actions
- (void)onTouchVoiceBtn:(id)sender {
    // image change
    if (self.status!= NIMInputStatusAudio) {
        if ([self.actionDelegate respondsToSelector:@selector(onTapVoiceBtn:)]) {
            [self.actionDelegate onTapVoiceBtn:sender];
        }
        __weak typeof(self) weakSelf = self;
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf refreshStatus:NIMInputStatusAudio];
                        if (weakSelf.toolBar.showsKeyboard)
                        {
                            weakSelf.toolBar.showsKeyboard = NO;
                        }
                        [weakSelf sizeToFit];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"没有麦克风权限".nim_localized
                                                   delegate:nil
                                          cancelButtonTitle:@"确定".nim_localized
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    else
    {
        if ([self.toolBar.inputBarItemTypes containsObject:@(NIMInputBarItemTypeTextAndRecord)])
        {
            [self refreshStatus:NIMInputStatusText];
            self.toolBar.showsKeyboard = YES;
        }
    }
}

- (IBAction)onTouchRecordBtnDown:(id)sender {
    self.recordPhase = AudioRecordPhaseStart;
}
- (IBAction)onTouchRecordBtnUpInside:(id)sender {
    // finish Recording
    self.recordPhase = AudioRecordPhaseEnd;
}
- (IBAction)onTouchRecordBtnUpOutside:(id)sender {
    // cancel Recording
    self.recordPhase = AudioRecordPhaseEnd;
}

- (IBAction)onTouchRecordBtnDragInside:(id)sender {
    // "手指上滑，取消发送"
    self.recordPhase = AudioRecordPhaseRecording;
}
- (IBAction)onTouchRecordBtnDragOutside:(id)sender {
    // "松开手指，取消发送"
    self.recordPhase = AudioRecordPhaseCancelling;
}


- (void)onTouchEmoticonBtn:(id)sender
{
    if (self.status != NIMInputStatusEmoticon) {
        if ([self.actionDelegate respondsToSelector:@selector(onTapEmoticonBtn:)]) {
            [self.actionDelegate onTapEmoticonBtn:sender];
        }
        [self checkEmoticonContainer];
        [self bringSubviewToFront:self.emoticonContainer];
        [self.emoticonContainer setHidden:NO];
        [self.moreContainer setHidden:YES];
        [self refreshStatus:NIMInputStatusEmoticon];
        [self sizeToFit];
        
        
        if (self.toolBar.showsKeyboard)
        {
            self.toolBar.showsKeyboard = NO;
        }
    }
    else
    {
        [self refreshStatus:NIMInputStatusText];
        self.toolBar.showsKeyboard = YES;
    }
}

- (void)onTouchMoreBtn:(id)sender {
    if (self.status != NIMInputStatusMore)
    {
        if ([self.actionDelegate respondsToSelector:@selector(onTapMoreBtn:)]) {
            [self.actionDelegate onTapMoreBtn:sender];
        }
        [self checkMoreContainer];
        [self bringSubviewToFront:self.moreContainer];
        [self.moreContainer setHidden:NO];
        [self.emoticonContainer setHidden:YES];
        [self refreshStatus:NIMInputStatusMore];
        [self sizeToFit];

        if (self.toolBar.showsKeyboard)
        {
            self.toolBar.showsKeyboard = NO;
        }
    }
    else
    {
        [self refreshStatus:NIMInputStatusText];
        self.toolBar.showsKeyboard = YES;
    }
}

- (BOOL)endEditing:(BOOL)force
{
    BOOL endEditing = [super endEditing:force];
    if (!self.toolBar.showsKeyboard) {
        UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
        
        __weak typeof(self) weakSelf = self;
        void(^animations)(void) = ^{
            [weakSelf refreshStatus:NIMInputStatusText];
            [weakSelf sizeToFit];
            if (weakSelf.inputDelegate && [weakSelf.inputDelegate respondsToSelector:@selector(didChangeInputHeight:)]) {
                [weakSelf.inputDelegate didChangeInputHeight:weakSelf.nim_height];
            }
        };
        NSTimeInterval duration = 0.25;
        [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
    }
    return endEditing;
}


#pragma mark - NIMInputToolBarDelegate

- (BOOL)textViewShouldBeginEditing
{
    [self refreshStatus:NIMInputStatusText];
    return YES;
}

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self didPressSend:nil];
        return NO;
    }
    if ([text isEqualToString:@""] && range.length == 1 )
    {
        //非选择删除
        return [self onTextDelete];
    }
    if ([self shouldCheckAt])
    {
        // @ 功能
        [self checkAt:text];
    }
    NSString *str = [self.toolBar.contentText stringByAppendingString:text];
    if (str.length > self.maxTextLength)
    {
        return NO;
    }
    return YES;
}

- (BOOL)shouldCheckAt
{
    BOOL disable = NO;
    if ([self.inputConfig respondsToSelector:@selector(disableAt)])
    {
        disable = [self.inputConfig disableAt];
    }
    return !disable;
}

- (void)checkAt:(NSString *)text
{
    if ([text isEqualToString:NIMInputAtStartChar]) {
        switch (self.session.sessionType)
        {
            case NIMSessionTypeTeam:
            {
                NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
                config.teamType = NIMKitTeamTypeNomal;
                config.needMutiSelected = NO;
                config.teamId = self.session.sessionId;
                config.session = self.session;
                config.filterIds = @[[NIMSDK sharedSDK].loginManager.currentAccount];
                [self atGroup];
//                NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
//                vc.delegate = self;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [vc show];
//                });
            }
                break;
            case NIMSessionTypeSuperTeam:
            {
                NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
                config.teamType = NIMKitTeamTypeSuper;
                config.needMutiSelected = NO;
                config.teamId = self.session.sessionId;
                config.session = self.session;
                config.filterIds = @[[NIMSDK sharedSDK].loginManager.currentAccount];
                [self atGroup];
//                NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
//                vc.delegate = self;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [vc show];
//                });
            }
                break;
            case NIMSessionTypeP2P:
                break;
            case NIMSessionTypeChatroom:
                break;
            default:
                break;
        }
    }
}


- (void)textViewDidChange
{
    if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(onTextChanged:)])
    {
        [self.actionDelegate onTextChanged:self];
    }
}


- (void)toolBarDidChangeHeight:(CGFloat)height
{
    [self sizeToFit];
}

- (void)addAtItems:(NSArray *)selectedContacts
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@"@"];
    [self addContacts:selectedContacts prefix:str];
}

#pragma mark - NIMContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    [self addContacts:selectedContacts prefix:str];
}

- (void)addContacts:(NSArray *)selectedContacts prefix:(NSMutableString *)str
{
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = self.session;
    option.forbidaAlias = YES;
    for (NSString *uid in selectedContacts) {
        NSString *nick = [[NIMKit sharedKit].provider infoByUser:uid option:option].showName;
        [str appendString:nick];
        [str appendString:NIMInputAtEndChar];
        if (![selectedContacts.lastObject isEqualToString:uid]) {
            [str appendString:NIMInputAtStartChar];
        }
        NIMInputAtItem *item = [[NIMInputAtItem alloc] init];
        item.uid  = uid;
        item.name = nick;
        [self.atCache addAtItem:item];
    }
    [self.toolBar insertText:str];
}

#pragma mark - InputEmoticonProtocol
- (void)selectedEmoticon:(NSString*)emoticonID catalog:(NSString*)emotCatalogID description:(NSString *)description{
    if (!emotCatalogID) { //删除键
        [self doButtonDeleteText];
    }else{
        if ([emotCatalogID isEqualToString:NIMKit_EmojiCatalog]) {
            [self.toolBar insertText:description];
        }else{
            //发送贴图消息
            if ([self.actionDelegate respondsToSelector:@selector(onSelectChartlet:catalog:)]) {
                [self.actionDelegate onSelectChartlet:emoticonID catalog:emotCatalogID];
            }
        }
    }
}

- (void)didPressSend:(id)sender{
    if ([self.actionDelegate respondsToSelector:@selector(onSendText:atUsers:)] && [self.toolBar.contentText length] > 0) {
        NSString *sendText = self.toolBar.contentText;
        NSArray *userArray = [self.allCache copy];
        if ([userArray count] != 0) {
            [self.actionDelegate onSendText:sendText atUsers: userArray];
        } else {
           [self.actionDelegate onSendText:sendText atUsers:[self.atCache allAtUid:sendText]];
        }
        [self.allCache removeAllObjects];
        [self.atCache clean];
        self.toolBar.contentText = @"";
        [self.toolBar layoutIfNeeded];
    }
}



- (BOOL)onTextDelete
{
    NSRange range = [self delRangeForEmoticon];
    if (range.length == 1)
    {
        //删的不是表情，可能是@
        NIMInputAtItem *item = [self delRangeForAt];
        if (item) {
            range = item.range;
        }
    }
    if (range.length == 1) {
        //自动删除
        return YES;
    }
    [self.toolBar deleteText:range];
    return NO;
}

- (BOOL)doButtonDeleteText
{
    NSRange range = [self delRangeForLastComponent];
    if (range.length == 1)
    {
        //删的不是表情，可能是@
        NIMInputAtItem *item = [self delRangeForAt];
        if (item) {
            range = item.range;
        }
    }
    
    [self.toolBar deleteText:range];
    return NO;
}


- (NSRange)delRangeForEmoticon
{
    NSString *text = self.toolBar.contentText;
    NSRange selectedRange = [self.toolBar selectedRange];
    BOOL isEmoji = NO;
    if (selectedRange.location >= 2) {
        NSString *subStr = [text substringWithRange:NSMakeRange(selectedRange.location - 2, 2)];
        isEmoji = [subStr nim_containsEmoji];
    }
    
    NSRange range = NSMakeRange(selectedRange.location - 1, 1);
    if (isEmoji) {
        range = NSMakeRange(selectedRange.location-2, 2);
    } else {
        NSRange subRange = [self rangeForPrefix:@"[" suffix:@"]"];
        if (subRange.length > 1)
        {
            NSString *name = [text substringWithRange:subRange];
            NIMInputEmoticon *icon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:name];
            range = icon? subRange : NSMakeRange(selectedRange.location - 1, 1);
        }
    }

    return range;
}

- (NSRange)delRangeForLastComponent
{
    NSString *text = self.toolBar.contentText;
    NSRange selectedRange = [self.toolBar selectedRange];
    if (selectedRange.location == 0)
    {
        return NSMakeRange(0, 0) ;
    }
    
    NSRange range;
    NSRange subRange = [self rangeForPrefix:@"[" suffix:@"]"];
    
    if (text.length > 0 &&
        [[text substringFromIndex:text.length - 1] isEqualToString:@"]"] &&
        subRange.length > 1)
    {
        NSString *name = [text substringWithRange:subRange];
        NIMInputEmoticon *icon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:name];
        range = icon? subRange : NSMakeRange(selectedRange.location - 1, 1);
    }
    else
    {
        range = [text nim_rangeOfLastUnicode];
    }

    return range;
}


- (NIMInputAtItem *)delRangeForAt
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self rangeForPrefix:NIMInputAtStartChar suffix:NIMInputAtEndChar];
    NSRange selectedRange = [self.toolBar selectedRange];
    NIMInputAtItem *item = nil;
    if (range.length > 1)
    {
        NSString *name = [text substringWithRange:range];
        NSString *set = [NIMInputAtStartChar stringByAppendingString:NIMInputAtEndChar];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:set]];
        item = [self.atCache item:name];
        range = item? range : NSMakeRange(selectedRange.location - 1, 1);
    }
    item.range = range;
    return item;
}


- (NSRange)rangeForPrefix:(NSString *)prefix suffix:(NSString *)suffix
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self.toolBar selectedRange];
    NSString *selectedText = range.length ? [text substringWithRange:range] : text;
    NSInteger endLocation = range.location;
    if (endLocation <= 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger index = -1;
    if ([selectedText hasSuffix:suffix]) {
        //往前搜最多20个字符，一般来讲是够了...
        NSInteger p = 20;
        for (NSInteger i = endLocation; i >= endLocation - p && i-1 >= 0 ; i--)
        {
            NSRange subRange = NSMakeRange(i - 1, 1);
            NSString *subString = [text substringWithRange:subRange];
            if ([subString compare:prefix] == NSOrderedSame)
            {
                index = i - 1;
                break;
            }
        }
    }
    return index == -1? NSMakeRange(endLocation - 1, 1) : NSMakeRange(index, endLocation - index);
}

#pragma mark - NIMReplyContentViewDelegate

- (void)onClearReplyContent:(id)sender
{
    [self sizeToFit];
//    [self setNeedsLayout];
//    self.toolBar.inputTextView.text = nil;
    if ([self.actionDelegate respondsToSelector:@selector(didReplyCancelled)])
    {
        [self.actionDelegate didReplyCancelled];
    }
}

@end
