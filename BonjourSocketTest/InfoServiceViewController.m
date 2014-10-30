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

@interface InfoServiceViewController ()
<
    UIGestureRecognizerDelegate,
    UITextFieldDelegate
>
@property (weak, nonatomic) IBOutlet UITextView *serverInfoTextView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UILabel *sentStatusLabel;
@property (weak, nonatomic) IBOutlet UIView *sendView;

- (void)echoClientOpenStreamSuccess:(NSNotification *)notification;
- (void)bonjourClientStartSendingData:(NSNotification *)notification;
@end

@implementation InfoServiceViewController
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
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(bonjourClientStartSendingData:) name:kBonjourClientStartSendDataNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sendTextField.delegate = self;
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
//    [[[UIAlertView alloc]initWithTitle:@"Stream" message:@"added connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
    NSLog(@"Accept connection from server");
}
- (void)bonjourClientStartSendingData:(NSNotification *)notification
{
    self.sentStatusLabel.text = @"Start sending data";
}
#pragma mark - Hanle TapGestureRecoginzer
- (IBAction)tapToSend:(UITapGestureRecognizer *)sender
{
    UIImageView *v = (UIImageView *)[sender view];
    switch (v.tag)
    {
        case 1001:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test1"];
            break;
        case 1002:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test2"];
            break;
        case 1003:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test3"];
            break;
        case 1004:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test4"];
            break;
        case 1005:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test5"];
            break;
        case 1006:
            //NSLog(@"%f",sender.view.frame.size.width);
            [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService withName:@"test6"];
            break;
            
        default:
            break;
    }
}



#pragma mark - Text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}
#pragma mark -
- (IBAction)tapToExit:(id)sender
{
    [self.delegate tapToDismissViewController:self];
}

@end
