//
//  PlaygroundViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//  in videochat

#import "PlaygroundViewController.h"
@import AVFoundation;
@import CoreMedia;
@import VideoToolbox;
@import QuartzCore;
@import MobileCoreServices;

#import "Util.h"
#import "UITextView+Utils.h"
#import "VideoFrameExtractor.h"
#import "AVCamPreview.h"

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;


@interface PlaygroundViewController ()
<
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
>
@property (weak, nonatomic) IBOutlet UIButton       *playBtn;
@property (weak, nonatomic) IBOutlet UITextView     *chatView;
@property (weak, nonatomic) IBOutlet UITextField    *input;
@property (weak, nonatomic) IBOutlet UIImageView    *frameView;
@property (weak, nonatomic) IBOutlet AVCamPreview *previewView;

// AVAsset
@property AVAssetReader                                 *assetReader;
@property (strong, nonatomic)VideoFrameExtractor        *video;
@property float lastFrameTime;
@property (strong, nonatomic)UIImagePickerController    *picker;
@property (strong, nonatomic)CADisplayLink              *displayLink;

// AVCaptureSession
@property (strong, nonatomic) dispatch_queue_t          sessionQueue;
@property (strong, nonatomic) AVCaptureSession          *session;
@property (nonatomic) AVCaptureStillImageOutput         *stillImageOutput;
@property (nonatomic) AVCaptureDeviceInput              *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput          *videoDataOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer        *videoPreviewLayer;
// Ultilities
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) id runtimeErrorHandlingObserver;

@end

@implementation PlaygroundViewController
@synthesize chanel;
@synthesize input;
@synthesize chatView;


//@synthesize server;
- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session]isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running",@"deviceAuthorized",nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self avCaptureSessionSetUp];
    
    [self.session startRunning];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        
        [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput]device]];
        
        
        __weak PlaygroundViewController *weakSelf = self;
        
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter]addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
            
            PlaygroundViewController *strongSelf = weakSelf;
            
            dispatch_async([strongSelf sessionQueue], ^{
                // Manual restaring the session since it must have been stopped due to an error
                [[strongSelf session] startRunning];
                
            });
            
        }]];
        [[self session] startRunning];
        
    });

}
- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        
        [[self session]stopRunning];
        
        // remove NSNotificatonCenter
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput]device]];
        
        [[NSNotificationCenter defaultCenter]removeObserver:[self runtimeErrorHandlingObserver]];

        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
        
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}
- (void)avCaptureSessionSetUp
{
    // Create the AVCaptureSession
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    
    [[self session] setSessionPreset:AVCaptureSessionPresetLow];
    
    [self setSession:session];
    
    // Setup the preview view
    [[self previewView] setSession:session];
    
    // Check for device authorized
    [self checkDeviceAuthorizationStatus];
    
    // Dispatch session setup to the sessionQueue so that the main queue isn't blocked
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [PlaygroundViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error)
        {
            NSLog(@"AVCaptureDeviceInput error %@,%@",error,[error localizedDescription]);
        }
        
        if ([session canAddInput:videoDeviceInput])
        {
            [session addInput:videoDeviceInput];
            
            [self setVideoDeviceInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[(AVCaptureVideoPreviewLayer *)[[self previewView]layer]connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }
        
        
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
       
        if ([session canAddOutput:videoDataOutput])
        {
            [session addOutput:videoDataOutput];
            
            videoDataOutput.videoSettings =
            [NSDictionary dictionaryWithObject:
             [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                        forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            
            [self setVideoDataOutput:videoDataOutput];
            
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
           
            
        }

    
    });
    
}
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        
        AVCaptureDevice *device = [[self videoDeviceInput]device];
        
        NSError *error = nil;
        
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
#ifdef DEBUG
            NSLog(@"forcusWithMode error %@,%@",error,[error localizedDescription]);
#endif
        }
        
    });
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    @autoreleasepool {
        if ([self.playBtn isSelected])
        {
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.2);//max compression = 0, min compression:1.0
            NSLog(@"length %f",(float)imageData.length/1024);
            // maybe not always the correct input?  just using this to send current FPS...
            NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
            
            NSDictionary* dict = @{
                                   @"image": imageData,
                                   @"timestamp" : timestamp
                                   };

            [chanel broadcastDict:dict fromUser:[[Util sharedInstance]name]];
        }

        
    }
}
//! Returns an image object from the buffer received from camera
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    //@autoreleasepool {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image= [UIImage imageWithCGImage:quartzImage
                                        scale:1.0 orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
    //}
}

+ (void)setFlashMode:(AVCaptureFlashMode)flasMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flasMode])
    {
        NSError *error = nil;
        
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flasMode];
            [device unlockForConfiguration];
        }
        else
        {
#ifdef DEBUG
            NSLog(@"FlashMode error %@,%@",error,[error localizedDescription]);
#endif
        }
    }
}

- (void) setFrameRate:(NSInteger) framerate onDevice:(AVCaptureDevice*) videoDevice {
    
    if ([videoDevice lockForConfiguration:nil]) {
        videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1,(int32_t)framerate);
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1,(int32_t)framerate);
        [videoDevice unlockForConfiguration];
    }
}
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}
- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        
        if (granted)
        {
            [self setDeviceAuthorized:YES];
        }
        else
        {
            // not granted access to media type
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc]initWithTitle:@"AVCaptureDevice"
                                           message:@"AVCaptureDevice doesn't have permission to use Camera, please change privacy settings" delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil]show];
            });
        }
    }];
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
- (IBAction)playAction:(UIButton *)sender
{
    self.playBtn.selected = !self.playBtn.selected;


}

#pragma mark - ImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.video = [[VideoFrameExtractor alloc]initWithVideo:[info[UIImagePickerControllerMediaURL] absoluteString]];
    // print some info about the video
    NSLog(@"video duration: %f",self.video.duration);
    NSLog(@"video size: %d x %d", self.video.sourceWidth, self.video.sourceHeight);
    [self.frameView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    picker.delegate = nil;

}

#pragma mark - ChanelDelegate
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

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)
- (void)displayNextFrame:(NSTimer *)timer
{
    
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    if (![self.video stepFrame]) {
        [self.displayLink setPaused:YES];
        [timer invalidate];
        return;
    }
    float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
    
    NSData *data = UIImageJPEGRepresentation(self.video.currentImage, 0.2);

    NSDictionary *dict = @{@"image":data,
                           @"framePerSecond":[NSNumber numberWithFloat:frameTime]};

    [chanel broadcastDict:dict fromUser:[[Util sharedInstance]name]];
    
}
     

@end
