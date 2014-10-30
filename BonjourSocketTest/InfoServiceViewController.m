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
    UITextFieldDelegate
>
@property (weak, nonatomic) IBOutlet UITextView *serverInfoTextView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UILabel *sentStatusLabel;

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

    
    [self.serverInfoTextView setText:[NSString stringWithFormat:@"%@ \n Address :%@ \n Port : %zd",self.netService,self.netService.addresses,self.netService.port]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sentToServer:(id)sender
{
    //[[BonjourClient sharedBrowser]outputText:self.sendTextField.text];
    [[BonjourClient sharedBrowser]openStreamToConnectNetService:self.netService];

}
- (IBAction)sendFileToServer:(id)sender
{
//    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"file.zip" ofType:nil];
//    [[BonjourClient sharedBrowser]startSendFileWithPath:filePath toNetService:self.netService];
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
#pragma mark - Text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
