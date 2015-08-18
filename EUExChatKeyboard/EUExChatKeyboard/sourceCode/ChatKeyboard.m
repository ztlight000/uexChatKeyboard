//
//  ChatKeyboard.m
//  EUExChatKeyboard
//
//  Created by xurigan on 14/12/12.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "ChatKeyboard.h"
#import "ChatKeyboardData.h"

#define UEX_SHARE_PIC_ITEM @"uexChatKeyboard/shareResource/sharemore_pic_ios7@2x"
#define UEX_SHARE_VIDEO_ITEM @"uexChatKeyboard/shareResource/sharemore_video_ios7@2x"
#define UEX_SHARE_LOC_ITEM @"uexChatKeyboard/shareResource/sharemore_location_ios7@2x"
#define UEX_SHARE_VOIP_ITEM @"uexChatKeyboard/shareResource/sharemore_videovoip@2x"
#define UEX_SEND_FACE_NORMAL @"uexChatKeyboard/messageInputViewResource/EmotionsSendBtnGrey@2x"
#define UEX_SEND_FACE_HL @"uexChatKeyboard/messageInputViewResource/EmotionsSendBtnBlueHL@2x"

#define isSysVersionAbove7_0 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define UEX_SCREENWIDTH (isSysVersionAbove7_0?[UIScreen mainScreen].bounds.size.width:[UIScreen mainScreen].applicationFrame.size.width)
#define UEX_SCREENHEIGHT (isSysVersionAbove7_0?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].applicationFrame.size.height)

@implementation ChatKeyboard

-(instancetype)initWithUexobj:(EUExChatKeyboard *)uexObj{
    if (self = [super init]) {
        self.uexObj = uexObj;
        self.animationDuration = 0.25;
        self.isInit = YES;
        self.keyboardStatus = @"0";
    }
    return self;
}

-(void)removeViewAndSubviewsFromSuperview:(UIView *)view{
    if ([view.subviews count] == 0) {
        [view removeFromSuperview];
    } else {
        for (UIView * subview in view.subviews) {
            [self removeViewAndSubviewsFromSuperview:subview];
        }
        [view removeFromSuperview];
    }
}

-(void)close {

    if (self.messageToolView) {
        [self removeViewAndSubviewsFromSuperview:self.messageToolView];
        self.messageToolView = nil;
    }
    if (self.sendButton) {
        [self removeViewAndSubviewsFromSuperview:self.sendButton];
        self.sendButton = nil;
    }
    if (self.faceView) {
        [self removeViewAndSubviewsFromSuperview:self.faceView];
        self.faceView = nil;
    }
    if (self.shareMenuView) {
        [self removeViewAndSubviewsFromSuperview:self.shareMenuView];
        self.shareMenuView = nil;
    }
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}

- (void)hideKeyboard {
    
    
    
    if (CGRectGetMaxY(self.messageToolView.frame) < UEX_SCREENHEIGHT) {
        
        [self messageViewAnimationWithMessageRect:self.keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
    
    
    
}

-(void)open {
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardChange:)
                                                name:UIKeyboardDidChangeFrameNotification
                                              object:nil];
    
    
    if ([[[UIDevice currentDevice]systemVersion]floatValue]>=7) {
        _inputViewHeight = 45.0f;
    }
    else{
        _inputViewHeight = 40.0f;
    }
    
    self.messageToolView = [[ZBMessageInputView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT - _inputViewHeight,UEX_SCREENWIDTH,_inputViewHeight)];
    
    self.messageToolView.delegate = self;
    [EUtility brwView:self.uexObj.meBrwView addSubview:self.messageToolView];
    
//    CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
//    tempRect.size.height = CGRectGetMinY(self.messageToolView.frame);
//    self.uexObj.meBrwView.scrollView.frame = tempRect;
    
    
    [self shareFaceView];
    [self shareShareMeun];
}

