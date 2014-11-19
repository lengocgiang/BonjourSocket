//
//  PlaygroundViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "PlaygroundViewController.h"
@import AVFoundation;
@import CoreMedia;
@import VideoToolbox;
@import QuartzCore;
@import MobileCoreServices;

#import "Util.h"
#import "UITextView+Utils.h"
#import "AAPLEAGLLayer.h"

@interface BonjourImagePickerController : UIImagePickerController

@end

@implementation BonjourImagePickerController

@end

@interface PlaygroundViewController ()
<
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate
>
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UITextView     *chatView;
@property (weak, nonatomic) IBOutlet UITextField    *input;
@property (weak, nonatomic) IBOutlet UIImageView    *frameView;

// AVAsset
@property UIPopoverController           *popover;
@property dispatch_queue_t              backgroundQueue;
@property dispatch_semaphore_t          bufferSemaphore;
@property AVAssetReader                 *assetReader;
@property CGAffineTransform             videoPreferredTransform;
@property VTDecompressionSessionRef     decompressionSession;
@property NSMutableArray                *presentationTimes;
@property NSMutableArray                *outputFrames;
@property CFTimeInterval                lastCallbackTime;
@property (strong, nonatomic)CADisplayLink                 *displayLink;
@property (strong, nonatomic)UIImagePickerController *picker;

@end

@implementation PlaygroundViewController
@synthesize chanel;
@synthesize input;
@synthesize chatView;


//@synthesize server;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //server = [[BonjourServer alloc]init];
    //server.delegate = self;
    input.delegate = self;
    
    self.backgroundQueue = dispatch_queue_create("com.giangln.backgroundQueue", NULL);
    self.outputFrames = [[NSMutableArray alloc] init];
    self.presentationTimes = [[NSMutableArray alloc] init];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.displayLink setPaused:YES];
    self.lastCallbackTime = 0.0;
    self.bufferSemaphore = dispatch_semaphore_create(0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
- (IBAction)exitAction:(id)sender
{
    [chanel stop];
    [self.delegate dismissPlayViewController:self];
}

- (void)active
{
    if (chanel != nil) {
        chanel.delegate = self;
        [chanel start];
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == input) {
            [chanel broadcastChatMessage:input.text fromUser:[[Util sharedInstance]name]];
        [input setText:@""];
        
        [input resignFirstResponder];
    }
    return NO;

}
- (IBAction)dataSendingAction:(id)sender
{
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc]init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    
    [self presentViewController:videoPicker animated:YES completion:nil];
    
}
- (IBAction)playAction:(id)sender
{
    BOOL isPlaying = self.displayLink.isPaused;
    
    if (isPlaying == NO) {
        [self.displayLink setPaused:YES];
        [sender setTitle:@"Play"];
    } else{
        [self.displayLink setPaused:NO];
        [sender setTitle:@"Pause"];
        
    }

}

#pragma mark - ImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.displayLink setPaused:YES];
    self.lastCallbackTime = 0.0;
    [self.popover dismissPopoverAnimated:YES];
    [self.outputFrames removeAllObjects];
    [self.presentationTimes removeAllObjects];
    AVAsset *asset = [AVAsset assetWithURL:info[UIImagePickerControllerMediaURL]];
    if (self.assetReader.status == AVAssetReaderStatusReading) {
        dispatch_semaphore_signal(self.bufferSemaphore);
        [self.assetReader cancelReading];
    }
    dispatch_async(self.backgroundQueue, ^{
        [self readSampleBuffersFromAsset:asset];
    });
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    picker.delegate = nil;

}
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover.delegate = nil;
}
- (void)displayChatMessage:(NSString *)message fromUser:(NSString *)userName
{
    [chatView appendTextAfterLinebreak:[NSString stringWithFormat:@"%@: %@", userName, message]];
    [chatView scrollToBottom];
}

- (void)chanelTerminated:(id)chanel reason:(NSString *)string
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Chanel terminated"
                                                    message:string
                                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [self exitAction:nil];
}

- (void)displayImageFromView:(NSData *)_image withFPS:(NSNumber *)framePerSecond fromUser:(NSString *)userName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.frameView.image = [UIImage imageWithData:_image];
    });
}

#pragma mark - CMSampleBuffer
- (void)readSampleBuffersFromAsset:(AVAsset *)asset{
    NSError *error = nil;
    self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    if (error) {
        NSLog(@"Error creating Asset Reader: %@", [error description]);
    }
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    __block AVAssetTrack *videoTrack = (AVAssetTrack *)[videoTracks firstObject];
    [self createDecompressionSessionFromAssetTrack:videoTrack];
    AVAssetReaderTrackOutput *videoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:nil];
    
    if ([self.assetReader canAddOutput:videoTrackOutput]) {
        [self.assetReader addOutput:videoTrackOutput];
    }
    
    BOOL didStart = [self.assetReader startReading];
    if (!didStart) {
        goto bail;
    }
    
    while (self.assetReader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef sampleBuffer = [videoTrackOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
            VTDecodeInfoFlags flagOut;
            VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, flags, NULL, &flagOut);
            
            CFRelease(sampleBuffer);
            if ([self.presentationTimes count] >= 5) {
                dispatch_semaphore_wait(self.bufferSemaphore, DISPATCH_TIME_FOREVER);
            }
        }
        else if (self.assetReader.status == AVAssetReaderStatusFailed){
            NSLog(@"Asset Reader failed with error: %@", [[self.assetReader error] description]);
        } else if (self.assetReader.status == AVAssetReaderStatusCompleted){
            NSLog(@"Reached the end of the video.");
        }
    }
    
