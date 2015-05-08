//
//  ChatKeyboardData.m
//  EUExChatKeyboard
//
//  Created by xurigan on 15/3/9.
//  Copyright (c) 2015年 com.zywx. All rights reserved.
//

#import "ChatKeyboardData.h"

@implementation ChatKeyboardData

static ChatKeyboardData *_sharedChatKeyboardData = nil;

+ (ChatKeyboardData *)sharedChatKeyboardData
{
    if (!_sharedChatKeyboardData) {
        _sharedChatKeyboardData = [[self alloc] init];
    }
    
    return _sharedChatKeyboardData;
}

-(instancetype)init
{
    if (self = [super init]) {
        self.faceArray = [NSArray array];
        self.faceImgArray = [NSArray array];
        self.shareArray = [NSArray array];
        self.shareImgArray = [NSArray array];
    }
    return self;
}

@end
