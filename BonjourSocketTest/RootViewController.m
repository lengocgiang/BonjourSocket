//
//  RootViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/6/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "RootViewController.h"
#import "BrowserViewController.h"
#import "Util.h"
@interface RootViewController ()
<
    UITextFieldDelegate
>
@property (weak, nonatomic) IBOutlet UITextField *nameTxtField;

@end

@implementation RootViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nameTxtField.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    [[Util sharedInstance] setName:self.nameTxtField.text];
    BrowserViewController *browserVC = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
    [self presentViewController:browserVC animated:YES completion:nil];
    
    return NO;
}
- (void)dealloc
{
    NSLog(@"dealoc BrowserVC");
}
@end
