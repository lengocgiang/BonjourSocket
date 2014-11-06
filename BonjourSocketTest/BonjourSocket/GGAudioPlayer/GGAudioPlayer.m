//
//  GGAudioPlayer.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/3/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "GGAudioPlayer.h"

@implementation GGAudioPlayer

+ (GGAudioPlayer *)sharedInstance
{
    static GGAudioPlayer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[GGAudioPlayer alloc]init];
    });
    return _sharedInstance;
}
 /**
    Initializer the Player with file name and file extension
  */
- (void)initWithAudioFile:(NSString *)audioFile withFileExtension:(NSString *)fileExtension
{
    NSURL *audioFileLocationURL = [[NSBundle mainBundle] URLForResource:audioFile withExtension:fileExtension];
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileLocationURL error:&error];
}

/*
    Simple  fire the play event
 */
- (void)playAudio
{
    [self.audioPlayer play];
}
- (void)pauseAudio
{
    [self.audioPlayer pause];
}

- (NSString *)timeFormat:(float)value
{
    float minutes = floor(lroundf(value/60));
    float seconds = lroundf(value) - (minutes * 60);
    
    int roundedSeconds = (int)lroundf(seconds);
    int roundedMinutes = (int)lroundf(minutes);
    
    NSString *time = [[NSString alloc]initWithFormat:@"%d:%02d",roundedMinutes,roundedSeconds];
    
    return time;
}

- (void)setCurrentAudioTime:(float)value
{
    [self.audioPlayer setCurrentTime:value];
}

- (NSTimeInterval)getCurrentAudioTime
{
    return [self.audioPlayer currentTime];
}

- (float)getAudioDuration
{
    return [self.audioPlayer duration];
}
- (void)convertFloatDataFromAudioFileWithPath:(NSString *)filePath
{
    const char *cString = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
    
    CFStringRef str = CFStringCreateWithCString(nil, cString, kCFStringEncodingMacRoman);
    
    CFURLRef inputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, str, kCFURLPOSIXPathStyle, false);
    
    ExtAudioFileRef fileRef;
    ExtAudioFileOpenURL(inputFileURL, &fileRef);
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = 44100;                    // standand
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
    audioFormat.mBitsPerChannel = sizeof(Float32) * 8;
    audioFormat.mChannelsPerFrame = 1;                  // MONO
    audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * sizeof(Float32);
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    
    // Apple audio format to the Extended audio file
    ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &audioFormat);
    
    int numSamples = 1024;          // samples to read in at a time
    UInt32 sizePerPacket    = audioFormat.mBytesPerPacket;             // 32 bytes
    UInt32 packetsPerBuffer = numSamples;
    UInt32 outputBufferSize = packetsPerBuffer * sizePerPacket;
    
    // So the lvalue of outputBuffer is the memory location where we have reserved space
    UInt8 *outputBuffer= (UInt8 *)malloc(sizeof(UInt8 *) * outputBufferSize);
    
    AudioBufferList convertedData;                                      // = malloc(sizeof(convertedData));
    
    convertedData.mNumberBuffers = 1;                                   // set this to 1 for mono @@
    convertedData.mBuffers[0].mNumberChannels   = audioFormat.mChannelsPerFrame;
    convertedData.mBuffers[0].mDataByteSize     = outputBufferSize;
    convertedData.mBuffers[0].mData             = outputBuffer;
    
    UInt32 frameCount = numSamples;
    float *saplesAsCArray;
    int j =0;
    double floatDataArray[882000];
    
    while (frameCount > 0)
    {
        //ExtAudioFileRead(fileRef, &frameCount, &convertedData);
        ExtAudioFileRead(fileRef, &frameCount, &convertedData);
        if (frameCount > 0)
        {

            AudioBuffer audioBuffer = convertedData.mBuffers[0];
            saplesAsCArray = (float*)audioBuffer.mData;         // cast mdata to float
            
            for (int i =0; i< 1024; i++)
            {
                floatDataArray[j] = (double)saplesAsCArray[i];  // put data into float array
                printf("\n %f",floatDataArray[j]);
                j++;
            }
        }
    }
}




@end
