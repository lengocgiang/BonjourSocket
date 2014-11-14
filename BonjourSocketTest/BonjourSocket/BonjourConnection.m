//
//  EchoConnection.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//  featureAudio2

#import "BonjourConnection.h"
#import "Util.h"

// Declare C callback functions
void readStreamEventHandler(CFReadStreamRef stream,CFStreamEventType eventType,void *info);
void writeStreamEventHandler(CFWriteStreamRef stream,CFStreamEventType eventType,void *info);

// Private properties and methods
@interface BonjourConnection()
<
    NSNetServiceDelegate
>
// Properties
@property (strong, nonatomic) NSString              *host;
@property (assign, nonatomic) int                   port;
@property (assign, nonatomic) CFSocketNativeHandle  connectedSocketHandle;
@property (strong, nonatomic) NSNetService          *netService;

// Initialize
- (void)clean;

// Further setup streams created by one of the 'init' methods
- (BOOL)setupSocketStreams;

// Stream event handlers
- (void)readStreamHandleEvent:(CFStreamEventType)event;
- (void)writeStreamHandleEvent:(CFStreamEventType)event;

// Read all available bytes from the read stream into buffer and try to extract packets
- (void)readFromStreamIntoIncomingBuffer;

// Write whatever data we have in the buffer, as much as stream can hanle
- (void)writeOutgoingBufferToStream;

@end

@implementation BonjourConnection
@synthesize delegate;
@synthesize host,port;
@synthesize connectedSocketHandle;
@synthesize netService;


// Initialize, empty
- (void)clean
{
    readStream      = nil;
    readStreamOpen  = NO;
    
    writeStream     = nil;
    writeStreamOpen = NO;
    
    incomingDataBuffer =nil;
    outgoingDataBuffer = nil;
    
    self.netService         = nil;
    self.host               = nil;
    connectedSocketHandle   = -1;
    packetBodySize          = -1;
}

- (void)dealloc
{
    self.netService = nil;
    self.host = nil;
    self.delegate = nil;
    
}

// Initialize and store connection information until 'connect' is called
- (id)initWithHostAddress:(NSString *)_host andPort:(int)_port
{
    [self clean];
    
    self.host = _host;
    self.port = _port;
    
    return self;
}

// Initialize using a native socket handle, assuming connection is open
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle
{
    [self clean];
    
    self.connectedSocketHandle = nativeSocketHandle;
    
    return self;
}

// Initialize using an instance of NSNetService
- (id)initWithNetService:(NSNetService *)_netService
{
    [self clean];
    
    // Has it been resolved?
    if (_netService.hostName != nil)
    {
        return [self initWithHostAddress:_netService.hostName andPort:(int)_netService.port];
    }
    self.netService = _netService;
    
    return self;
}

// Connect using whatever connection info that was passed during initialization
- (BOOL)connect
{
    if (self.host != nil)
    {
        // Bind read/write streams to a new socket
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           (__bridge CFStringRef)self.host,
                                           self.port,
                                           &readStream, &writeStream);
        // Do the rest
        return [self setupSocketStreams];
    }
    else if (self.connectedSocketHandle != -1)
    {
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, self.connectedSocketHandle, &readStream, &writeStream);
        // Do the rest
        return [self setupSocketStreams];
    }
    else if (netService != nil)
    {
        // Still need to resolve?
        if (netService.hostName != nil)
        {
            CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)netService.hostName, (UInt32)netService.port, &readStream, &writeStream);
            return [self setupSocketStreams];
        }
        // Start resolving
        netService.delegate = self;
        [netService resolveWithTimeout:5.0];
        
        return YES;
    }
    // Nothing was passed, connection is not possible
    return NO;

}

