//
//  EchoConnection.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BonjourConnection : NSObject

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
- (BOOL)openStreams;
- (void)closeStreams;

extern NSString * EchoConnectionDidCloseNotification;
extern NSString * EchoConnectionDidRequestedNotification;
// this notification is posted when the connection closes, either because
// called -closeStream or because of on-the-wire- events(the clients closing
// the connection, a network error, and so on)
@end
