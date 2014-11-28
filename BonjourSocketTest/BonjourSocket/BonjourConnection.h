//
//  EchoConnection.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BonjourConnection;

@protocol BonjourConnectionDelegate <NSObject>
- (void)connectionAttemptFailed:(BonjourConnection *)connection;
- (void)connectionTerminated:(BonjourConnection *)connection;
- (void)receivedNetworkPacket:(NSDictionary *)message viaConnection:(BonjourConnection *)connection;

// add new method
//- (void)receivedNetworkDataPacket:(NSData *)data viaConnection:(BonjourConnection *)connection;
@end

@interface BonjourConnection : NSObject
{
    // Connection info: host address and port
    NSString *host;
    int port;
    
    // Connection info: native socket handle
    CFSocketNativeHandle connectedSocketHandle;
    
    // Connection info: NSNetService
    NSNetService *netService;
    
    // Read stream
    CFReadStreamRef readStream;
    BOOL readStreamOpen;
    NSMutableData* incomingDataBuffer;
    int packetBodySize;
    
    // Write stream
    CFWriteStreamRef writeStream;
    BOOL writeStreamOpen;
    NSMutableData *outgoingDataBuffer;
}

@property (assign, nonatomic) id<BonjourConnectionDelegate>delegate;

// Initialize are store connection information util 'connect' is called
- (id)initWithHostAddress:(NSString *)host andPort:(int)port;

// Initialize using a native socket handle, assuming connection is open
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;

// Initialize using an instance of NSNetService
- (id)initWithNetService:(NSNetService *)netService;

// Connect using whatever connection info that was passed during initialization
- (BOOL)connect;

// Close connection
- (void)close;

// Send network message
- (void)sendNetworkPackage:(NSDictionary *)packet;

@end
