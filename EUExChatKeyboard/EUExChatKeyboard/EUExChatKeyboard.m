//
//  EUExChatKeyboard.m
//  EUExChatKeyboard
//
//  Created by xurigan on 14/12/12.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "EUExChatKeyboard.h"
#import "ChatKeyboard.h"
#import "XMLReader.h"
#import "ChatKeyboardData.h"

@interface EUExChatKeyboard()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) ChatKeyboard * chatKeyboard;
@property (nonatomic, strong) NSString * delete;
@property (nonatomic, strong) NSString * pageNum;
@property (nonatomic, strong) UITapGestureRecognizer * tapGR;

@end

@implementation EUExChatKeyboard


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    if (self = [super initWithWebViewEngine:engine]) {
        
    }
    return self;
}



- (void)clean {
    
    if (_tapGR) {
        _tapGR.delegate = nil;
        _tapGR = nil;
    }
    
    
    if (_chatKeyboard) {
        [_chatKeyboard close];
        _chatKeyboard = nil;
    }

}

-(void)open:(NSMutableArray *)inArguments {

    ChatKeyboardData *chatKeyboardData = [ChatKeyboardData sharedChatKeyboardData];
    
    ACArgsUnpack(NSDictionary *xmlDic) = inArguments;
    
    
    NSString * xmlPath = [xmlDic objectForKey:@"emojicons"];
    xmlPath = [self absPath:xmlPath];
    
    NSString * sharePath = [xmlDic objectForKey:@"shares"];
    sharePath = [self absPath:sharePath];
    
    [self getFaceDicByFaceXMLPath:xmlPath];
    [self getShareDicFromSharePath:sharePath];
    
    NSArray * facePathArray = [xmlPath componentsSeparatedByString:@"/"];
    NSString * fileName = [facePathArray lastObject];
    NSRange range = [xmlPath rangeOfString:fileName];
    xmlPath = [xmlPath substringToIndex:range.location];
    chatKeyboardData.facePath = xmlPath;
    
    NSArray * sharePathArray = [sharePath componentsSeparatedByString:@"/"];
    NSString * shareFileName = [sharePathArray lastObject];
    NSRange range1 = [sharePath rangeOfString:shareFileName];
    sharePath = [sharePath substringToIndex:range1.location];
    chatKeyboardData.sharePath = sharePath;
    
    NSString * placeHold = @"";
    if ([xmlDic objectForKey:@"placeHold"]) {
        placeHold = [xmlDic objectForKey:@"placeHold"];
    }
    chatKeyboardData.placeHold = placeHold;
    
    NSString * touchDownImg = nil;
    if ([xmlDic objectForKey:@"touchDownImg"]) {
        touchDownImg = [self absPath:[xmlDic objectForKey:@"touchDownImg"]];
    }
    
    NSString * dragOutsideImg = nil;
    if ([xmlDic objectForKey:@"dragOutsideImg"]) {
        dragOutsideImg = [self absPath:[xmlDic objectForKey:@"dragOutsideImg"]];
    }
    
    UIColor * textColor = [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0];
    if ([xmlDic objectForKey:@"textColor"]) {
        NSString * textColorStr = [xmlDic objectForKey:@"textColor"];
        textColor = [UIColor ac_ColorWithHTMLColorString:textColorStr];
    }
    
    float textSize = 30.0;
    if ([xmlDic objectForKey:@"textSize"]) {
        textSize = [[xmlDic objectForKey:@"textSize"] floatValue];
    }
    BOOL isAudio=NO;
    if([xmlDic objectForKey:@"inputMode"]&&[[xmlDic objectForKey:@"inputMode"] integerValue]==1){
        isAudio=YES;
    }
    UIColor * sendBtnbgColorUp = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.5];
    if ([xmlDic objectForKey:@"sendBtnbgColorUp"]) {
        NSString * sendBtnbgColorUpStr = [xmlDic objectForKey:@"sendBtnbgColorUp"];
        sendBtnbgColorUp = [UIColor ac_ColorWithHTMLColorString:sendBtnbgColorUpStr];
    }
    UIColor * sendBtnbgColorDown = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    if ([xmlDic objectForKey:@"sendBtnbgColorDown"]) {
        NSString * sendBtnbgColorDownStr = [xmlDic objectForKey:@"sendBtnbgColorDown"];
        sendBtnbgColorDown = [UIColor ac_ColorWithHTMLColorString:sendBtnbgColorDownStr];
    }
    NSString * sendBtnText = @"发送";
    if ([xmlDic objectForKey:@"sendBtnText"]) {
        sendBtnText = [NSString stringWithFormat:@"%@",[xmlDic objectForKey:@"sendBtnText"]];
    }
    float sendBtnTextSize = 14.0;
    if ([xmlDic objectForKey:@"sendBtnTextSize"]) {
        sendBtnTextSize = [[xmlDic objectForKey:@"sendBtnTextSize"] floatValue];
    }
    UIColor * sendBtnTextColor = [UIColor colorWithRed:128.0/255.0 green:128.0/255.0 blue:128.0/255.0 alpha:1.0];
    if ([xmlDic objectForKey:@"sendBtnTextColor"]) {
        NSString * sendBtnTextColorStr = [xmlDic objectForKey:@"sendBtnTextColor"];
        sendBtnTextColor = [UIColor ac_ColorWithHTMLColorString:sendBtnTextColorStr];
    }
    
    chatKeyboardData.touchDownImg = touchDownImg;
    chatKeyboardData.dragOutsideImg = dragOutsideImg;
    chatKeyboardData.textColor = textColor;
    chatKeyboardData.textSize = textSize;
    chatKeyboardData.sendBtnbgColorUp = sendBtnbgColorUp;
    chatKeyboardData.sendBtnbgColorDown = sendBtnbgColorDown;
    chatKeyboardData.sendBtnText = sendBtnText;
    chatKeyboardData.sendBtnTextSize = sendBtnTextSize;
    chatKeyboardData.sendBtnTextColor = sendBtnTextColor;
    
    if (!_chatKeyboard) {
        
        _chatKeyboard = [[ChatKeyboard alloc]initWithUexobj:self];
        if([xmlDic objectForKey:@"bottom"]){
            _chatKeyboard.bottomOffset=[[xmlDic objectForKey:@"bottom"] floatValue];
        }
        
        
        [_chatKeyboard open];
        
        _tapGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard:)];
        [[self.webViewEngine webView]addGestureRecognizer:_tapGR];

        
        _tapGR.delegate = self;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [_chatKeyboard.messageToolView uex_change:isAudio];

        });
        
    }
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)hideKeyboard:(NSMutableArray*)inArguments {
    
    if (_chatKeyboard) {
 
        [_chatKeyboard hideKeyboard];
        
    }

}

