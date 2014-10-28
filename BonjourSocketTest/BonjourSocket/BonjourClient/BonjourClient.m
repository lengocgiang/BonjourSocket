//
//  EchoClient.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourClient.h"
#import "Util.h"

@interface NSNetService(qNetworkAdditions)
- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr outputStream:(out NSOutputStream **)outputStreamPtr;
@end

@implementation NSNetService(qNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr
                            outputStream:(out NSOutputStream **)outputStreamPtr
// The following works around three problems with
// -[NSNetService getInputStream:outputStream:]:
//
// o <rdar://problem/6868813> -- Currently the returns the streams with
//   +1 retain count, which is counter to Cocoa conventions and results in
//   leaks when you use it in ARC code.
//
// o <rdar://problem/9821932> -- If you create two pairs of streams from
//   one NSNetService and then attempt to open all the streams simultaneously,
//   some of the streams might fail to open.
//
// o <rdar://problem/9856751> -- If you create streams using
//   -[NSNetService getInputStream:outputStream:], start to open them, and
//   then release the last reference to the original NSNetService, the
//   streams never finish opening.  This problem is exacerbated under ARC
//   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) ) {
        CFNetServiceRef     netService;
        
        netService = CFNetServiceCreate(
                                        NULL,
                                        (__bridge CFStringRef) [self domain],
                                        (__bridge CFStringRef) [self type],
                                        (__bridge CFStringRef) [self name],
                                        0
                                        );
        if (netService != NULL) {
            CFStreamCreatePairWithSocketToNetService(
                                                     NULL,
                                                     netService,
                                                     ((inputStreamPtr  != nil) ? &readStream  : NULL),
                                                     ((outputStreamPtr != nil) ? &writeStream : NULL)
                                                     );
            CFRelease(netService);
        }
        
        // We have failed if the client requested an input stream and didn't
        // get one, or requested an output stream and didn't get one.  We also
        // fail if the client requested neither the input nor the output
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) ||
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}


@end
#pragma mark - 
#pragma mark - EchoClient class

enum {
    kSendBufferSize = 32768
};


@interface BonjourClient()
<
    NSNetServiceBrowserDelegate,
    NSStreamDelegate
>
@property (nonatomic, strong, readwrite) NSNetServiceBrowser            *serviceBrowser;
@property (nonatomic, strong, readwrite) NSMutableArray                 *services;

@property (nonatomic, strong, readwrite) NSInputStream                  *inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream                 *outputStream;
@property (nonatomic, strong, readwrite) NSMutableData                  *inputBuffer;
@property (nonatomic, strong, readwrite) NSMutableData                  *outputBuffer;

@property (nonatomic, strong, readwrite) NSInputStream                  *fileStream;
@property (nonatomic, strong, readwrite) NSOutputStream                 *networkStream;

@property (nonatomic, assign, readonly ) uint8_t                        *buffer;
@property (nonatomic, assign, readwrite) size_t                         bufferOffset;
@property (nonatomic, assign, readwrite) size_t                         bufferLimit;

// forward declarations
- (void)closeStreams;

@end

@implementation BonjourClient
{
    uint8_t             _buffer[kSendBufferSize];
}

+ (BonjourClient *)sharedBrowser
{
    static BonjourClient *_sharedBrowser = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _sharedBrowser = [[BonjourClient alloc]init];
    });
    
    return _sharedBrowser;
}
- (id)init
{
    self = [super init];
    if (self) {
        self.services = [[NSMutableArray alloc]init];
    }
    return self;
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

#pragma mark - Public methods
- (void)browserForServer
{
    [self browserForServerWithType:@"_gcocoaecho._tcp"];
}

- (void)browserForServerWithType:(NSString *)serverType
{
    self.serviceBrowser = [[NSNetServiceBrowser alloc]init];
    [self.serviceBrowser setDelegate:self];
    [self.serviceBrowser searchForServicesOfType:serverType inDomain:@"local"];
}

- (NSArray *)availableService
{
    return (NSArray *)self.services;
}
- (void)stopBrowserSearchForServer
{
    [self.serviceBrowser setDelegate:nil];
    [self.serviceBrowser stop];
    self.serviceBrowser = nil;
    self.services = [NSMutableArray new];
}

- (void)outputText:(NSString *)text
{
    NSData * dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (self.outputBuffer != nil)
    {
        BOOL wasEmpty = ([self.outputBuffer length] == 0);
        [self.outputBuffer appendData:dataToSend];
        if (wasEmpty) {
            [self startOutput];
        }
    }
}

- (void)startSendFileWithPath:(NSString *)filePath toNetService:(NSNetService *)netService
{
    NSInputStream   *input;
    NSOutputStream  *output;
    BOOL            success;
    
    assert(filePath != nil);            // check file path exists
    
    assert(self.outputStream == nil);   // don't tap send twice in a row
    assert(self.inputStream == nil);    // did to
    
    // Open a stream for the file
    self.inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    assert(self.inputStream == nil);
    
    // Open stream to the server, finding the server via Bonjour. Then configure
    // the stream for async operation
    success = [netService qNetworkAdditions_getInputStream:&input outputStream:&output];
    assert(success);
    
    self.inputStream = input;
    self.outputStream = output;
    
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream open];
    [self.outputStream open];
    
    // Tell the UI we're sending
    [Util postNotification:kBonjourClientStartSendDataNotification];
    
}

