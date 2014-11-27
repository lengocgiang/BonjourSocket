//
//  EchoServer.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourServer.h"
#import "BonjourConnection.h"
#import "Util.h"
#import "BonjourConfig.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>


@interface BonjourServer()
<
    NSNetServiceDelegate
>
@property (assign, nonatomic) uint16_t          port;
@property (strong, nonatomic) NSNetService      *netService;
@property (assign, nonatomic) CFSocketRef       listeningSocket;

// methods
- (BOOL)createServer;
- (void)terminateServer;

- (BOOL)publishService;
- (void)unpublishService;

@end

@implementation BonjourServer
@synthesize port;
@synthesize netService;
@synthesize listeningSocket;
@synthesize delegate;
// Clean up
- (void)dealloc
{
    self.netService = nil;
    self.delegate = nil;
}
#pragma mark - Public methods
// Create server and anounce it

- (BOOL)startServer
{
    // Start the socket server
    if (![self createServer])
    {
        return NO;
    }
    // Announce the server via Bonjour
    if (![self publishService])
    {
        [self terminateServer];
        return NO;
    }
    //NSLog(@"SERVER: Start done");
    
    return YES;
}
- (void)stopServer
{
    [self terminateServer];
    [self unpublishService];
}


#pragma mark- Callbacks
// Handle new connection
- (void)handleNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle
{
    BonjourConnection *connection = [[BonjourConnection alloc]initWithNativeSocketHandle:nativeSocketHandle];

    // In case of errors, close native socket handle
    if (connection == nil)
    {
        close(nativeSocketHandle);
        return;
    }
    // finish connecting
    if ( ! [connection connect] ) {
        [connection close];
        return;
    }
    
    // Pass this on to our delegate
    [self.delegate handleNewConnection:connection];
    
}

// This function will be used as a callback while creating our listening socket via 'CFSocketCreate'
static void serverAcceptCallback(CFSocketRef socket,CFSocketCallBackType type,CFDataRef address,const void *data,void *info)
{
    BonjourServer *server = (__bridge BonjourServer *)info;
    
    // We can only process 'connection accepted' calls here
    if (type != kCFSocketAcceptCallBack) {
        return;
    }
    // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;
    
    [server handleNewNativeSocket:nativeSocketHandle];
    
}

#pragma mark Sockets and stream
- (BOOL)createServer
{
    // Step 1: Create a socket that can accept connection
    /**
     Socket Context
       struct CFSocketContext{
        CFIndex version;
        void *info;
        CFAllocatorRetainCallBack retain;
        CFAllocatorReleaseCallBack release;
        CFAllocatorCopyDescriptionCallBack copyDescription;
     };
     */
    CFSocketContext socketCtx = {0,(__bridge void *)(self),NULL,NULL,NULL};
    
    listeningSocket = CFSocketCreate(kCFAllocatorDefault,
                                     PF_INET,                                   // The protocol family for the socket
                                     SOCK_STREAM,                               // The socket type to create
                                     IPPROTO_TCP,                               // THe protocol for the socket, TCP
                                     kCFSocketAcceptCallBack,                   // New connection will be automatically accepted and the callback is called with the data argument being a pointer to a CFSocketNativeHandle of the child socket
                                     (CFSocketCallBack)&serverAcceptCallback,
                                     &socketCtx);
    // Previos call might have failed
    if (listeningSocket == nil)
    {
        return NO;
    }
    
    // getsockopt will return existing socket option value via this variable
    int existingValue = 1;

    // Make sure that same listening socket address gets reused after every connection
    setsockopt(CFSocketGetNative(listeningSocket),
               SOL_SOCKET, SO_REUSEADDR,
               (void *)&existingValue,
               sizeof(existingValue));
    
    // Step 2: Bind our socket to an endpoint
    // We'll be listening on all available interface/addresses.
    // Port will be assigned automatically by kernel
    struct sockaddr_in socketAddress;
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sin_len       = sizeof(socketAddress);
    socketAddress.sin_family    = AF_INET;                                      // Address family (IPv4/ IPv6)
    socketAddress.sin_port      = 0;                                            // Actual port will get assigned automatically by kernel
    socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);                          // We must use "network by order" format (big-endian) for the value here
    
    // Convert the endpoint data structure into something that CFSocket can use
    NSData *socketAddressData = [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
    
    // Bind our socket to the endpoint. Check if successful
    if (CFSocketSetAddress(listeningSocket, (CFDataRef)socketAddressData) != kCFSocketSuccess)
    {
        // clean up
        if (listeningSocket != nil)
        {
            CFRelease(listeningSocket);
            listeningSocket = nil;
        }
        return NO;
    }
    // Step 3: Find out what port kernel assigned to our socket
    // We need it to advertise our service via Bonjour
    NSData *socketAddressActualData = (NSData *)CFBridgingRelease(CFSocketCopyAddress(listeningSocket));
    
    // Convert socket data into a usable structure
    struct sockaddr_in socketAddressActual;
    memcpy(&socketAddressActual, [socketAddressActualData bytes], [socketAddressActualData length]);
    self.port = ntohs(socketAddressActual.sin_port);
    
    
    // Step 4: Hook up our socket to the current run loop
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, listeningSocket, 0);
    CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
    
    return YES;
}
- (void)terminateServer
{
    if (listeningSocket != nil)
    {
        CFSocketInvalidate(listeningSocket);
        CFRelease(listeningSocket);
        listeningSocket = nil;
    }
}
#pragma mark - Bonjour
- (BOOL)publishService
{
    // come up with a name for our channel :D very fun \:m/
    NSString *channelName = [NSString stringWithFormat:@"%@'sChannel",[[Util sharedInstance]name]];
    
    // create new instance of netService
    self.netService = [[NSNetService alloc]initWithDomain:@""
                                                     type:@"_gBonjourSocket._tcp."
                                                     name:channelName port:self.port];
    if (self.netService == nil) return NO;

    // Add service to current run loop
    [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    // NetService will let us know about what's happening via delegate methods
    [self.netService setDelegate:self];
    
    // Publish the service
    [self.netService publish];
    
    return YES;
}
- (void)unpublishService
{
    if (self.netService)
    {
        [self.netService stop];
        [self.netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        self.netService = nil;
    }
}
#pragma mark - 
#pragma mark NSNetServiceDelegate method 
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    if (sender != self.netService)
    {
        return;
    }
    
    // Stop socket server;
    [self terminateServer];
    
    // Stop bonjour
    [self unpublishService];
    
    // Let delegate know about failure
    [delegate serverFailed:self reason:@"Failed to publish service via Bonjour(duplicate server name?)"];
}

@end