bail:
    ;
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    /*
     The callback gets called once every Vsync.
     Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, get the imagebuffer from our queue and render it on screen at the right time
     */
    
    // if we haven't had a callback yet, we can set the last call back time to the CADisplayLink time
    if (self.lastCallbackTime == 0.0f) {
        self.lastCallbackTime = [sender timestamp];
    }
    CFTimeInterval timeSinceLastCallback = [sender timestamp] - self.lastCallbackTime;
    
    if ([self.outputFrames count] && [self.presentationTimes count]) {
        
        CVImageBufferRef imageBuffer = NULL;
        NSNumber *framePTS = nil;
        id imageBufferObject = nil;
        @synchronized(self){
            
            framePTS = [self.presentationTimes firstObject];
            imageBufferObject = [self.outputFrames firstObject];
            
            imageBuffer = (__bridge CVImageBufferRef)imageBufferObject;
        }
        //check if the current time is greater than or equal to the presentation time of the sample buffer
        if (timeSinceLastCallback >= [framePTS floatValue] ) {
            
            //draw the imagebuffer, move the time line, and update the queues
            @synchronized(self){
                if (imageBufferObject) {
                    [self.outputFrames removeObjectAtIndex:0];
                }
                
                if (framePTS) {
                    [self.presentationTimes removeObjectAtIndex:0];
                    
                    if ([self.presentationTimes count] == 3) {
                        dispatch_semaphore_signal(self.bufferSemaphore);
                    }
                }
                
            }
            
        }
        
        if (imageBuffer) {
            NSLog(@"done");
            CIImage *ciimage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            UIImage *img = [self cgImageBackedImageWithCIImage:ciimage];
            
            NSData *imgData = UIImageJPEGRepresentation(img, 0.2);
            NSDictionary *dict = @{@"image":imgData,
                                   @"framePerSecond":framePTS};
            

            [chanel broadcastDict:dict fromUser:[[Util sharedInstance]name]];
            
        }
    }
    else
    {
        NSLog(@"end");
        if (!self.displayLink.isPaused)
        {
            [self.displayLink setPaused:YES];
        }
    }

}
- (void)showme:(NSData *)data
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.frameView.image = [UIImage imageWithData:data];
    });
}

- (UIImage*) cgImageBackedImageWithCIImage:(CIImage*) ciImage
{

    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef ref = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage* image = [UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationRight];
    
    CGImageRelease(ref);
    
    return image;

}

- (void)createDecompressionSessionFromAssetTrack:(AVAssetTrack *)track{
    NSArray *formatDescriptions = [track formatDescriptions];
    CMVideoFormatDescriptionRef formatDescription = (__bridge CMVideoFormatDescriptionRef)[formatDescriptions firstObject];
    
    self.videoPreferredTransform = track.preferredTransform;
    _decompressionSession = NULL;
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
    VTDecompressionSessionCreate(kCFAllocatorDefault, formatDescription, NULL, NULL, &callBackRecord, &_decompressionSession);
}

#pragma mark - VideoToolBox Decompress Frame CallBack
/*
 This callback gets called everytime the decompresssion session decodes a frame
 */
void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    if (status == noErr) {
        if (imageBuffer != NULL) {
            __weak __block PlaygroundViewController *weakSelf = (__bridge PlaygroundViewController *)decompressionOutputRefCon;
            NSNumber *framePTS = nil;
            if (CMTIME_IS_VALID(presentationTimeStamp)) {
                framePTS = [NSNumber numberWithDouble:CMTimeGetSeconds(presentationTimeStamp)];
            } else{
                NSLog(@"Not a valid time for image buffer: %@", imageBuffer);
            }
            
            if (framePTS) { //find the correct position for this frame in the output frames array
                @synchronized(weakSelf){
                    id imageBufferObject = (__bridge id)imageBuffer;
                    BOOL shouldStop = NO;
                    NSInteger insertionIndex = [weakSelf.presentationTimes count] -1;
                    while (insertionIndex >= 0 && shouldStop == NO) {
                        NSNumber *aNumber = weakSelf.presentationTimes[insertionIndex];
                        if ([aNumber floatValue] <= [framePTS floatValue]) {
                            shouldStop = YES;
                            break;
                        }
                        insertionIndex--;
                    }
                    if (insertionIndex + 1 == [weakSelf.presentationTimes count]) {
                        [weakSelf.presentationTimes addObject:framePTS];
                        [weakSelf.outputFrames addObject:imageBufferObject];
                    } else{
                        [weakSelf.presentationTimes insertObject:framePTS atIndex:insertionIndex + 1];
                        [weakSelf.outputFrames insertObject:imageBufferObject atIndex:insertionIndex + 1];
                    }
                    
                }
                
                
            }
        }
    } else {
        NSLog(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u", (float)presentationTimeStamp.value/presentationTimeStamp.timescale, (int)status, (unsigned int)infoFlags);
    }
}
- (void)dealloc{
    CFRelease(_decompressionSession);
}
     

@end