// Further setup socket streams that were created by one of out 'init' methods
- (BOOL)setupSocketStreams
{
    if (readStream == nil || writeStream == nil)
    {
        [self close];
        return NO;
    }
    
    // Create buffers
    incomingDataBuffer = [NSMutableData data];
    outgoingDataBuffer = [NSMutableData data];
    
    // Indicate that we want socket to be closed whatever streams are closed
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    // We'll be handling the following streams events
    CFOptionFlags registeredEvents =    kCFStreamEventOpenCompleted |
                                        kCFStreamEventHasBytesAvailable|
                                        kCFStreamEventCanAcceptBytes|
                                        kCFStreamEventEndEncountered|
                                        kCFStreamEventErrorOccurred;
    // Setup stream context - reference to 'self' will be passed to stream event handling callbacks
    CFStreamClientContext ctx = {0,(__bridge void *)(self),NULL,NULL,NULL};
    
    // Specify callbacks that will be handling stream events
    CFReadStreamSetClient(readStream, registeredEvents, readStreamEventHandler, &ctx);
    CFWriteStreamSetClient(writeStream, registeredEvents, writeStreamEventHandler, &ctx);
    
    // Schedule streams with current run loop
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    // Open both streams
    if (!CFReadStreamOpen(readStream) || !CFWriteStreamOpen(writeStream)) {
        [self close];
        return NO;
    }
    
    return YES;
}

// Close connection
- (void)close
{
    // cleanup read stream
    if (readStream != nil)
    {
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        readStream = nil;
    }
    // cleanup write stream
    if (writeStream != nil)
    {
        CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFWriteStreamClose(writeStream);
        CFRelease(writeStream);
        writeStream = nil;
    }
    // Cleanup buffers
    incomingDataBuffer = nil;
    outgoingDataBuffer = nil;
    
    
    // Stop net service
    if (netService != nil)
    {
        [netService stop];
        self.netService = nil;
    }
    // Reset all other variable
    [self clean];
}

// Send network message
- (void)sendNetworkPackage:(NSDictionary *)packet
{
    NSData *rawPacket = [NSKeyedArchiver archivedDataWithRootObject:packet];
    
    // Write header: lengh of raw packet
    int packetLength = (int)[rawPacket length];
    [outgoingDataBuffer appendBytes:&packetLength length:sizeof(int)];
    
    // Write body: encoded NSDictionary
    [outgoingDataBuffer appendData:rawPacket];
    
    // Try to write to steam
    [self writeOutgoingBufferToStream];
}

// Send network data
- (void)sendNetworkData:(NSData *)data
{
    NSData *rawData = [NSKeyedArchiver archivedDataWithRootObject:data];
    
    // Write header: length of raw data
    int dataLength = (int)[rawData length];
    [outgoingDataBuffer appendBytes:&dataLength length:sizeof(int)];
    
    // Write body:
    [outgoingDataBuffer appendData:rawData];
    
    // Try to write to stream
    [self writeOutgoingBufferToStream];
}

#pragma mark Read stream methods

// dispatch readStream events
void readStreamEventHandler(CFReadStreamRef stream,CFStreamEventType eventType,void *info)
{
    BonjourConnection *connection = (__bridge BonjourConnection *)info;
    [connection readStreamHandleEvent:eventType];
}

// Handle events from the read stream
- (void)readStreamHandleEvent:(CFStreamEventType)event
{
    // Stream successfully opened
    if (event == kCFStreamEventOpenCompleted)
    {
        readStreamOpen = YES;
    }
    // New data has arrived
    else if (event == kCFStreamEventHasBytesAvailable)
    {
        // Read as many bytes from the stream as possible and try to extract meaningful packets
        [self readFromStreamIntoIncomingBuffer];
    }
    // Connection has been terminated or error encountered( treat them the same way)
    else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred)
    {
        // cleaning everything
        [self close];
        
        // If we haven't connected yet then our connection attempt has failed
        if (!readStreamOpen || !writeStreamOpen)
        {
            [delegate connectionAttemptFailed:self];
        }
        else
        {
            [delegate connectionTerminated:self];
        }
    }
}

