//
//  Util.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "Util.h"

@implementation Util
- (id)init
{
    self.name = @"unknow";
    return self;
}
- (void)dealloc
{
    self.name = nil;
}
+ (Util *)sharedInstance
{
    static Util *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[Util alloc]init];
    });
    return _sharedInstance;
}

- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
{
    NSString *  result;
    CFUUIDRef   uuid;
    NSString *  uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease( CFUUIDCreateString(NULL, uuid) );
    
    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidStr]];
    assert(result != nil);
    
    CFRelease(uuid);
    
    return result;
}


+ (void)postNotification:(NSString *)notification
{
    // post notification to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:notification object:nil];
    });
}

@end
