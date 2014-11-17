//
//  Chanel.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ChanelDelegate <NSObject>
- (void)displayChatMessage:(NSString *)message fromUser:(NSString *)userName;
- (void)chanelTerminated:(id)chanel reason:(NSString *)string;
- (void)displayImageFromView:(NSData *)imageData withFPS:(NSNumber *)framePerSecond fromUser:(NSString *)userName;

@end

@interface Chanel : NSObject
{
    //id<ChanelDelegate>delegate;
}
@property (assign, nonatomic)id<ChanelDelegate>delegate;

- (BOOL) start;
- (void) stop;
- (void) broadcastChatMessage:(NSString *)message fromUser:(NSString *)name;
- (void) broadcastData:(NSData *)data fromUser:(NSString *)name;
- (void) broadcastDict:(NSDictionary *)dict fromUser:(NSString *)name;

@end
