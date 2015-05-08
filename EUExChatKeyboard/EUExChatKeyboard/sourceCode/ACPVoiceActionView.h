//
//  ACPVoiceActionView.h
//  EUExChatKeyboard
//
//  Created by xurigan on 15/1/19.
//  Copyright (c) 2015年 com.zywx. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ACPVoiceActionViewDelegate <NSObject>

@optional
-(void)didTimeOut;

@end

@interface ACPVoiceActionView : UIView
@property (nonatomic,weak) id<ACPVoiceActionViewDelegate> delegate;
@property(nonatomic,strong) UIImageView * voiceActionImgView;
@property(nonatomic,strong) UILabel * secondLabel;
@property(nonatomic,strong) NSTimer * secondTimer;
@property(nonatomic,assign) int second;

-(void)changeImage:(UIImage *)voiceImg andHiddenSecondLabel:(BOOL)hidden;
-(void)recordStop;
-(void)recordCancel;

@end
