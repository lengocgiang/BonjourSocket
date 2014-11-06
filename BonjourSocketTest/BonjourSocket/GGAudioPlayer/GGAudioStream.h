//
//  GGAudioStream.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/3/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GGAudioStreamEvent) {
    GGAudioStreamEventHasData,                      // input
    GGAudioStreamEventWasData,                      // output
    GGAudioStreamEventEnd,
    GGAudioStreamEventError
};
@class GGAudioStream;

@protocol GGAudioStreamDelegate  <NSObject>

@required
- (void)audioStream:(GGAudioStream *)audioStreams didRaiseEvent:(GGAudioStreamEvent)event;
@end

@interface GGAudioStream : NSObject
@property (assign, nonatomic) id<GGAudioStreamDelegate> delegate;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream;
- (instancetype)initWithOutputStream:(NSOutputStream *)outputStream;

- (void)open;
- (void)close;
- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength;
- (UInt32)writeData:(uint8_t *)data maxLength:(UInt32)maxLength;
@end
