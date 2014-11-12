//
//  ViewController.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "ServerViewController.h"
#import "RootViewController.h"
#import "BrowserViewController.h"

#import "BonjourServer.h"
#import "BonjourConnection.h"

@interface ServerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startServerBtn;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;


- (void)handleEchoServerOpenConnectionNotification:(NSNotification *)notification;
- (void)handleEchoServerCloseConnectionNotification:(NSNotification *)notification;
@end

@implementation ServerViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoServerOpenConnectionNotification:) name:EchoConnectionDidOpenNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoServerCloseConnectionNotification:) name:EchoConnectionDidCloseNotification object:nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.startServerBtn setTitle:@"Start Server" forState:UIControlStateNormal];
    [self.startServerBtn setTitle:@"Stop Server" forState:UIControlStateSelected];
    
//    UIBarButtonItem *rootBack = [[UIBarButtonItem alloc]initWithTitle:@"Exit" style:UIBarButtonItemStylePlain target:self action:@selector(exitServerView)];
//    self.navigationItem.leftBarButtonItem = rootBack;
    
}
- (void)dealloc
{
    [[BonjourServer sharedPublisher]stopServer];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startServerAction:(id)sender
{
    if (!self.startServerBtn.selected) {
        [self.startServerBtn setSelected:TRUE];
        if ([[BonjourServer sharedPublisher]startServer])
        {
            NSString *logString = [NSString stringWithFormat:@"Start server on port %zu",(size_t)[[BonjourServer sharedPublisher] port]];
            [self.logTextView setText:logString];
            
        }
        else
        {
            [self.logTextView setText:@"Error starting server"];
            
        }
    }
    else
    {
        [self.startServerBtn setSelected:FALSE];
        [[BonjourServer sharedPublisher]stopServer];
    }
    
}


#pragma mark - Handle Request Notification
- (void)handleEchoServerOpenConnectionNotification:(NSNotification *)notification
{
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\n Open connection"];
}
- (void)handleEchoServerCloseConnectionNotification:(NSNotification *)notification
{
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\n Close connection"];
}

- (IBAction)exitServerView:(id)sender
{
        [self.delegate dismissServerViewController:self];
}
         


@end