//7-24 by lkl

- (NSNumber *)getInputBarHeight:(NSMutableArray*)inArguments{
    CGFloat height;
    if (ACSystemVersion() >= 7) {
        height = 45.0f;
    }
    else{
        height = 40.0f;
    }
    
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexChatKeyboard.cbGetInputBarHeight" arguments:ACArgsPack(@{@"height":@(height)}.ac_JSONFragment)];
    return @(height);

    
}



-(void)getShareDicFromSharePath:(NSString *)sharePath
{
    NSData * xmlData = [NSData dataWithContentsOfFile:sharePath];
    NSError * error;
    NSDictionary * xmlDic = [XMLReader dictionaryForXMLData:xmlData error: &error];
    NSDictionary * tempDic = [xmlDic objectForKey:@"shares"];
    [ChatKeyboardData sharedChatKeyboardData].shareArray = [tempDic objectForKey:@"key"];
    [ChatKeyboardData sharedChatKeyboardData].shareImgArray = [tempDic objectForKey:@"string"];
    [ChatKeyboardData sharedChatKeyboardData].pageNum = [tempDic objectForKey:@"prePageNum"];
    
}

-(NSMutableDictionary *)getDicByKeyArray:(NSArray *)keyArray andStringArray:(NSArray *)stringArray
{
    NSMutableDictionary * reDic = [NSMutableDictionary dictionary];
    for (int i = 0; i < [keyArray count]; i++)
    {
        NSString * key = [[keyArray objectAtIndex:i] objectForKey:@"text"];
        NSString * string = [[stringArray objectAtIndex:i] objectForKey:@"text"];
        [reDic setObject:string forKey:key];
    }
    return reDic;
}

-(void)getFaceDicByFaceXMLPath:(NSString *)xmlPath {
    NSData * xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSError * error;
    NSDictionary * xmlDic = [XMLReader dictionaryForXMLData:xmlData error: &error];
    NSDictionary * emojiconsDic = [xmlDic objectForKey:@"emojicons"];
    [ChatKeyboardData sharedChatKeyboardData].faceArray = [emojiconsDic objectForKey:@"key"];
    [ChatKeyboardData sharedChatKeyboardData].faceImgArray = [emojiconsDic objectForKey:@"string"];
    [ChatKeyboardData sharedChatKeyboardData].deleteImg = [emojiconsDic objectForKey:@"delete"];
}

- (void)changeWebViewFrame:(NSMutableArray *)inArguments {
    float h = [inArguments.firstObject floatValue];
    if (_chatKeyboard) {
        [_chatKeyboard changeWebView:h];
    }
    
}

-(void)close:(NSMutableArray *)inArguments {
    
    [self clean];
}

@end
