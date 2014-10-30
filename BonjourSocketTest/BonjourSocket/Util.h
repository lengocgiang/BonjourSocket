//
//  Util.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+ (Util *)sharesInstance;
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix;


+ (void)postNotification:(NSString *)notification;

@end