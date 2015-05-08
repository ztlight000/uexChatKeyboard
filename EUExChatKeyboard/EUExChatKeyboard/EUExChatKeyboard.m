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

@interface EUExChatKeyboard()

@property (nonatomic, strong) ChatKeyboard * chatKeyboard;
@property (nonatomic, strong) NSString * delete;
@property (nonatomic, strong) NSString * pageNum;

@end

@implementation EUExChatKeyboard

-(id)initWithBrwView:(EBrowserView *)eInBrwView {
    if (self = [super initWithBrwView:eInBrwView]) {
        //
    }
    return self;
}

-(void)clean {
    if (_chatKeyboard) {
        [_chatKeyboard close];
        _chatKeyboard = nil;
    }
}

-(void)open:(NSMutableArray *)array {
    if ([array count] < 1) {
        return;
    }
    
    NSDictionary * xmlDic = [[array objectAtIndex:0] JSONValue];
    
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
    [ChatKeyboardData sharedChatKeyboardData].facePath = xmlPath;
    
    NSArray * sharePathArray = [sharePath componentsSeparatedByString:@"/"];
    NSString * shareFileName = [sharePathArray lastObject];
    NSRange range1 = [sharePath rangeOfString:shareFileName];
    sharePath = [sharePath substringToIndex:range1.location];
    [ChatKeyboardData sharedChatKeyboardData].sharePath = sharePath;
    
    NSString * placeHold = @"";
    if ([xmlDic objectForKey:@"placeHold"]) {
        placeHold = [xmlDic objectForKey:@"placeHold"];
    }
    [ChatKeyboardData sharedChatKeyboardData].placeHold = placeHold;
    
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
        textColor = [EUtility ColorFromString:textColorStr];
    }
    
    float textSize = 30.0;
    if ([xmlDic objectForKey:@"textSize"]) {
        textSize = [[xmlDic objectForKey:@"textSize"] floatValue];
    }
    
    [ChatKeyboardData sharedChatKeyboardData].touchDownImg = touchDownImg;
    [ChatKeyboardData sharedChatKeyboardData].dragOutsideImg = dragOutsideImg;
    [ChatKeyboardData sharedChatKeyboardData].textColor = textColor;
    [ChatKeyboardData sharedChatKeyboardData].textSize = textSize;
    
    
    if (!_chatKeyboard) {
        _chatKeyboard = [[ChatKeyboard alloc]initWithUexobj:self];
        [_chatKeyboard open];
    }
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

-(void)getFaceDicByFaceXMLPath:(NSString *)xmlPath
{
    NSData * xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSError * error;
    NSDictionary * xmlDic = [XMLReader dictionaryForXMLData:xmlData error: &error];
    NSDictionary * emojiconsDic = [xmlDic objectForKey:@"emojicons"];
    [ChatKeyboardData sharedChatKeyboardData].faceArray = [emojiconsDic objectForKey:@"key"];
    [ChatKeyboardData sharedChatKeyboardData].faceImgArray = [emojiconsDic objectForKey:@"string"];
    [ChatKeyboardData sharedChatKeyboardData].deleteImg = [emojiconsDic objectForKey:@"delete"];
}

-(void)close:(NSMutableArray *)array {
    if (_chatKeyboard) {
        [_chatKeyboard close];
        _chatKeyboard = nil;
    }
}

@end