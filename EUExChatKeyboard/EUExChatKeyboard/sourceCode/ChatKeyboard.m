//
//  ChatKeyboard.m
//  EUExChatKeyboard
//
//  Created by xurigan on 14/12/12.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "ChatKeyboard.h"
#import "ChatKeyboardData.h"

// iOS系统版本
#define SYSTEM_VERSION    [[[UIDevice currentDevice] systemVersion] doubleValue]
// 标准系统状态栏高度
#define SYS_STATUSBAR_HEIGHT                        20
// 热点栏高度
#define HOTSPOT_STATUSBAR_HEIGHT            20
// 导航栏（UINavigationController.UINavigationBar）高度
#define NAVIGATIONBAR_HEIGHT                44
// 工具栏（UINavigationController.UIToolbar）高度
#define TOOLBAR_HEIGHT                              44
// 标签栏（UITabBarController.UITabBar）高度
#define TABBAR_HEIGHT                              44
// APP_STATUSBAR_HEIGHT=SYS_STATUSBAR_HEIGHT+[HOTSPOT_STATUSBAR_HEIGHT]
#define APP_STATUSBAR_HEIGHT                (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
// 根据APP_STATUSBAR_HEIGHT判断是否存在热点栏
#define IS_HOTSPOT_CONNECTED                (APP_STATUSBAR_HEIGHT==(SYS_STATUSBAR_HEIGHT+HOTSPOT_STATUSBAR_HEIGHT)?YES:NO)
// 无热点栏时，标准系统状态栏高度+导航栏高度
#define NORMAL_STATUS_AND_NAV_BAR_HEIGHT    (SYS_STATUSBAR_HEIGHT+NAVIGATIONBAR_HEIGHT)
// 实时系统状态栏高度+导航栏高度，如有热点栏，其高度包含在APP_STATUSBAR_HEIGHT中。
#define STATUS_AND_NAV_BAR_HEIGHT                    (APP_STATUSBAR_HEIGHT+NAVIGATIONBAR_HEIGHT)


#define UEX_SEND_FACE_NORMAL [UEX_PLUGIN_BUNDLE pathForResource:@"messageInputViewResource/EmotionsSendBtnGrey@2x" ofType:@"png"]
#define UEX_SEND_FACE_HL [UEX_PLUGIN_BUNDLE pathForResource:@"messageInputViewResource/EmotionsSendBtnBlueHL@2x" ofType:@"png"]

#define isSysVersionAbove7_0 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define UEX_SCREENWIDTH (isSysVersionAbove7_0?[UIScreen mainScreen].bounds.size.width:[UIScreen mainScreen].applicationFrame.size.width)
#define UEX_SCREENHEIGHT (isSysVersionAbove7_0?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].applicationFrame.size.height)


@implementation UIButton (FillColor)

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    [self setBackgroundImage:[UIButton imageWithColor:backgroundColor] forState:state];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

@implementation ChatKeyboard

