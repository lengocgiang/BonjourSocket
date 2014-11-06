//
//  GGAudioStream.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/3/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "GGAudioStream.h"

@interface GGAudioStream()
<
    NSStreamDelegate
>

@property (strong, nonatomic) NSStream *stream;

@end

@implementation GGAudioStream

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (self)
    {
        self.stream = inputStream;
    }
    return self;
}
- (instancetype)initWithOutputStream:(NSOutputStream *)outputStream
{
    self = [super init];
    if (self)
    {
        self.stream = outputStream;
    }
    return self;
}





@end