#pragma mark - Private Methods
- (void)openStreamToConnectNetService:(NSNetService *)netService
{
    NSInputStream       *istream;
    NSOutputStream      *ostream;
    
    [self closeStreams];
    
    if ([netService qNetworkAdditions_getInputStream:&istream outputStream:&ostream])
    {
        self.inputStream    = istream;
        self.outputStream   = ostream;
        [self.inputStream setDelegate:self];
        [self.outputStream setDelegate:self];
        
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self.inputStream open];
        [self.outputStream open];
    }
    
    [Util postNotification:kEchoClientOpenStreamSuccess];
}
- (void)closeStreams
{
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    
    [self.inputStream close];
    [self.outputStream close];
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    self.inputStream    = nil;
    self.outputStream   = nil;
    self.inputBuffer    = nil;
    self.outputStream   = nil;
}

#pragma mark - NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if (![self.services containsObject:aNetService])
    {
        [self.services addObject:aNetService];
    }
    if (!moreComing)
    {
        [Util postNotification:kBonjourClientBrowserSuccessNotification];
    }
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ([self.services containsObject:aNetService])
    {
        [self.services removeObject:aNetService];
    }
    if (!moreComing) {
        [Util postNotification:kBonjourClientBrowserRemoveServiceNotification];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
//    [self.serviceBrowser setDelegate:nil];
//    [self.serviceBrowser stop];
//    self.serviceBrowser = nil;
    
    [Util postNotification:kBonjourClientBrowserSearchErrorNotification];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
//    [self.serviceBrowser setDelegate:nil];
//    self.serviceBrowser = nil;
    
    [Util postNotification:kBonjourClientBrowserStopSearchNotification];
}

#pragma mark - Stream method

- (void)startOutput
{
    assert([self.outputBuffer length] != 0);
    
    NSInteger actuallyWritten = [self.outputStream write:[self.outputBuffer bytes] maxLength:[self.outputBuffer length]];
    
    if (actuallyWritten > 0)
    {
        [self.outputBuffer replaceBytesInRange:NSMakeRange(0, (NSUInteger)actuallyWritten) withBytes:NULL length:0];
        // If we didn't write all the bytes we'll continue writing them in response to the
        // next has-space-avaiable event
    }
    else
    {
        // A non-positive result from -write:maxLength: indicates a failure of some form
        // in this simple app we respond by simply closing down our connection
        [self closeStreams];
    }
        
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    assert(aStream == self.inputStream || aStream == self.outputStream);
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            // I don't create the input and output buffers until I get the open-completed
            // events. This's important for the output buffer because -outputText: is a no-op
            // until the buffer is in place, which avoid us trying to write to a stream
            // that's still in the process of opening
            if (aStream == self.inputStream)
            {
                self.inputBuffer = [[NSMutableData alloc]init];
                self.outputBuffer = [[NSMutableData alloc]init];
            }
        }break;
            
        case NSStreamEventHasSpaceAvailable:
        {// sent request -> output
            if ([self.outputBuffer length] != 0)
            {
                [self startOutput];
            }
        }break;
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
            if (actuallyRead > 0)
            {
                [self.inputBuffer appendBytes:buffer length:(NSInteger)actuallyRead];
                // If the input buffer ends with CR LF, show it to the user.
                if([self.inputBuffer length] >= 2 && memcmp((const char *)[self.inputBuffer bytes] +[self.inputBuffer length] - 2, @"\rn", 2) == 0)
                    
                {
                    NSString *string = [[NSString alloc]initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
                    if (string == nil)
                    {
                        NSLog(@"");
                        [[[UIAlertView alloc]initWithTitle:@"Response" message:@"deo co gi em oi @@" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    }
                    else
                    {
                        [[[UIAlertView alloc]initWithTitle:@"Response" message:string delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    }
                    [self.inputBuffer setLength:0];
                }
            }
            else
            {
                // A non-positive value from - read:maxLength: indicates either end of file (0)
                // or an error (-1). In either case I just wait for the corresponding stream event
                // to come throught
            }
        }break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
        {
            [self closeStreams];
        }break;
        default:
            break;
    }
}


- (void)stopSendDataWithStatus:(NSUInteger)status
{
    if (self.networkStream != nil)
    {
        self.networkStream.delegate = nil;
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil)
    {
        [self.fileStream close];
        self.fileStream = nil;
    }
    self.bufferLimit    = 0;
    self.bufferOffset   = 0;
    
    switch (status) {
        case BonjourClientSendDataError:
        {
            [Util postNotification:kBonjourClientSendDataWithErrorNotification];
        }break;
            
        case BonjourClientSendDataDidFinished:
        {
            [Util postNotification:kBonjourClientSendDataDidFinishedNotification];
        }break;
            
        case BonjourClientSendDataDidCanceled:
        {
            [Util postNotification:kBonjourClientSendDataDidCanceledNotification];
        }
        default:
            break;
    }
}

@end
