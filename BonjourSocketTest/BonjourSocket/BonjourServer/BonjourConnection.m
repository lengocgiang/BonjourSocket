//
//  EchoConnection.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

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

const unsigned int kNumAQBufs = 3;			// number of audio queue buffers we allocate
const size_t kAQBufSize = 128 * 1024;		// number of bytes in each audio queue buffer
const size_t kAQMaxPacketDescs = 512;		// number of packet descriptions in our array

struct MyData
{
    AudioFileStreamID audioFileStream;	// the audio file stream parser
    
    AudioQueueRef audioQueue;								// the audio queue
    AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
    
    AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
    
    unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
    size_t bytesFilled;				// how many bytes have been filled
    size_t packetsFilled;			// how many packets have been filled
    
    bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
    bool started;					// flag to indicate that the queue has been started
    bool failed;					// flag to indicate an error occurred
    
    pthread_mutex_t mutex;			// a mutex to protect the inuse flags
    pthread_cond_t cond;			// a condition varable for handling the inuse flags
    pthread_cond_t done;			// a condition varable for handling the inuse flags
};

typedef struct MyData MyData;

void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

void MyPropertyListenerProc(	void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags);

void MyPacketsProc(				void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions);

OSStatus MyEnqueueBuffer(MyData* myData);
void WaitForFreeBuffer(MyData* myData);


@interface BonjourConnection()
<
    NSStreamDelegate
>
@property (strong, nonatomic, readwrite) NSInputStream          *inputStream;
@property (strong, nonatomic, readwrite) NSOutputStream         *outputStream;

@property (strong, nonatomic) NSNumber                          *bytesRead;
@property (strong, nonatomic) NSNumber                          *bytesWritten;

@property (strong, nonatomic) NSString                          *filePath;
// Audio Stream
@property (strong, nonatomic) AVAudioPlayer                     *audioPlayer;
@property (assign, nonatomic) UInt32 audioStreamReadMaxLength;
@property (assign, nonatomic) UInt32 audioQueueBufferSize;
@property (assign, nonatomic) UInt32 audioQueueBufferCount;

@end

@implementation BonjourConnection
@synthesize audioQueueBufferCount = _audioQueueBufferCount;
@synthesize audioQueueBufferSize = _audioQueueBufferSize;
@synthesize audioStreamReadMaxLength = _audioStreamReadMaxLength;

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
    [(NSNotificationCenter*)[NSNotificationCenter defaultCenter]postNotificationName:EchoConnectionDidOpenNotification object:self];
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
            MyData *myData = (MyData *)calloc(1, sizeof(MyData));
            
            // initialize a mutex and condition so that we can block on buffers in use.
            pthread_mutex_init(&myData->mutex, NULL);
            pthread_cond_init(&myData->cond, NULL);
            pthread_cond_init(&myData->done, NULL);
            
            OSStatus err = AudioFileStreamOpen(myData, MyPropertyListenerProc, MyPacketsProc,
                                               kAudioFileAAC_ADTSType, &myData->audioFileStream);
            //if (err) { PRINTERROR("AudioFileStreamOpen");}
        
            while (!myData ->failed)
            {
                // READ data from socket
                uint8_t buffer[512];            // data
                NSUInteger bytesRead;           // length of data
                bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                
                if (bytesRead <= 0) break;      // eof or failure
                
                // parse the data, this will call MyPropertyListenerProc and MyPacketsProc
                err = AudioFileStreamParseBytes(myData->audioFileStream, (UInt32)bytesRead, buffer, 0);
                //if (err) {PRINTERROR("AudioFileStreamParseBytes");}
            }
            // enqueue last buffer
            MyEnqueueBuffer(myData);
            
            printf("flushing\n");
            err = AudioQueueFlush(myData->audioQueue);
            //if (err) {PRINTERROR("AudioQueueFlush");}
            
            printf("Stoping\n");
            err = AudioQueueStop(myData->audioQueue, false);
            //if(err){PRINTERROR("AudioQueueStop");}
            
            printf("waiting until finished playing...\n");
            pthread_mutex_lock(&myData->mutex);
            pthread_cond_wait(&myData->done, &myData->mutex);
            pthread_mutex_unlock(&myData->mutex);
            
            printf("done \n");
            
            err = AudioFileStreamClose(myData->audioFileStream);
            err = AudioQueueDispose(myData->audioQueue, false);
            //close(connection_socket);
            [self closeStreams];

        }break;
            
        case NSStreamEventHasSpaceAvailable:
        {}break;
            
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


#pragma mark - Audio Properties

