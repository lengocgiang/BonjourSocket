//
//  EchoConnection.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//  featureAudio2

#import "BonjourConnection.h"
#import "Util.h"

#import <pthread.h>
#import <AVFoundation/AVFoundation.h>
#define PRINTERROR(LABEL)	printf("%s err %4.4s %ld\n", LABEL, (char *)&err, err)


UInt32 const kTDAudioStreamReadMaxLength = 512;
UInt32 const kTDAudioQueueBufferSize = 2048;
UInt32 const kTDAudioQueueBufferCount = 16;
UInt32 const kTDAudioQueueStartMinimumBuffers = 8;

NSString * EchoConnectionDidOpenNotification        = @"EchoConnectionDidOpenNotification";
NSString * EchoConnectionDidCloseNotification       = @"EchoConnectionDidCloseNotification";
NSString * EchoConnectionDidRequestedNotification   = @"EchoConnectionDidRequestedNotification";

@interface BonjourConnection()
<
    NSStreamDelegate
>
enum {
    kSendBufferSize = 32768
};


@property (strong, nonatomic, readwrite) NSInputStream          *inputStream;
@property (strong, nonatomic, readwrite) NSOutputStream         *outputStream;

@property (strong, nonatomic) NSString                          *filePath;

@property (nonatomic, assign, readonly ) uint8_t                        *buffer;
@property (nonatomic, assign, readwrite) size_t                         bufferOffset;
@property (nonatomic, assign, readwrite) size_t                         bufferLimit;


@end

@implementation BonjourConnection
{
    uint8_t             _buffer[kSendBufferSize];
}

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    self = [super init];

    if (self)
    {
        self->_inputStream = inputStream;
        self->_outputStream = outputStream;
    }
    return self;
    
}
- (uint8_t *)buffer
{
    return self->_buffer;
}

- (BOOL)openStreams
{
    NSLog(@"SERVER: Open stream");
    NSString *path = [[NSBundle mainBundle]pathForResource:@"music2" ofType:@"mp3"];

    self.inputStream = [NSInputStream inputStreamWithFileAtPath:path];

    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream open];
    [self.outputStream open];
    
    //[(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidOpenNotification object:self];
    
    return YES;
}

- (void)closeStreams
{
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];

    [self.inputStream close];
    [self.outputStream close];
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidCloseNotification object:self];
    
}
- (void)closeStreamsWithStatus:(NSString *)status
{
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    
    [self.inputStream close];
    [self.outputStream close];
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.inputStream = nil;
    self.outputStream = nil;

    //[self receiveDidStopWithStatus:status];
    
    self.filePath = nil;
    
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidCloseNotification object:self];
    
}

- (void)receiveDidStopWithStatus:(NSString *)status
{
    NSLog(@"----SERVER: RECEIVER DATA HAS COMPLETED-----");
    if (status == nil)
    {
        assert(self.filePath != nil);

//        NSURL *url = [NSURL fileURLWithPath:self.filePath];
//        NSError *error = nil;
        UIImage *img = [UIImage imageWithContentsOfFile:self.filePath];
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        
//        self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
//        if (error) {
//            NSLog(@"Error in audioPlayer %@",[error localizedDescription]);
//        }
//        else
//        {
//            [self.audioPlayer prepareToPlay];
//            [self.audioPlayer play];
//        }
    }
}


#pragma mark - NSStreamDelegate
/**
    Trạng thái trả về NSStreamStatus là một hằng chỉ ra "Stream" đang được mở, ghi
    ở cuối stream.
    Một khi các đối tượng Stream đã được mở ra, nó vẫn sẽ tiếp tục gửi thông điệp
    stream:handleEvent cho delegate(miễn là các delegate vẫn tiếp tục đặt "byte" lên stream)
    Cho đến khi nó gặp cuối stream. Các thông điệp này bao gồm một tham số là
    hằng số NSStreamEvent nó cho biết các loại sự kiện. 
    Với các đối tượng NSOutputStream kiểu sự kiện phổ biến nhất là:
    NSStreamEventOpenCompleted, NSStreamEventHasSpaceAvailable, và NSStreamEventEndEncountered
    Các delegate thường "quan tâm" nhất tới sự kiện NSStreamEventHasSpaceAvailable.
 
    NSStreamEventOpenCompleted, kiểm tra kết nối đã được mở ?
    NSStreamEventHasBytesAvailable, nhận thông điệp
    NSStreamEventErrorOccurred, kiểm tra các vấn đề trong khi kết nối
    NSStreamEventEndEncountered, đóng stream khi server down
 
    The core point here is the NSStreamEventHasBytesAvailable case. Here we should:
     - read bytes from the stream
     - collect them in a buffer
     - transform the buffer in a string
     - add the string to the array of messages

 */
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //assert(aStream == self.inputStream || aStream == self.outputStream);
    #pragma unused(aStream)
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            // Start receiver incoming data
            //[self receiveData];

        }break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            [self sendData];
            
        }break;
            
        case NSStreamEventOpenCompleted:
        {}break;
            
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
        {
            NSError *theError = [aStream streamError];
            NSLog(@"Error reading stream! \n %zd %@",[theError code],[theError localizedDescription]);
            [self closeStreams];
            
        }break;
            
        default:
        {
            // do nothing
        }break;
    }
}
- (void)sendingMusicData
{
    
}
- (void)sendData
{
    if (self.bufferOffset == self.bufferLimit)
    {
        NSInteger bytesRead = [self.inputStream read:self.buffer maxLength:kSendBufferSize];
        if (bytesRead == -1)
        {
            NSLog(@"Server : File read error");
            [self closeStreamsWithStatus:@"File read error"];
        }
        else if (bytesRead ==0)
        {
            NSLog(@"Server: Sending data successful");
            [self closeStreamsWithStatus:nil];
        }
        else
        {
            self.bufferOffset = 0;
            self.bufferLimit = bytesRead;
        }   
    }
    if (self.bufferOffset != self.bufferLimit)
    {
        NSInteger bytesWritten;
        bytesWritten = [self.outputStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
        assert(bytesWritten != 0);
        if (bytesWritten == -1)
        {
            NSLog(@"Network write error");
            [self closeStreamsWithStatus:@"Network write error"];
        }
        else
        {
            self.bufferOffset += bytesWritten;
        }
        NSLog(@"bytesWritten %zd",bytesWritten);
    }
}

- (void)receiveData
{
    NSInteger       bytesRead;
    uint8_t         buffer[32768];
    
    //[self updateStatus:@"Receiving"];
    
    // Pull some data off the network.
    
    bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
    if (bytesRead == -1) {
        //[self stopReceiveWithStatus:@"Network read error"];
        NSLog(@"Network read error");
        [self closeStreamsWithStatus:@"Network read error"];
        //[self closeStreams];
    } else if (bytesRead == 0) {
        //[self stopReceiveWithStatus:nil];
        [self closeStreamsWithStatus:nil];
        
    } else {
        NSInteger   bytesWritten;
        NSInteger   bytesWrittenSoFar;
        
        // Write to the file.
        
        bytesWrittenSoFar = 0;
        do {
            bytesWritten = [self.outputStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
            assert(bytesWritten != 0);
            if (bytesWritten == -1) {
                NSLog(@"File write error");
                [self closeStreamsWithStatus:@"File write error"];
                break;
            } else {
                bytesWrittenSoFar += bytesWritten;
            }
        } while (bytesWrittenSoFar != bytesRead);
        NSLog(@"SERVER:receiving--- %.2fKB ",(float)bytesWrittenSoFar/1024);

    }
}

@end
