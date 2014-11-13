//
//  LocalChanel.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "LocalChanel.h"
#import "BonjourConnection.h"

@interface LocalChanel()
@property(nonatomic, strong,readwrite) BonjourServer      *server;
@property(nonatomic, strong,readwrite) NSMutableSet       *clients;
@end

@implementation LocalChanel
@synthesize server,clients;


- (id)init
{
    clients = [NSMutableSet set];
    return self;
}

// cleanup
- (void)dealloc
{
    self.clients    = nil;
    self.server     = nil;
}

// Start the server and announce self
- (BOOL)start
{
    server = [[BonjourServer alloc]init];
    server.delegate = self;
    if (![server startServer]) {
        self.server =nil;
        return NO;
    }
    return YES;
}
- (void)stop
{
    [server stopServer];
    self.server = nil;
    
    [clients makeObjectsPerformSelector:@selector(close)];
}


- (void)boardcastChatMessage:(NSString *)message fromUser:(NSString *)name
{
    [self.delegate displayChatMessage:message fromUser:name];
    
    NSDictionary *packet = [NSDictionary dictionaryWithObjectsAndKeys:message,@"message",name,@"from" ,nil];
    
    // send it out
    [clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:packet];
}
#pragma mark -
#pragma mark ServerDelegate methods 
// Server has failed ,stop the world
- (void)serverFailed:(BonjourServer *)server reason:(NSString *)reason
{
    [self stop];
    [self.delegate chanelTerminated:self reason:reason];
}

// new client connected to our server, add it =))
- (void)handleNewConnection:(BonjourConnection *)connection
{
    NSLog(@"Server:Add new connection!");
    connection.delegate = self;
    [clients addObject:connection];

}
- (void)connectionAttemptFailed:(BonjourConnection *)connection
{
    
}
- (void)connectionTerminated:(BonjourConnection *)connection
{
    [clients removeObject:connection];
}
- (void)receivedNetworkPacket:(NSDictionary *)message viaConnection:(BonjourConnection *)connection
{
    NSLog(@"message %@",[message objectForKey:@"message"]);
    // display message locally
    [self.delegate displayChatMessage:[message objectForKey:@"message"] fromUser:[message objectForKey:@"from"]];
    
    // broacast this message to all connected clients, include
    [clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:message];
}

@end
