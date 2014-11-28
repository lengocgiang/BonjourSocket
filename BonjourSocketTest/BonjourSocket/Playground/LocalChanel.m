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


// Setup video
@property (strong, nonatomic) NSMutableArray    *frames;
@property (assign, nonatomic) NSNumber          *fps;
@property (assign, nonatomic) NSTimer           *playerClock;
@property (assign, nonatomic) NSInteger         numberOfFrameAtLastTick;
@property (assign, nonatomic) NSInteger         numberOfTicksWithFullBuffer;
@property (assign, nonatomic) BOOL              isPlaying;
@end

@implementation LocalChanel
@synthesize server,clients;
@synthesize fps,frames,playerClock,numberOfFrameAtLastTick,numberOfTicksWithFullBuffer,isPlaying;

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



- (void)broadcastChatMessage:(NSString *)message fromUser:(NSString *)name
{
    [self.delegate displayChatMessage:message fromUser:name];
    
    NSDictionary *packet = [NSDictionary dictionaryWithObjectsAndKeys:message,@"message",name,@"from" ,nil];
    
    // send it out
    [clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:packet];
}

- (void)broadcastDict:(NSDictionary *)dict fromUser:(NSString *)name
{
    //[self.delegate displayChatMessage:@"data sending" fromUser:name];
    //[self.delegate displayImageFromView:dict[@"image"] withFPS:dict[@"framesPerSecond"] fromUser:name];
    
    [clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:dict];
}

////////////////////////////////////////////////////////////////////////////////
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
// One of connected clients sent a chat message. Propagate it further.
- (void) receivedNetworkPacket:(NSDictionary*)message viaConnection:(BonjourConnection*)connection {
    // Display message locally
    //[self.delegate displayChatMessage:[packet objectForKey:@"message"] fromUser:[packet objectForKey:@"from"]];
    [self.delegate displayImageFromView:message[@"image"] withFPS:message[@"framesPerSecond"] fromUser:[message objectForKey:@"from"]];
    
    // Broadcast this message to all connected clients, including the one that sent it
    //[clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:message];
}

- (void)receivedNetworkDataPacket:(NSData *)data viaConnection:(BonjourConnection *)connection
{
    
}




@end
