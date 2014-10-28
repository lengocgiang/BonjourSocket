//
//  Util.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "Util.h"

@implementation Util
+ (void)postNotification:(NSString *)notification
{
    // post notification to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:notification object:nil];
    });
}
@end
