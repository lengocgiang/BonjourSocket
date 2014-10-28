//
//  EchoServer.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kEchoServerAddConnectionNotification @"EchoServerAddConnectionNotification"

@interface BonjourServer : NSObject

@property (nonatomic, assign, readonly) NSUInteger port;
+ (BonjourServer *)sharedPublisher;

- (BOOL)startServer;
- (void)stopServer;

@end
