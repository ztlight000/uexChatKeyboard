//
//  ChatKeyboardData.h
//  EUExChatKeyboard
//
//  Created by xurigan on 15/3/9.
//  Copyright (c) 2015年 com.zywx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatKeyboardData : NSObject

@property (nonatomic,strong) NSArray * faceImgArray;
@property (nonatomic,strong) NSArray * shareImgArray;
@property (nonatomic,strong) NSArray * faceArray;
@property (nonatomic,strong) NSArray * shareArray;
@property (nonatomic,strong) NSString * sharePath;
@property (nonatomic,strong) NSString * facePath;
@property (nonatomic,strong) NSString * deleteImg;
@property (nonatomic,strong) NSString * pageNum;
@property (nonatomic,strong) NSString * placeHold;

@property (nonatomic,strong) NSString * touchDownImg;
@property (nonatomic,strong) NSString * dragOutsideImg;
@property (nonatomic,strong) UIColor * textColor;
@property (nonatomic,assign) float textSize;

+(ChatKeyboardData *)sharedChatKeyboardData;

@end
