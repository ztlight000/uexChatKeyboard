//
//  ACPVoiceActionView.m
//  EUExChatKeyboard
//
//  Created by xurigan on 15/1/19.
//  Copyright (c) 2015年 com.zywx. All rights reserved.
//

#import "ACPVoiceActionView.h"
#import "ChatKeyboardData.h"
#import "EUtility.h"

@implementation ACPVoiceActionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self=[super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _maxRecordTimeInterval = 15;
        _second = 0;
        
        //UIImage * voiceImg = [UIImage imageNamed:@"uexChatKeyboard/voiceResource/touchdown"];
        UIImage * voiceImg = [UIImage imageWithContentsOfFile:[[EUtility bundleForPlugin:@"uexChatKeyboard"] pathForResource:@"voiceResource/touchdown@2x" ofType:@"png"]];
        if ([ChatKeyboardData sharedChatKeyboardData].touchDownImg) {
            UIImage * tempImg = [UIImage imageWithContentsOfFile:[ChatKeyboardData sharedChatKeyboardData].touchDownImg];
            if (tempImg) {
                voiceImg = tempImg;
            }
        }
        _voiceActionImgView = [[UIImageView alloc]initWithImage:voiceImg];
        _voiceActionImgView.center = self.center;
        [self addSubview:_voiceActionImgView];
        
        _secondLabel = [[UILabel alloc]initWithFrame:CGRectMake(_voiceActionImgView.frame.size.width/2, _voiceActionImgView.frame.size.height*2/5, _voiceActionImgView.frame.size.width/2, _voiceActionImgView.frame.size.height*2/5)];
        _secondLabel.text = [NSString stringWithFormat:@"%d’",_second];
        _secondLabel.textAlignment = NSTextAlignmentCenter;
        _secondLabel.textColor = [ChatKeyboardData sharedChatKeyboardData].textColor;
        float textSize = [ChatKeyboardData sharedChatKeyboardData].textSize;
        
        _secondLabel.font = [UIFont systemFontOfSize:textSize];
        _secondLabel.backgroundColor = [UIColor clearColor];
        [_voiceActionImgView addSubview:_secondLabel];
        
        _secondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSecondLabel) userInfo:nil repeats:YES];
        [_secondTimer fire];
        
        
    }
    return self;
}

-(void)timeOut{
    if ([self.delegate respondsToSelector:@selector(didTimeOut)]) {
        [self.delegate didTimeOut];
    }
}

-(void)updateSecondLabel{
    
    _second +=1;
    _secondLabel.text = [NSString stringWithFormat:@"%d’",_second];
    
    if (_second >= self.maxRecordTimeInterval) {
        [_secondTimer invalidate];
        [self timeOut];
    }
}

-(void)changeImage:(UIImage *)voiceImg andHiddenSecondLabel:(BOOL)hidden{
    
    _voiceActionImgView.image = voiceImg;
    _secondLabel.hidden = hidden;
}


-(void)recordStop{
    [_secondTimer invalidate];
}

-(void)recordCancel{
    [_secondTimer invalidate];
}


@end
