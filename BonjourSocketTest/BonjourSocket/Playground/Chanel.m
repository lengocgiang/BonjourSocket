//
//  Chanel.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "Chanel.h"


@implementation Chanel
@synthesize delegate;

// cleanup
- (void)dealloc
{
    self.delegate = nil;
}

// "Abstract" methods
- (BOOL)start
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}
- (void)stop
{
    [self doesNotRecognizeSelector:_cmd];
}
- (void)broadcastChatMessage:(NSString *)message fromUser:(NSString *)name
{
    [self doesNotRecognizeSelector:_cmd];
}
- (void)broadcastData:(NSData *)data fromUser:(NSString *)name
{
    [self doesNotRecognizeSelector:_cmd];
}
- (void)broadcastDict:(NSDictionary *)dict fromUser:(NSString *)name
{
    [self doesNotRecognizeSelector:_cmd];
}

@end
