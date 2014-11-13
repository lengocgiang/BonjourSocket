//
//  EchoServer.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BonjourServer;
@class BonjourConnection;

@protocol BonjourServerDelegate <NSObject>
// Server has been terminated because of an error
- (void)serverFailed:(BonjourServer *)server reason:(NSString *)reason;
// Server has accepted a new connection and it needs to be processed
- (void)handleNewConnection:(BonjourConnection *)connection;
@end

@interface BonjourServer : NSObject
@property (assign, nonatomic) id<BonjourServerDelegate>delegate;
// Initialize and start listening for connections
- (BOOL)startServer;
- (void)stopServer;


@end
