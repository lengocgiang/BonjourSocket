//
//  GGAudioPlayer.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/3/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface GGAudioPlayer : NSObject<AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

+ (GGAudioPlayer *)sharedInstance;

- (void)initWithAudioFile:(NSString *)audioFile withFileExtension:(NSString *)fileExtension;
- (void)playAudio;
- (void)pauseAudio;
- (void)setCurrentAudioTime:(float)value;
- (float)getAudioDuration;
- (NSString *)timeFormat:(float)value;
- (NSTimeInterval)getCurrentAudioTime;

- (void)convertFloatDataFromAudioFileWithPath:(NSString *)filePath;


@end
