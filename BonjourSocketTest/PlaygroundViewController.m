//
//  PlaygroundViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "PlaygroundViewController.h"


#import "Util.h"
#import "UITextView+Utils.h"

@interface PlaygroundViewController ()

@property (weak, nonatomic) IBOutlet UITextView *chatView;
@property (weak, nonatomic) IBOutlet UITextField *input;
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
    NSURL *url = [[NSBundle mainBundle]URLForResource:@"music.mp3" withExtension:nil];
    [chanel broadcastData:[NSData dataWithContentsOfURL:url] fromUser:[[Util sharedInstance]name]];
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

@end
