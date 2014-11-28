//
//  RemoteChanel.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "RemoteChanel.h"
#import "Util.h"
@interface RemoteChanel()
@property (strong, nonatomic) BonjourConnection *connection;
// Setup video
@property (strong, nonatomic) NSMutableArray    *frames;
@property (assign, nonatomic) NSNumber          *fps;
@property (assign, nonatomic) NSTimer           *playerClock;
@property (assign, nonatomic) NSInteger         numberOfFrameAtLastTick;
@property (assign, nonatomic) NSInteger         numberOfTicksWithFullBuffer;
@property (assign, nonatomic) BOOL              isPlaying;
@end

@implementation RemoteChanel
@synthesize connection;
@synthesize fps,frames,playerClock,numberOfFrameAtLastTick,numberOfTicksWithFullBuffer,isPlaying;
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
- (void)initialization
{
    frames = @[].mutableCopy;
    isPlaying = NO;
    numberOfTicksWithFullBuffer = 0;
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
    
    [self initialization];
    
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
- (void)broadcastChatMessage:(NSString *)message fromUser:(NSString *)name
{
    NSDictionary *packet = [NSDictionary dictionaryWithObjectsAndKeys:message,@"message",name,@"from", nil];
    NSLog(@"Remote:packet %@",packet);
    // send it out
    [connection sendNetworkPackage:packet];
}

- (void)broadcastData:(NSData *)data fromUser:(NSString *)name
{
    
}

- (void)broadcastDict:(NSDictionary *)dict fromUser:(NSString *)name
{
    //[self.delegate displayChatMessage:@"data sending" fromUser:name];
    //[self.delegate displayImageFromView:dict[@"image"] withFPS:dict[@"framesPerSecond"] fromUser:name];
    
    [connection sendNetworkPackage:dict];
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
    //[self.delegate displayChatMessage:[message objectForKey:@"message"] fromUser:[message objectForKey:@"from"]];
    [self.delegate displayImageFromView:message[@"image"] withFPS:message[@"framesPerSecond"] fromUser:[message objectForKey:@"from"]];
}

- (void)receivedNetworkDataPacket:(NSData *)data viaConnection:(BonjourConnection *)connection
{
    
}





@end
