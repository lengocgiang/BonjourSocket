//
//  RemoteChanel.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "RemoteChanel.h"

@interface RemoteChanel()
@property (strong, nonatomic) BonjourConnection *connection;
@end

@implementation RemoteChanel
@synthesize connection;

// Setup connection but don't connect yet
- (id)initWithHost:(NSString *)host andPort:(int)port
{
    connection = [[BonjourConnection alloc]initWithHostAddress:host andPort:port];
    return self;
}

// Initialize and connection to a net service
- (id)initWithNetService:(NSNetService *)netService
{
    connection = [[BonjourConnection alloc]initWithNetService:netService];
    return self;
}

- (void)dealloc
{
    self.connection = nil;
}
- (BOOL)start
{
    if (connection == nil) {
        return NO;
    }
    connection.delegate = self;
    
    return [connection connect];
}

- (void)stop
{
    if (connection == nil) {
        return;
    }
    [connection close];
    self.connection = nil;
}

// Send chat message to the server
- (void)boardcastChatMessage:(NSString *)message fromUser:(NSString *)name
{
    NSDictionary *packet = [NSDictionary dictionaryWithObjectsAndKeys:message,@"message",name,@"from", nil];
    
    // send it out
    [connection sendNetworkPackage:packet];
}
#pragma mark
#pragma mark ConnectionDelegate
- (void)connectionAttemptFailed:(BonjourConnection *)connection
{
    [self.delegate chanelTerminated:self reason:@"Wasn't able to connect to server"];
}
- (void)connectionTerminated:(BonjourConnection *)connection
{
    [self.delegate chanelTerminated:self reason:@"Connection to server closed"];
}
- (void)receivedNetworkPacket:(NSDictionary *)message viaConnection:(BonjourConnection *)connection
{
    [self.delegate displayChatMessage:[message objectForKey:@"message"] fromUser:[message objectForKey:@"from"]];
}

@end
