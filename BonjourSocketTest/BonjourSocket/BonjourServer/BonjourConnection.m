//
//  EchoConnection.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourConnection.h"
#import "Util.h"

NSString * EchoConnectionDidOpenNotification        = @"EchoConnectionDidOpenNotification";
NSString * EchoConnectionDidCloseNotification       = @"EchoConnectionDidCloseNotification";
NSString * EchoConnectionDidRequestedNotification   = @"EchoConnectionDidRequestedNotification";

@interface BonjourConnection()
<
    NSStreamDelegate
>
@property (strong, nonatomic, readwrite) NSInputStream          *inputStream;
@property (strong, nonatomic, readwrite) NSOutputStream         *outputStream;

@property (strong, nonatomic) NSMutableData                     *receiveData;
@property (strong, nonatomic) NSMutableData                     *sendData;

@property (strong, nonatomic) NSNumber                          *bytesRead;
@property (strong, nonatomic) NSNumber                          *bytesWritten;

@property (strong, nonatomic) NSString                          *filePath;

@end

@implementation BonjourConnection
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

- (BOOL)openStreams
{
    NSLog(@"open stream");
 
    self.filePath = [[Util sharesInstance]pathForTemporaryFileWithPrefix:@"Receive"];
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
    
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    return YES;
}

- (void)closeStreams
{
    NSLog(@"close stream");
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
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

    [self receiveDidStopWithStatus:status];
    
    self.filePath = nil;
    
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidCloseNotification object:self];
    
}

- (void)receiveDidStopWithStatus:(NSString *)status
{
    NSLog(@"SAVE IMAGE DONE!!!!!");
    if (status == nil)
    {
        assert(self.filePath != nil);
        UIImage *img = [UIImage imageWithContentsOfFile:self.filePath];
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    }
}
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
        {// input Stream
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
                NSLog(@"bytesWrittenSoFar %.2fKB",(float)bytesWrittenSoFar/1024);
            }

        }break;
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
        {
            NSError *theError = [aStream streamError];
            NSLog(@"Error reading stream! \n %zd %@",[theError code],[theError localizedDescription]);
            [self closeStreams];

            break;

        }break;
            
        case NSStreamEventHasSpaceAvailable:
        {

        }break;
            
        case NSStreamEventOpenCompleted:
        {
            
        }break;
            
        default:
        {
            // do nothing
        }break;
    }
}


@end
