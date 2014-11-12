//
//  RootViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/6/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "RootViewController.h"
#import "ServerViewController.h"
@interface RootViewController ()
<
ServerViewControllerDelegate
>

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation

*/
- (void)dismissServerViewController:(ServerViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"serverModal"])
    {
        ServerViewController *serverVC = segue.destinationViewController;
        serverVC.delegate = self;
    }
}

@end
