//
//  GGAudioOutputStreamer.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/3/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface GGAudioOutputStreamer : NSObject

- (instancetype)initWithOutputStream:(NSOutputStream *)stream;

- (void)streamAudioFromURL:(NSURL *)url;
- (void)start;
- (void)stop;


@end
