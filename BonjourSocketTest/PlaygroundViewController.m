//
//  PlaygroundViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "PlaygroundViewController.h"

#import "BonjourServer.h"

@interface PlaygroundViewController ()
<
BonjourServerDelegate
>
@property (strong, nonatomic)BonjourServer *server;
@end

@implementation PlaygroundViewController

@synthesize server;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    server = [[BonjourServer alloc]init];
    server.delegate = self;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)serverFailed:(BonjourServer *)server reason:(NSString *)reason
{
    
}
- (void)handleNewConnection:(BonjourConnection *)connection
{
    
}
- (IBAction)startServer:(id)sender {
    [server startServer];
}
- (IBAction)stopServer:(id)sender
{
    [server stopServer];
}


@end