- (void)shareFaceView{
    
    if (!self.faceView) {
        self.faceView = [[ZBMessageManagerFaceView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT, UEX_SCREENWIDTH, 196) andFacePath:self.facePath];
        self.faceView.delegate = self;
        [EUtility brwView:self.uexObj.meBrwView addSubview:self.faceView];
        
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.sendButton.frame = CGRectMake(UEX_SCREENWIDTH-70, CGRectGetMaxY(self.faceView.frame)+3, 70, 37);
        [self.sendButton setTitle:@"  发送" forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.sendButton setBackgroundColor:[UIColor blueColor]];
        self.sendButton.layer.borderWidth = 0.5f;
        self.sendButton.layer.borderColor = [[UIColor grayColor]CGColor];
        [self.sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:UEX_SEND_FACE_NORMAL ofType:@"png"]] forState:UIControlStateNormal];
        [self.sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:UEX_SEND_FACE_HL ofType:@"png"]] forState:UIControlStateHighlighted];
        [EUtility brwView:self.uexObj.meBrwView addSubview:self.sendButton];
        [self.sendButton addTarget:self action:@selector(sendButtonDidClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
}

-(void)sendButtonDidClicked:(id)sender {
    [self didSendTextAction:self.messageToolView.messageInputTextView];
    [self messageViewAnimationWithMessageRect:CGRectZero
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:0.25
                                     andState:ZBMessageViewStateShowNone];
}

- (void)shareShareMeun
{
    if (!self.shareMenuView)
    {
        self.shareMenuView = [[ZBMessageShareMenuView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT,UEX_SCREENWIDTH, 196)];
        [EUtility brwView:self.uexObj.meBrwView addSubview:self.shareMenuView];

        self.shareMenuView.delegate = self;
        
        NSMutableArray * itemArray = [NSMutableArray array];
        int count = (int)[ChatKeyboardData sharedChatKeyboardData].shareArray.count;
        
        for (int i = 0; i < count; i++) {
            NSString * imgStr = [[[ChatKeyboardData sharedChatKeyboardData].shareImgArray objectAtIndex:i] objectForKey:@"text"];
            NSString * imgPath = [NSString stringWithFormat:@"%@%@",[ChatKeyboardData sharedChatKeyboardData].sharePath,imgStr];
            UIImage * image = [UIImage imageWithContentsOfFile:imgPath];
            
            NSString * imgTitle = [[[ChatKeyboardData sharedChatKeyboardData].shareArray objectAtIndex:i] objectForKey:@"text"];
            
            ZBMessageShareMenuItem * shareItem = [[ZBMessageShareMenuItem alloc]initWithNormalIconImage:image title:imgTitle];
            [itemArray addObject:shareItem];
        }
        
        self.shareMenuView.shareMenuItems = [NSArray arrayWithArray:itemArray];
        [self.shareMenuView reloadData];
        
    }
}


- (void)changeWebView:(float)height {
    
    
    CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
    tempRect.size.height = CGRectGetMinY(self.messageToolView.frame);
    self.uexObj.meBrwView.scrollView.frame = tempRect;
    
    float yy = self.uexObj.meBrwView.frame.origin.y;
    
    if (CGRectGetMidY(self.messageToolView.frame) < yy + height) {
        
        
        
        [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, yy + height - CGRectGetMinY(self.messageToolView.frame))];
        
        
        
        
    }
    
    
    
    
}

