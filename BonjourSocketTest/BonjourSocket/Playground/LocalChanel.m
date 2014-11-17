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
////////////////////////////////////////////////////////////////////////////////
//                          TESTING                                           //
////////////////////////////////////////////////////////////////////////////////
- (void)broadcastData:(NSData *)data fromUser:(NSString *)name
{
    [self.delegate displayChatMessage:@"data sending" fromUser:name];
    
    [clients makeObjectsPerformSelector:@selector(sendNetworkData:)withObject:data];
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
- (void)receivedNetworkPacket:(NSDictionary *)message viaConnection:(BonjourConnection *)connection
{
    NSLog(@"message %@",[message objectForKey:@"message"]);
    // display message locally
    [self.delegate displayChatMessage:[message objectForKey:@"message"] fromUser:[message objectForKey:@"from"]];
    
    // broacast this message to all connected clients, include
    [clients makeObjectsPerformSelector:@selector(sendNetworkPackage:) withObject:message];
}
- (void)receivedNetworkDataPacket:(NSData *)data viaConnection:(BonjourConnection *)connection
{
    NSLog(@"server tu nhan cua minh ");
    if (data.length > 14)
    {
        @try {
            NSDictionary *dict = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            NSLog(@"frame %@",dict[@"framesPerSecond"]);
            if (dict[@"image"])
            {
                UIImage *img = [UIImage imageWithData:dict[@"image"] scale:[UIScreen mainScreen].scale];
                NSNumber *framesPerSecond = dict[@"framesPerSecond"];
                
                [self addImageFrame:img withFPS:framesPerSecond];
            }
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
    }
}

- (void)addImageFrame:(UIImage *)image withFPS:(NSNumber *)_fps
{
    if (!image) {
        return;
    }
    fps = _fps;
    
    if (!playerClock || (playerClock.timeInterval != (1.0/_fps.floatValue)))
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (playerClock) {
                [playerClock invalidate];
            }
            NSTimeInterval timeInterval = 1.0/[fps floatValue];
            playerClock = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                           target:self
                                                         selector:@selector(playerClockTick) userInfo:nil repeats:YES];
        });
    }
    [frames addObject:image];
    
}
- (void)playerClockTick
{
    if (isPlaying)
    {
        if (frames.count > 1)
        {
            if (self.delegate)
            {
                [self.delegate showImage:frames[0]];
            }
            [frames removeObjectAtIndex:0];
            
        }
        else {
            isPlaying = NO;
        }
    }
    else {
        if (frames.count >= 1)
        {
            isPlaying = YES;
        }
    }
    
}


@end