//Read as many bytes from the streams as posible and try to extract meaningful packets
- (void)readFromStreamIntoIncomingBuffer
{
    // Temporary buffer to read data into
    UInt8 buffer[1024];
    
    // try reading while there is data
    while (CFReadStreamHasBytesAvailable(readStream))
    {
        CFIndex len = CFReadStreamRead(readStream, buffer, sizeof(buffer));
        if (len <=0) {
            // Either stream was closed or error occured. Close everything up and treat this
            // as 'connection terminated'
            [self close];
            [delegate connectionTerminated:self];
            return;
        }
        [incomingDataBuffer appendBytes:buffer length:len];
    }
    
    // Try to extract packets from the buffer
    /**
     Protocol = header + body
     HEADER  : an integer that indicates length of the body
     BODY    : bytes that represent encoded NSDictionary
     */
    // We might have more than one message in the buffer - that's why we'll be reading
    // it inside the while loop
    while (YES)
    {
        // Did we read the header yet?
        if (packetBodySize == -1)
        {
            // Do we have enought bytes in the buffer to read the header?
            if ([incomingDataBuffer length] > sizeof(int))
            {
                // extract length
                memcpy(&packetBodySize, [incomingDataBuffer bytes], sizeof(int));
                
                // remove that chunk from buffer
                NSRange rangeToDelete  = {0,sizeof(int)};
                [incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:nil length:0]
                ;
            }
        }
        else{
            // we don't have enough yet, wi'' wait for more detail
            break;
        }
        // We should now have the header. Time to extract the body
        if ([incomingDataBuffer length] >= packetBodySize)
        {
            // We now have enough data to extract a meaningful packets31Q
            NSData *raw = [NSData dataWithBytes:[incomingDataBuffer bytes] length:packetBodySize];
            NSDictionary *packet= [NSKeyedUnarchiver unarchiveObjectWithData:raw];
            
            // Tell our delegate about it
            NSLog(@"Server:packet %@",packet);
            [delegate receivedNetworkPacket:packet viaConnection:self];
            
            // Remove that chunk from buffer
            NSRange rangeToDelete = {0,packetBodySize};
            [incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:nil length:0];
            
            // We have processed the packet, resetting the state
            packetBodySize = -1;
        }
        else
        {
            // Not enough data yet, will wait
            break;
        }
    }
}

#pragma mark Write stream methods
// Dispatch writeStream event handling
void writeStreamEventHandler(CFWriteStreamRef stream,CFStreamEventType eventType,void *info)
{
    BonjourConnection *connection = (__bridge BonjourConnection *)info;
    [connection writeStreamHandleEvent:eventType];
}

// Handle events from the write stream
- (void)writeStreamHandleEvent:(CFStreamEventType)event
{
    // Stream successfully opened
    if (event == kCFStreamEventOpenCompleted)
    {
        writeStreamOpen = YES;
    }
    // Stream has space for more data to be written
    else if (event == kCFStreamEventCanAcceptBytes)
    {
        // Write whatever data we have, as much as stream can handle
        [self writeOutgoingBufferToStream];
    }
    // Connection has been terminated or error encountered(we treat them the same way)
    else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred)
    {
        // Clean everything up
        [self close];
        
        // If we haven't connected yet then our connection attemp has failed
        if (!readStreamOpen || !writeStreamOpen)
        {
            [delegate connectionAttemptFailed:self];
        }
        else
        {
            [delegate connectionTerminated:self];
        }
    }
}

// Write whatever data we have, as much of it as stream can handle
- (void)writeOutgoingBufferToStream
{
    // Is connection open?
    if (!readStreamOpen || !writeStreamOpen)
    {
        // No, wait until everything is operational before pushing data throught
        return;
    }
    // do we have anything to write?
    if([outgoingDataBuffer length] == 0)
    {
        return;
    }
    // Can stream take any data in?
    if (!CFWriteStreamCanAcceptBytes(writeStream)) {
        return;
    }
    // Write as much as we can
    CFIndex writtenBytes = CFWriteStreamWrite(writeStream, [outgoingDataBuffer bytes], [outgoingDataBuffer length]);
    
    if (writtenBytes == -1)
    {
        // Error orrcured, close everything up
        [self close];
        [delegate connectionTerminated:self];
        return;
    }
    NSRange range = {0,writtenBytes};
    [outgoingDataBuffer replaceBytesInRange:range withBytes:nil length:0];
}

#pragma mark - 
#pragma mark NSNetService Delegate methods

// Called if we weren't able to resolve net service
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    if (sender != netService) {
        return;
    }
    // Close everything and tell delegate that we have failed
    [delegate connectionTerminated:self];
    [self close];
}

// Called when net service has been succesfully resolve
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if (sender != netService) {
        return;
    }
    // Save connection info
    self.host = netService.hostName;
    self.port = (int)netService.port;
    
    // Don't need the service anymore
    self.netService = nil;
    
    // Connect
    if (![self connect]) {
        [delegate connectionAttemptFailed:self];
        [self close];
    }
}


@end