#pragma mark - messageView animation
- (void)messageViewAnimationWithMessageRect:(CGRect)rect  withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state{
    
    //if (state != ZBMessageViewStateShowNone) {
        duration = 0.0;
    //} else {
     //   duration += 0.1;
    //}
    
    [UIView animateWithDuration:duration animations:^{
        
        self.messageToolView.frame = CGRectMake(0.0f,UEX_SCREENHEIGHT-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect),UEX_SCREENWIDTH,CGRectGetHeight(inputViewRect));
        
        CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
        tempRect.size.height = CGRectGetMinY(self.messageToolView.frame);
        self.uexObj.meBrwView.scrollView.frame = tempRect;
        
        
        
        
        switch (state) {
                
            case ZBMessageViewStateShowFace:
            {
                
                self.faceView.frame = CGRectMake(0.0f, UEX_SCREENHEIGHT - CGRectGetHeight(rect), UEX_SCREENWIDTH, CGRectGetHeight(rect));
                
                self.shareMenuView.frame = CGRectMake(0.0f, UEX_SCREENHEIGHT, UEX_SCREENWIDTH, CGRectGetHeight(self.shareMenuView.frame));
                
            }
                break;
                
            case ZBMessageViewStateShowNone:
            {
                
                self.faceView.frame = CGRectMake(0.0f,UEX_SCREENHEIGHT-CGRectGetHeight(rect),UEX_SCREENWIDTH,CGRectGetHeight(self.faceView.frame));
                
                self.shareMenuView.frame = CGRectMake(0.0f,UEX_SCREENHEIGHT,UEX_SCREENWIDTH,CGRectGetHeight(self.shareMenuView.frame));
                
            }
                break;
                
            case ZBMessageViewStateShowShare:
            {
                self.shareMenuView.frame = CGRectMake(0.0f,UEX_SCREENHEIGHT-CGRectGetHeight(rect),UEX_SCREENWIDTH,CGRectGetHeight(rect));
                
                self.faceView.frame = CGRectMake(0.0f,UEX_SCREENHEIGHT,UEX_SCREENWIDTH,CGRectGetHeight(self.faceView.frame));
                
            }
                break;
                
            default:
                
                break;
                
        }
        
        CGRect tmpRect = self.sendButton.frame;
        tmpRect.origin.y = CGRectGetMaxY(self.faceView.frame)-37;
        self.sendButton.frame = tmpRect;
        
    } completion:^(BOOL finished) {
        
    }];
    
    NSString * status = @"0";
    
    if (CGRectGetHeight(rect) > 0) {
        status = @"1";
    } else{
        if (self.uexObj.meBrwView.scrollView.frame.size.height >= self.uexObj.meBrwView.scrollView.contentOffset.y) {
            [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, 0)];
        } else {
            [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, self.uexObj.meBrwView.scrollView.contentOffset.y)];
        }
        
    }
    
    NSDictionary * jsDic = [NSDictionary dictionaryWithObject:status forKey:@"status"];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onKeyBoardShow!=null){uexChatKeyboard.onKeyBoardShow(\'%@\');}", [jsDic JSONFragment]];
    
    //if (![status isEqualToString:_keyboardStatus]) {
        //_keyboardStatus = status;
        [self performSelectorOnMainThread:@selector(onKeyboardShowCallback:) withObject:jsStr waitUntilDone:NO];
    //}
    
}

- (void)onKeyboardShowCallback:(id)userInfo {
    
    NSString *jsStr = (NSString *)userInfo;
    
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
}

#pragma end

#pragma mark - ZBMessageInputView Delegate
- (void)didSelectedMultipleMediaAction:(BOOL)changed{
    
    if (changed)
    {
        [self messageViewAnimationWithMessageRect:self.shareMenuView.frame
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowShare];
    }
    else{
        [self messageViewAnimationWithMessageRect:self.keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
    
}

- (void)didSendFaceAction:(BOOL)sendFace{
    if (sendFace) {
        [self messageViewAnimationWithMessageRect:self.faceView.frame
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowFace];
    }
    else{
        [self messageViewAnimationWithMessageRect:self.keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
}

- (void)didChangeSendVoiceAction:(BOOL)changed{
    if (changed){
        [self messageViewAnimationWithMessageRect:CGRectZero
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
    else{
        [self messageViewAnimationWithMessageRect:self.keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:self.animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
}

/*
 * 点击输入框代理方法
 */
- (void)inputTextViewWillBeginEditing:(ZBMessageTextView *)messageInputTextView{
    
}

- (void)inputTextViewDidBeginEditing:(ZBMessageTextView *)messageInputTextView
{
    [self messageViewAnimationWithMessageRect:self.keyboardRect
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:self.animationDuration
                                     andState:ZBMessageViewStateShowNone];
    
    if (!self.previousTextViewContentHeight)
    {
        self.previousTextViewContentHeight = messageInputTextView.contentSize.height;
    }
}



- (void)inputTextViewDidChange:(ZBMessageTextView *)messageInputTextView
{
    if (_isInit) {
        self.previousTextViewContentHeight = messageInputTextView.contentSize.height;
        _isInit = NO;
    }
    
    CGFloat maxHeight = [ZBMessageInputView maxHeight];
    CGSize size = [messageInputTextView sizeThatFits:CGSizeMake(CGRectGetWidth(messageInputTextView.frame), maxHeight)];
    CGFloat textViewContentHeight = size.height;
    
    // End of textView.contentSize replacement code
    BOOL isShrinking = textViewContentHeight < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    
    if(!isShrinking && self.previousTextViewContentHeight == maxHeight) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }

    
    if(changeInHeight != 0.0f) {
        
        [UIView animateWithDuration:0.01f
                         animations:^{
                             
                             if(isShrinking) {
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.messageToolView adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.messageToolView.frame;
                             self.messageToolView.frame = CGRectMake(0.0f,
                                                                     inputViewFrame.origin.y - changeInHeight,
                                                                     inputViewFrame.size.width,
                                                                     inputViewFrame.size.height + changeInHeight);
                             
                             if(!isShrinking) {
                                 [self.messageToolView adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                             
                         }];
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }
}
/*
 * 发送信息
 */
- (void)didSendTextAction:(ZBMessageTextView *)messageInputTextView
{
    
    NSDictionary * jsDic = [NSDictionary dictionaryWithObject:messageInputTextView.text forKey:@"emojiconsText"];
    
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onCommit!=null){uexChatKeyboard.onCommit(\'%@\');}", [jsDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
    NSString *cbJsonStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onCommitJson!=null){uexChatKeyboard.onCommitJson(%@);}", [jsDic JSONFragment]];
    
    NSDictionary * cbDic = [NSDictionary dictionaryWithObject:cbJsonStr forKey:@"cbKey"];
    
    NSString * cbjson = [cbDic objectForKey:@"cbKey"];
    
    
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:cbjson];

    [messageInputTextView resignFirstResponder];
    [messageInputTextView setText:nil];
    [self inputTextViewDidChange:messageInputTextView];
}




#pragma end
#pragma mark - ZBMessageFaceViewDelegate
- (void)SendTheFaceStr:(NSString *)faceStr isDelete:(BOOL)dele
{
    NSString * oldMsg = self.messageToolView.messageInputTextView.text;
    if (dele && [oldMsg length] > 0) {
        
        [self.messageToolView.messageInputTextView deleteBackward];
        
    } else if (!dele) {
        
        self.messageToolView.messageInputTextView.text = [oldMsg stringByAppendingString:faceStr];
        [self inputTextViewDidChange:self.messageToolView.messageInputTextView];
        
    }
    
}
#pragma end


-(void)doActionWithSelectShareMenuItemIndex:(NSInteger)index{
    
    switch (index) {
        case 0:
            //
            break;
        case 1:
            //
            break;
        case 2:
            //
            break;
    }
    
}



#pragma mark - ZBMessageShareMenuView Delegate
- (void)didSelecteShareMenuItem:(ZBMessageShareMenuItem *)shareMenuItem atIndex:(NSInteger)index{
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onShareMenuItem!=null){uexChatKeyboard.onShareMenuItem(%d);}", (int)index];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    [self doActionWithSelectShareMenuItemIndex:index];
    [self messageViewAnimationWithMessageRect:CGRectZero
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:0.25
                                     andState:ZBMessageViewStateShowNone];
    
}
#pragma end

- (void)keyboardWillHide:(NSNotification *)notification {
    
    
    [self messageViewAnimationWithMessageRect:CGRectZero
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:0.0
                                     andState:ZBMessageViewStateShowNone];
    
}

- (void)keyboardWillShow:(NSNotification *)notification{
    self.keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.animationDuration= [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
}

- (void)keyboardChange:(NSNotification *)notification{
    if ([[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y<CGRectGetHeight(self.uexObj.meBrwView.frame)) {
        [self messageViewAnimationWithMessageRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:0.25
                                         andState:ZBMessageViewStateShowNone];
    }
}

-(void)willCancelRecordingVoiceAction{
    UIImage * image = [UIImage imageNamed:@"uexChatKeyboard/voiceResource/touchDragOutside"];
    if ([ChatKeyboardData sharedChatKeyboardData].dragOutsideImg) {
        UIImage * tempImg = [UIImage imageWithContentsOfFile:[ChatKeyboardData sharedChatKeyboardData].dragOutsideImg];
        if (tempImg) {
            image = tempImg;
        }
    }
    [_v changeImage:image andHiddenSecondLabel:YES];
}

-(void)stopCancelRecordingVoiceAction{
    UIImage * image = [UIImage imageNamed:@"uexChatKeyboard/voiceResource/touchdown"];
    if ([ChatKeyboardData sharedChatKeyboardData].touchDownImg) {
        UIImage * tempImg = [UIImage imageWithContentsOfFile:[ChatKeyboardData sharedChatKeyboardData].touchDownImg];
        if (tempImg) {
            image = tempImg;
        }
    }
    [_v changeImage:image andHiddenSecondLabel:NO];
}

-(void)didTimeOut{
    NSDictionary * cbDic = [NSDictionary dictionaryWithObjectsAndKeys:@"2",@"status",@"2",@"voicePath", nil];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onVoiceAction!=null){uexChatKeyboard.onVoiceAction(\'%@\');}", [cbDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    [self removeViewAndSubviewsFromSuperview:_v];
    _v.delegate = nil;
    
    _messageToolView.holdDownButton.selected = NO;
    _messageToolView.holdDownButton.highlighted = NO;
}

/**
 *  按下录音按钮开始录音
 */
- (void)didStartRecordingVoiceAction{

    NSDictionary * cbDic = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"status",@"0",@"voicePath", nil];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onVoiceAction!=null){uexChatKeyboard.onVoiceAction(\'%@\');}", [cbDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
    _v = [[ACPVoiceActionView alloc]initWithFrame:CGRectMake(0, 0, UEX_SCREENWIDTH, UEX_SCREENHEIGHT-_inputViewHeight)];
    _v.delegate = self;
    [EUtility brwView:self.uexObj.meBrwView addSubview:_v];
    
    
}

/**
 *  手指向上滑动取消录音
 */
- (void)didCancelRecordingVoiceAction{
    

    
    NSDictionary * cbDic = [NSDictionary dictionaryWithObjectsAndKeys:@"-1",@"status",@"-1",@"voicePath", nil];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onVoiceAction!=null){uexChatKeyboard.onVoiceAction(\'%@\');}", [cbDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
    [self removeViewAndSubviewsFromSuperview:_v];
    _v.delegate = nil;
}

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction{
    

    
    NSDictionary * cbDic = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"status",@"1",@"voicePath", nil];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onVoiceAction!=null){uexChatKeyboard.onVoiceAction(\'%@\');}", [cbDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    [self removeViewAndSubviewsFromSuperview:_v];
    _v.delegate = nil;
}





@end