-(instancetype)initWithUexobj:(EUExChatKeyboard *)uexObj{
    if (self = [super init]) {
        self.uexObj = uexObj;
        self.animationDuration = 0.25;
        self.isInit = YES;
        self.bottomOffset=0;
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
    
    [self.messageToolView.messageInputTextView resignFirstResponder];
    
    if (CGRectGetMaxY(self.messageToolView.frame) < UEX_SCREENHEIGHT) {
        
        [self messageViewAnimationWithMessageRect:CGRectZero
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
                                                name:UIKeyboardWillChangeFrameNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handleUIApplicationWillChangeStatusBarFrameNotification:)
                                                name:UIApplicationWillChangeStatusBarFrameNotification
                                              object:nil];

    
    if ([[[UIDevice currentDevice]systemVersion]floatValue]>=7) {
        _inputViewHeight = 45.0f;
    }
    else{
        _inputViewHeight = 40.0f;
    }
    
    
    CGFloat contentSatrtY = 0;
    
    if (IS_HOTSPOT_CONNECTED) { // iPhone4(s)-iOS6/iOS7屏幕坐标系下：hostView.frame={{0, 40}, {320, 440}}/{{0, 20}, {320, 460}}

        if (SYSTEM_VERSION >= 7.0) { // 如果设置了edgesForExtendedLayout=UIRectEdgeNone 
            contentSatrtY -= HOTSPOT_STATUSBAR_HEIGHT;// 64（有热点栏时，会自动下移20）
            
            self.messageToolView = [[ZBMessageInputView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT - _inputViewHeight-_bottomOffset - HOTSPOT_STATUSBAR_HEIGHT,UEX_SCREENWIDTH,_inputViewHeight)];
        }
    } else { // iPhone4(s)-iOS6/iOS7屏幕坐标系下：hostView.frame={{0, 20}, {320, 460}}/{{0, 0}, {320, 480}}
        contentSatrtY = NORMAL_STATUS_AND_NAV_BAR_HEIGHT; // 64
        
        self.messageToolView = [[ZBMessageInputView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT - _inputViewHeight-_bottomOffset,UEX_SCREENWIDTH,_inputViewHeight)];
    }
    
    //输入框的背景色
//    self.messageToolView.backgroundColor = [UIColor redColor];
//    self.messageToolView.image = nil;
    
    self.messageToolView.delegate = self;
    [EUtility brwView:self.uexObj.meBrwView addSubview:self.messageToolView];

//    CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
//    tempRect.size.height = CGRectGetMinY(self.messageToolView.frame);
//    self.uexObj.meBrwView.scrollView.frame = tempRect;
    
    
    [self shareFaceView];
    [self shareShareMeun];
}

//状态栏变化的通知(zt)
- (void)handleUIApplicationWillChangeStatusBarFrameNotification:(NSNotification*)notification
{
    CGRect newStatusBarFrame = [(NSValue*)[notification.userInfo objectForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    // 根据系统状态栏高判断热点栏的变动
    BOOL bPersonalHotspotConnected = (CGRectGetHeight(newStatusBarFrame)==(SYS_STATUSBAR_HEIGHT+HOTSPOT_STATUSBAR_HEIGHT)?YES:NO);
    
    CGPoint newCenter = CGPointZero;
    CGFloat OffsetY = bPersonalHotspotConnected?+HOTSPOT_STATUSBAR_HEIGHT:-HOTSPOT_STATUSBAR_HEIGHT;
    if (SYSTEM_VERSION >= 7.0) { // 即使设置了extendedLayoutIncludesOpaqueBars=NO/edgesForExtendedLayout=UIRectEdgeNone，对没有自动调整的部分View做必要的手动调整
        newCenter = self.messageToolView.center;
        newCenter.y -= OffsetY;
        self.messageToolView.center = newCenter;
        
        CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
        tempRect.size.height -= OffsetY;
        self.uexObj.meBrwView.scrollView.frame = tempRect;
        
    } else { // Custom Content对应的view整体调整
        
    }
    
}

- (void)shareFaceView{
    
    if (!self.faceView) {
        ChatKeyboardData *chatKeyboardData = [ChatKeyboardData sharedChatKeyboardData];
        self.faceView = [[ZBMessageManagerFaceView alloc]initWithFrame:CGRectMake(0.0f,UEX_SCREENHEIGHT, UEX_SCREENWIDTH, 196) andFacePath:self.facePath];
        self.faceView.delegate = self;
        [EUtility brwView:self.uexObj.meBrwView addSubview:self.faceView];
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.sendButton.frame = CGRectMake(UEX_SCREENWIDTH-70, CGRectGetMaxY(self.faceView.frame)+3, 70, 37);
        [self.sendButton setTitle:chatKeyboardData.sendBtnText forState:UIControlStateNormal];
        [self.sendButton setTitleColor:chatKeyboardData.sendBtnTextColor forState:UIControlStateNormal];
        [self.sendButton setBackgroundColor:chatKeyboardData.sendBtnbgColorUp];
        [self.sendButton setBackgroundColor:chatKeyboardData.sendBtnbgColorDown forState:UIControlStateHighlighted];
        self.sendButton.titleLabel.font = [UIFont systemFontOfSize:chatKeyboardData.sendBtnTextSize];
        self.sendButton.layer.borderWidth = 0.6;
        self.sendButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        [self.sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:UEX_SEND_FACE_NORMAL] forState:UIControlStateNormal];
//        [self.sendButton setBackgroundImage:[UIImage imageWithContentsOfFile:UEX_SEND_FACE_HL] forState:UIControlStateHighlighted];
        [EUtility brwView:self.uexObj.meBrwView addSubview:self.sendButton];
        [self.sendButton addTarget:self action:@selector(sendButtonDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)sendButtonDidClicked:(id)sender {
    [self didSendTextAction:self.messageToolView.messageInputTextView];
//    [self messageViewAnimationWithMessageRect:CGRectZero
//                     withMessageInputViewRect:self.messageToolView.frame
//                                  andDuration:0.25
//                                     andState:ZBMessageViewStateShowNone];
    
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
//        self.shareMenuView.backgroundColor = [UIColor redColor];
    }
}

- (void)changeWebView:(float)height {
    NSLog(@"changeWebView==>>进入changeWebView");
    float yy = self.uexObj.meBrwView.frame.origin.y;
    NSLog(@"changeWebView==>>meBrwView=%@;scrollView=%@",self.uexObj.meBrwView,self.uexObj.meBrwView.scrollView);
    [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, 0)];
    
    if (CGRectGetMinY(self.messageToolView.frame) < yy + height) {
        NSLog(@"changeWebView==>>有遮挡设偏移量====%lf",yy + height - CGRectGetMinY(self.messageToolView.frame));

        [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, yy + height - CGRectGetMinY(self.messageToolView.frame))];
        
    }

}

#pragma mark - messageView animation
- (void)messageViewAnimationWithMessageRect:(CGRect)rect withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state{

    [UIView animateWithDuration:duration animations:^{
        
        CGFloat offsetHeight=self.bottomOffset;
        if(CGRectGetHeight(rect)>offsetHeight){
            offsetHeight=CGRectGetHeight(rect);
        }
        
        CGFloat messageToolViewHeigh = UEX_SCREENHEIGHT - offsetHeight - CGRectGetHeight(inputViewRect);
        
        if (IS_HOTSPOT_CONNECTED){
            messageToolViewHeigh -= HOTSPOT_STATUSBAR_HEIGHT;
        }
        
        self.messageToolView.frame = CGRectMake(0.0f,messageToolViewHeigh,UEX_SCREENWIDTH,CGRectGetHeight(inputViewRect));
        
        CGRect tempRect = self.uexObj.meBrwView.scrollView.frame;
        tempRect.size.height = CGRectGetMinY(self.messageToolView.frame) + self.bottomOffset - self.uexObj.meBrwView.frame.origin.y;
        
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
        self.messageToolView.isKeyBoardShow=YES;
    } else {
        NSLog(@"messageViewAnimationWithMessageRect==>>键盘收回时scrollView=%@",self.uexObj.meBrwView.scrollView);
        if (self.uexObj.meBrwView.scrollView.frame.size.height >= self.uexObj.meBrwView.scrollView.contentOffset.y) {
            [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, 0)];
            
        } else {
            [self.uexObj.meBrwView.scrollView setContentOffset:CGPointMake(0, self.uexObj.meBrwView.scrollView.contentOffset.y)];
        }
        self.messageToolView.isKeyBoardShow = NO;
        //判断chatKeyboard是否收起
        if(!self.faceView.isHidden&&!self.shareMenuView.isHidden){
            self.messageToolView.faceSendButton.selected = NO;
        }
    }
    
    NSLog(@"messageViewAnimationWithMessageRect==>>messageInputTextView=%@;meBrwView=%@;scrollView=%@",self.messageToolView.messageInputTextView,self.uexObj.meBrwView,self.uexObj.meBrwView.scrollView);
    CGFloat inputTextViewY = CGRectGetMinY(self.messageToolView.frame);
    CGFloat inputTextViewHeight = self.messageToolView.frame.size.height;
    
//    NSDictionary * jsDic = [NSDictionary dictionaryWithObject:status forKey:@"status"];
    NSMutableDictionary *jsDic = [[NSMutableDictionary alloc] init];
    [jsDic setObject:status forKey:@"status"];
    [jsDic setObject:[NSString stringWithFormat:@"%f",inputTextViewY] forKey:@"inputTextViewY"];
    [jsDic setObject:[NSString stringWithFormat:@"%f",inputTextViewHeight] forKey:@"inputTextViewHeight"];
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onKeyBoardShow!=null){uexChatKeyboard.onKeyBoardShow(\'%@\');}",[jsDic JSONFragment]];
    

    [self performSelectorOnMainThread:@selector(onKeyboardShowCallback:) withObject:jsStr waitUntilDone:NO];
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
        self.faceView.hidden = NO;
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
    self.faceView.hidden = YES;
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
//    if (_isInit) {
//        self.previousTextViewContentHeight = messageInputTextView.contentSize.height;
//        _isInit = NO;
//    }
    if (!self.previousTextViewContentHeight)
    {
        self.previousTextViewContentHeight = messageInputTextView.contentSize.height;
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
    
    NSString * testContent = messageInputTextView.text;
    [messageInputTextView setText:nil];
    
    
    NSDictionary * jsDic = [NSDictionary dictionaryWithObject:testContent forKey:@"emojiconsText"];
    
    NSString *jsStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onCommit!=null){uexChatKeyboard.onCommit(\'%@\');}", [jsDic JSONFragment]];
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
    NSString *cbJsonStr = [NSString stringWithFormat:@"if(uexChatKeyboard.onCommitJson!=null){uexChatKeyboard.onCommitJson(%@);}", [jsDic JSONFragment]];
    
    NSDictionary * cbDic = [NSDictionary dictionaryWithObject:cbJsonStr forKey:@"cbKey"];
    
    NSString * cbjson = [cbDic objectForKey:@"cbKey"];
    
    
    [self.uexObj.meBrwView stringByEvaluatingJavaScriptFromString:cbjson];
    
    [self inputTextViewDidChange:messageInputTextView];
//    [messageInputTextView resignFirstResponder];
}




#pragma end
#pragma mark - ZBMessageFaceViewDelegate
- (void)SendTheFaceStr:(NSString *)faceStr isDelete:(BOOL)dele
{
    NSMutableString * oldMsg = [[NSMutableString alloc]initWithString:self.messageToolView.messageInputTextView.text];
    
    if (dele && [oldMsg length] > 0) {
        
        [self.messageToolView.messageInputTextView deleteBackward];
        
    } else if (!dele) {
        
        NSRange range = [self.messageToolView.messageInputTextView selectedRange];
        
        [oldMsg insertString:faceStr atIndex:range.location];
        
        range.location += [faceStr length];
        
        
        self.messageToolView.messageInputTextView.text = oldMsg;
        
        self.messageToolView.messageInputTextView.selectedRange = range;
        
    }
    
    [self inputTextViewDidChange:self.messageToolView.messageInputTextView];
    
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
    //UIImage * image = [UIImage imageNamed:@"uexChatKeyboard/voiceResource/touchDragOutside"];
    UIImage * image = [UIImage imageWithContentsOfFile:[UEX_PLUGIN_BUNDLE pathForResource:@"voiceResource/touchDragOutside@2x" ofType:@"png"]];
    if ([ChatKeyboardData sharedChatKeyboardData].dragOutsideImg) {
        UIImage * tempImg = [UIImage imageWithContentsOfFile:[ChatKeyboardData sharedChatKeyboardData].dragOutsideImg];
        if (tempImg) {
            image = tempImg;
        }
    }
    [_v changeImage:image andHiddenSecondLabel:YES];
}

-(void)stopCancelRecordingVoiceAction{
    //UIImage * image = [UIImage imageNamed:@"uexChatKeyboard/voiceResource/touchdown"];
    UIImage * image = [UIImage imageWithContentsOfFile:[UEX_PLUGIN_BUNDLE pathForResource:@"voiceResource/touchdown@2x" ofType:@"png"]];
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
