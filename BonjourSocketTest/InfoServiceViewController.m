//
//  DetailViewController.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "InfoServiceViewController.h"
#import "BonjourClient.h"
#import "BonjourServer.h"
#import "BonjourConnection.h"

#import "GGAudioPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface InfoServiceViewController ()
<
    MPMediaPickerControllerDelegate,
    UIGestureRecognizerDelegate,
    UITextFieldDelegate
>
@property (weak, nonatomic) IBOutlet UITextView *serverInfoTextView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UILabel *sentStatusLabel;
@property (weak, nonatomic) IBOutlet UIView *sendView;

// Audio Player
@property NSTimer   *timer;
@property BOOL      isPaused;
@property BOOL      scrubbing;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) GGAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeDurationLabel;
@property (weak, nonatomic) IBOutlet UISlider *currentTimeSlider;

- (void)echoClientOpenStreamSuccess:(NSNotification *)notification;
- (void)bonjourClientStartSendingData:(NSNotification *)notification;
@end

@implementation InfoServiceViewController
{
    AVAssetReader *assetReader;
    AVAssetReaderTrackOutput *assetOutput;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setupNotification];
    }
    return self;
}

- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(echoClientOpenStreamSuccess:) name:kEchoClientOpenStreamSuccess object:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sendTextField.delegate = self;

    [self setupImageTapGesture];
    self.audioPlayer = [[GGAudioPlayer alloc]init];
    [self setupAudioPlayer:@"music"];

}
- (void)setupImageTapGesture
{
    for(UIImageView *imgV in self.sendView.subviews)
    {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToSend:)];
        tapGesture.numberOfTapsRequired =1;
        tapGesture.delegate = self;
        imgV.userInteractionEnabled = YES;
        [imgV addGestureRecognizer:tapGesture];
    }
    
}

- (void)dealloc
{
    [[BonjourClient sharedBrowser]closeStreams];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sentToServer:(id)sender
{

    [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService];

}

#pragma mark - Handle Notification
- (void)echoClientOpenStreamSuccess:(NSNotification *)notification
{
    NSLog(@"Accept connection from server");
}
- (void)bonjourClientStartSendingData:(NSNotification *)notification
{
    self.sentStatusLabel.text = @"Start sending data";
}

#pragma mark - Handle TapGestureRecoginzer
- (IBAction)tapToSend:(UITapGestureRecognizer *)sender
{
    
    UIImageView *v = (UIImageView *)[sender view];
    switch (v.tag)
    {
        case 1001:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test1.png" ofType:nil]];
            break;
        case 1002:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test2.png" ofType:nil]];
            break;
        case 1003:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test3.png" ofType:nil]];
            break;
        case 1004:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test4.png" ofType:nil]];
            break;
        case 1005:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test5.png" ofType:nil]];
            break;
        case 1006:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:[[NSBundle mainBundle]pathForResource:@"test6.png" ofType:nil]];
            break;
            
        default:
            break;
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}
#pragma mark - IBAction
- (IBAction)tapToExit:(id)sender
{
    [self.delegate tapToDismissViewController:self];
}
- (IBAction)pickMusic:(id)sender
{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"music.mp3" ofType:nil];
    [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withFilePath:path];
    //[[GGAudioPlayer sharedInstance]convertFloatDataFromAudioFileWithPath:path];

}
#pragma mark - MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    MPMediaItem * mediaItem = [[mediaItemCollection items]objectAtIndex:0];
    
    NSURL *musicSourceURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    
    NSLog(@"music url %@",musicSourceURL);

    
}
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AudioPlayer
- (void)setupAudioPlayer:(NSString *)fileName
{
    // insert filename & fileextension
    NSString *fileExtension = @"mp3";
    
    [self.audioPlayer initWithAudioFile:fileName withFileExtension:fileExtension];
    
    self.currentTimeSlider.maximumValue = [self.audioPlayer getAudioDuration];
    
    self.timeElapsedLabel.text = @"0:00";
    self.timeDurationLabel.text = [NSString stringWithFormat:@"-%@",[self.audioPlayer timeFormat:[self.audioPlayer getAudioDuration]]];
    
}
- (void)updateTimer:(NSTimer *)timer
{
    if (!self.scrubbing)
    {
        self.currentTimeSlider.value = [self.audioPlayer getCurrentAudioTime];
    }
    self.timeElapsedLabel.text = [NSString stringWithFormat:@"%@",[self.audioPlayer timeFormat:[self.audioPlayer getCurrentAudioTime]]];
    self.timeDurationLabel.text = [NSString stringWithFormat:@"-%@",
                                   [self.audioPlayer timeFormat:[self.audioPlayer getAudioDuration] - [self.audioPlayer getCurrentAudioTime]]];
}
#pragma mark -
- (IBAction)userIsScrubbing:(id)sender
{
    self.scrubbing = true;
}
- (IBAction)setCurrentTime:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateTimer:) userInfo:nil repeats:NO];
    [self.audioPlayer setCurrentAudioTime:self.currentTimeSlider.value];
    self.scrubbing = false;
}
- (IBAction)playAudioPressed:(id)sender
{
    [self.timer invalidate];
    // play audio for the first time or if pause was pressed
    if (!self.isPaused)
    {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"audioplayer_pause.png"] forState:UIControlStateNormal];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
        [self.audioPlayer playAudio];
        self.isPaused = true;
    }
    else
    {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"audioplayer_play.png"] forState:UIControlStateNormal];
        [self.audioPlayer pauseAudio];
        self.isPaused = false;
    }
}



@end