void MyPropertyListenerProc(void *                          inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags)
{
    // this is called by audio file stream when it finds property values
    MyData* myData = (MyData*)inClientData;
    OSStatus err = noErr;
    
    printf("found property '%c%c%c%c'\n", (char)(inPropertyID>>24)&255, (char)(inPropertyID>>16)&255, (char)(inPropertyID>>8)&255, (char)inPropertyID&255);
    
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets :
        {
            // the file stream parser is now ready to produce audio packets.
            // get the stream format.
            AudioStreamBasicDescription asbd;
            UInt32 asbdSize = sizeof(asbd);
            err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
            if (err) { PRINTERROR("get kAudioFileStreamProperty_DataFormat"); myData->failed = true; break; }
            
            // create the audio queue
            err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, myData, NULL, NULL, 0, &myData->audioQueue);
            if (err) { PRINTERROR("AudioQueueNewOutput"); myData->failed = true; break; }
            
            // allocate audio queue buffers
            for (unsigned int i = 0; i < kNumAQBufs; ++i) {
                err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[i]);
                if (err) { PRINTERROR("AudioQueueAllocateBuffer"); myData->failed = true; break; }
            }
            
            // get the cookie size
            UInt32 cookieSize;
            Boolean writable;
            err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
            if (err) { PRINTERROR("info kAudioFileStreamProperty_MagicCookieData"); break; }
            printf("cookieSize %d\n", (unsigned int)cookieSize);
            
            // get the cookie data
            void* cookieData = calloc(1, cookieSize);
            err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
            if (err) { PRINTERROR("get kAudioFileStreamProperty_MagicCookieData"); free(cookieData); break; }
            
            // set the cookie on the queue.
            err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
            free(cookieData);
            if (err) { PRINTERROR("set kAudioQueueProperty_MagicCookie"); break; }
            
            // listen for kAudioQueueProperty_IsRunning
            err = AudioQueueAddPropertyListener(myData->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, myData);
            if (err) { PRINTERROR("AudioQueueAddPropertyListener"); myData->failed = true; break; }
            
            break;
        }
    }
}

void MyPacketsProc(				void *				inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *                     inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions)
{
    // this is called by audio file stream when it finds packets of audio
    MyData* myData = (MyData*)inClientData;
    printf("got data.  bytes: %d  packets: %d\n", (unsigned int)inNumberBytes, (unsigned int)inNumberPackets);
    
    // the following code assumes we're streaming VBR data. for CBR data, you'd need another code branch here.
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
        SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
        
        // if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
        size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
        if (bufSpaceRemaining < packetSize) {
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
        
        // copy data to the audio queue buffer
        AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
        memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
        // fill out packet description
        myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
        myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
        // keep track of bytes filled and packets filled
        myData->bytesFilled += packetSize;
        myData->packetsFilled += 1;
        
        // if that was the last free packet description, then enqueue the buffer.
        size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
        if (packetsDescsRemaining == 0) {
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
    }
}

OSStatus StartQueueIfNeeded(MyData* myData)
{
    OSStatus err = noErr;
    if (!myData->started) {		// start the queue if it has not been started already
        err = AudioQueueStart(myData->audioQueue, NULL);
        if (err) { PRINTERROR("AudioQueueStart"); myData->failed = true; return err; }
        myData->started = true;
        printf("started\n");
    }
    return err;
}

OSStatus MyEnqueueBuffer(MyData* myData)
{
    OSStatus err = noErr;
    myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
    fillBuf->mAudioDataByteSize = myData->bytesFilled;
    err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
    if (err) { PRINTERROR("AudioQueueEnqueueBuffer"); myData->failed = true; return err; }
    
    StartQueueIfNeeded(myData);
    
    return err;
}


void WaitForFreeBuffer(MyData* myData)
{
    // go to next buffer
    if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
    myData->bytesFilled = 0;		// reset bytes filled
    myData->packetsFilled = 0;		// reset packets filled
    
    // wait until next buffer is not in use
    printf("->lock\n");
    pthread_mutex_lock(&myData->mutex);
    while (myData->inuse[myData->fillBufferIndex]) {
        printf("... WAITING ...\n");
        pthread_cond_wait(&myData->cond, &myData->mutex);
    }
    pthread_mutex_unlock(&myData->mutex);
    printf("<-unlock\n");
}

int MyFindQueueBuffer(MyData* myData, AudioQueueBufferRef inBuffer)
{
    for (unsigned int i = 0; i < kNumAQBufs; ++i) {
        if (inBuffer == myData->audioQueueBuffer[i])
            return i;
    }
    return -1;
}


void MyAudioQueueOutputCallback(	void*					inClientData,
                                AudioQueueRef			inAQ,
                                AudioQueueBufferRef		inBuffer)
{
    // this is called by the audio queue when it has finished decoding our data.
    // The buffer is now free to be reused.
    MyData* myData = (MyData*)inClientData;
    
    unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
    
    // signal waiting thread that the buffer is free.
    pthread_mutex_lock(&myData->mutex);
    myData->inuse[bufIndex] = false;
    pthread_cond_signal(&myData->cond);
    pthread_mutex_unlock(&myData->mutex);
}

void MyAudioQueueIsRunningCallback(		void*					inClientData, 
                                   AudioQueueRef			inAQ, 
                                   AudioQueuePropertyID	inID)
{
    MyData* myData = (MyData*)inClientData;
    
    UInt32 running;
    UInt32 size;
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
    if (err) { PRINTERROR("get kAudioQueueProperty_IsRunning"); return; }
    if (!running) {
        pthread_mutex_lock(&myData->mutex);
        pthread_cond_signal(&myData->done);
        pthread_mutex_unlock(&myData->mutex);
    }
}


@end
