//
//  ChatKeyboardUtility.m
//  EUExChatKeyboard
//
//  Created by xurigan on 15/1/12.
//  Copyright (c) 2015年 com.zywx. All rights reserved.
//

#import "ChatKeyboardUtility.h"

@implementation ChatKeyboardUtility

+ (int)getRand {
    srand((unsigned)time(NULL));
    return rand();
}

+ (NSString *)getFilePathInChatKeyboardCache:(NSString*)fileName {
    return [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/chatKeyboardCache/%@",fileName]];
}

@end
