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

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface BonjourServer()
<
    NSNetServiceDelegate,
    NSStreamDelegate
>
@property (nonatomic, assign, readwrite) NSUInteger         port;

// private properties
@property (nonatomic, strong, readwrite) NSNetService       *netService;
@property (nonatomic, strong, readonly) NSMutableSet        *connections;       // of EchoConnection

@end

@implementation BonjourServer
{
    CFSocketRef         _ipv4socket;
    CFSocketRef         _ipv6socket;
    
}
@synthesize port        = _port;

@synthesize netService  =_netService;
@synthesize connections = _connections;

+ (BonjourServer *)sharedPublisher
{
    static BonjourServer *_sharedPublisher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPublisher = [[BonjourServer alloc]init];
    });
    return _sharedPublisher;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _connections = [[NSMutableSet alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self stopServer];
}

// This function is called by CFSocket when a new connection comes in
// We gather the data we need, and then convert the function call to a method
// invocation on EchoServer
static void BonjourServerAcceptCallback(CFSocketRef socket,CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    assert(type == kCFSocketAcceptCallBack);
    
    
    BonjourServer *server = (__bridge BonjourServer *)info;
    assert(socket == server->_ipv4socket || socket == server->_ipv6socket);
    #pragma unused(socket)
    
    // For an accept callback, the data parameter is a pointer to a CFSocketNativeHanle
    [server acceptConnection:*(CFSocketNativeHandle*)data];
}


#pragma mark - Public methods
- (BOOL)startServer
{
    if (![self setUpListeningSocket])
    {
        return NO;
    }
    
    assert(self.port > 0 && self.port < 65536);
    self.netService = [[NSNetService alloc]initWithDomain:@"local"
                                                     type:@"_gcocoaecho._tcp"
                                                     name:@"" port:(int)self.port];
    [self.netService setIncludesPeerToPeer:YES];
    [self.netService publish];
    [self.netService setDelegate:self];
    
    
    return YES;
    
}

- (void)stopServer
{
    [self.netService stop];
    self.netService = nil;
    
    // Closes all the open connections. The EchoConnectionDidCloseNotification
    // notification will ensure that the connection gets removed from the
    // self.connections set. To avoid mututation under interaction
    // problems, we make a copy of that set and interate over the copy
    for (BonjourConnection *connection in [self.connections copy])
    {
        [connection closeStreams];
    }
    if (_ipv4socket != NULL)
    {
        CFSocketInvalidate(_ipv4socket);
        CFRelease(_ipv4socket);
        _ipv4socket = NULL;
    }
    if (_ipv6socket != NULL)
    {
        CFSocketInvalidate(_ipv6socket);
        CFRelease(_ipv6socket);
        _ipv6socket = NULL;
    }
}

#pragma mark - NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender
    // An NSNetService delegate callback that's called when the service is successfully
    // registered on the network.  We set our service name to the name of the service
    // because the service might be been automatically renamed by Bonjour to avoid
    // conflicts
{
    
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"BonjourServer error: Failed to registered service.");
    [self stopServer];
}
- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog(@"BonjourServer stop: Network service stopped");
}


#pragma mark - Privates methods
- (BOOL)setUpListeningSocket
{
    assert(_ipv4socket == NULL && _ipv6socket == NULL);                           // don't call start twice!!!
    
    CFSocketContext socketContext = {0,(__bridge void*)self,NULL,NULL,NULL};
    
    _ipv4socket = CFSocketCreate(kCFAllocatorDefault,
                                 AF_INET,
                                 SOCK_STREAM,
                                 0,
                                 kCFSocketAcceptCallBack,
                                 &BonjourServerAcceptCallback,
                                 &socketContext);
    
    _ipv6socket = CFSocketCreate(kCFAllocatorDefault,
                                 AF_INET6,
                                 SOCK_STREAM,
                                 0,
                                 kCFSocketAcceptCallBack,
                                 &BonjourServerAcceptCallback,
                                 &socketContext);
    
    if (NULL == _ipv4socket || NULL == _ipv6socket)
    {
        [self stopServer];
        return NO;
    }
    static const int yes = 1;
    (void) setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (const void *)&yes, sizeof(yes));
    (void) setsockopt(CFSocketGetNative(_ipv6socket), SOL_SOCKET, SO_REUSEADDR, (const void *)&yes, sizeof(yes));
    
    // Set up the IPv4 listening socket, port is 0 which will cause the kernel to choose a port for us
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(0);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (__bridge CFDataRef)[NSData dataWithBytes:&addr4 length:sizeof(addr4)]))
    {
        [self stopServer];
        return NO;
    }
    
    // Now that the IPv4 binding was successful, we get the port number.
    // -- we'll need it for the IPv6 listening socket and for the NSNetService.
    NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4socket);
    assert([addr length] == sizeof(struct sockaddr_in));
    self.port = ntohs(((const struct sockaddr_in*)[addr bytes])->sin_port);
    
    // Set up the IPv6 listening socket.
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(self.port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv6socket, (__bridge CFDataRef)[NSData dataWithBytes:&addr6 length:sizeof(addr6)])) {
        [self stopServer];
        return NO;
    }
    
    // Set up the run loop sources for the sockets.
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
    CFRelease(source4);
    
    CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
    CFRelease(source6);
    
    return YES;
}

- (void)echoConnectionDidCloseNotification:(NSNotification *)notification
{
    BonjourConnection *connection = [notification object];
    assert([connection isKindOfClass:[BonjourConnection class]]);
    
}

- (void)acceptConnection:(CFSocketNativeHandle)nativeSocketHandle
{
    CFReadStreamRef readStream = nil;
    CFWriteStreamRef writeStream = nil;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
    
    if (readStream && writeStream)
    {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        BonjourConnection * connection = [[BonjourConnection alloc]initWithInputStream:(__bridge NSInputStream *)readStream outputStream:(__bridge NSOutputStream*)writeStream];
        [self.connections addObject:connection];
        [connection openStreams];
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(echoConnectionDidCloseNotification:) name:EchoConnectionDidCloseNotification object:connection];
        
        [Util postNotification:EchoConnectionDidCloseNotification];
        
        NSLog(@"Added connection %@",connection);
    }
    else
    {
        // On any failed, we need to destroy the CFSocketNativeHandle
        // since we're not going to use it any more
        (void)close(nativeSocketHandle);
    }
    if (readStream) CFRelease(readStream);
    if (writeStream) CFRelease(writeStream);
}

@end
