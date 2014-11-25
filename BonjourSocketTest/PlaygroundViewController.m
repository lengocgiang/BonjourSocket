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


@interface PlaygroundViewController ()
<
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate
>
@property (weak, nonatomic) IBOutlet UIButton       *playBtn;
@property (weak, nonatomic) IBOutlet UITextView     *chatView;
@property (weak, nonatomic) IBOutlet UITextField    *input;
@property (weak, nonatomic) IBOutlet UIImageView    *frameView;

// AVAsset


@property AVAssetReader                                 *assetReader;
@property (strong, nonatomic)VideoFrameExtractor        *video;
@property float lastFrameTime;
@property (strong, nonatomic)UIImagePickerController    *picker;
@property (strong, nonatomic)CADisplayLink              *displayLink;

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
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayNextFrame:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.frameInterval = 2;
    [self.displayLink setPaused:YES];
    
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
- (IBAction)playAction:(UIButton *)sender
{
    self.lastFrameTime = -1;

    // seek to 0.0 second
    [self.video seekTime:0.0];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0/30 target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil repeats:YES];
//    BOOL isPause = self.displayLink.isPaused;
//    if (isPause) {
//        [self.displayLink setPaused:NO];
//        [sender setTitle:@"Pause" forState:UIControlStateNormal];
//    }
//    else
//    {
//        [self.displayLink setPaused:YES];
//        [sender setTitle:@"Play" forState:UIControlStateNormal];
//    }
}

#pragma mark - ImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    //AVAsset *asset = [AVAsset assetWithURL:info[UIImagePickerControllerMediaURL]];
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
