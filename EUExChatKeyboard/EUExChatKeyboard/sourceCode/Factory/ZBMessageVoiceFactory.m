//
//  ZBMessageVoice.m
//  MessageDisplay
//
//  Created by zhoubin@moshi on 14-5-17.
//  Copyright (c) 2014年 Crius_ZB. All rights reserved.
//

#import "ZBMessageVoiceFactory.h"

@implementation ZBMessageVoiceFactory

+ (UIImageView *)messageVoiceAnimationImageViewWithBubbleMessageType:(ZBBubbleMessageType)type {
    UIImageView *messageVoiceAniamtionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    NSString *imageSepatorName;
    switch (type) {
        case ZBBubbleMessageTypeSending:
            imageSepatorName = @"Sender";
            break;
        case ZBBubbleMessageTypeReceiving:
            imageSepatorName = @"Receiver";
            break;
        default:
            break;
    }
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:4];
    for (NSInteger i = 0; i < 4; i ++) {
        NSString * imagePath = [NSString stringWithFormat:@"voiceResource/%@VoiceNodePlaying00%ld@2x",imageSepatorName,(long)i];
        UIImage *image = [UIImage imageWithContentsOfFile:[UEX_PLUGIN_BUNDLE pathForResource:imagePath ofType:@"png"]];
        if (image)
            [images addObject:image];
    }
    NSString * messageVoiceAniamtionImageViewPath = [NSString stringWithFormat:@"voiceResource/%@VoiceNodePlaying@2x",imageSepatorName];
    messageVoiceAniamtionImageView.image = [UIImage imageWithContentsOfFile:[UEX_PLUGIN_BUNDLE pathForResource:messageVoiceAniamtionImageViewPath ofType:@"png"]];
    messageVoiceAniamtionImageView.animationImages = images;
    messageVoiceAniamtionImageView.animationDuration = 1.0;
    [messageVoiceAniamtionImageView stopAnimating];
    
    return messageVoiceAniamtionImageView;
}

@end
