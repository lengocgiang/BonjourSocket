//
//  EchoConnection.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourConnection.h"

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
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidCloseNotification object:self];
    
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
    assert(aStream == self.inputStream || aStream == self.outputStream);
    #pragma unused(aStream)
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {// input Stream
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:(uint8_t *)buffer maxLength:sizeof(buffer)];
            if (actuallyRead > 0)
            {
                NSInteger actuallyWritten = [self.outputStream write:buffer maxLength:(NSUInteger)actuallyRead];
                if (actuallyWritten != actuallyRead)
                {
                    //  -write:maxLength: may return -1 to indicate an error or a non-negative
                    //  value less than maxLength to indicate a 'short write'. In the case of an
                    //  error we just shut down the connection. The short write case is more
                    //  interesting. A short write mean that the client has sent us data to echo
                    //  but isn't reading the data the we sent back to it.
                    [self closeStreams];
                }
                else
                {
                    [[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidRequestedNotification object:nil userInfo:nil];
                    NSLog(@"Echoed %zd bytes.",(ssize_t)actuallyWritten);
                }
            }
            else
            {
                // A non-positive value from -read:maxLength indicates either end of file (0)
                // or an error (-1). In either case we just wait for the corresponding stream event
                // to come throught
            }
        }break;
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
        {
            NSError *theError = [aStream streamError];
            NSLog(@"Error reading stream! \n %i %@",[theError code],[theError localizedDescription]);
            [self closeStreams];

            break;

        }break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            // output
            // send data if there're pending
            if (aStream == self.outputStream)
            {
                uint8_t *readBytes = (uint8_t *)[_sendData mutableBytes];
                
                // keep track of pointer position
                readBytes += [_bytesWritten intValue];
                
                NSUInteger data_len = [_sendData length];
                
                NSInteger len = 0;
                len = ((data_len - [_bytesWritten intValue] >= 1024? 1024:data_len - [_bytesWritten intValue]));
                
                _bytesWritten = [NSNumber numberWithLong:([_bytesWritten intValue] + len)];
                
                
            }
            
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
