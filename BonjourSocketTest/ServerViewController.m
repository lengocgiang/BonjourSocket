//
//  ViewController.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "ServerViewController.h"
#import "BrowserViewController.h"

#import "BonjourServer.h"
#import "BonjourConnection.h"

@interface ServerViewController ()
<
    UIPickerViewDataSource,
    UIPickerViewDelegate
>
@property (weak, nonatomic) IBOutlet UIButton *startServerBtn;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIPickerView *serverPicker;

@property (strong, nonatomic) NSArray *pickerData;

- (void)handleRequestNotification:(NSNotification *)notification;
- (void)handleEchoServerAddConnectionNotification:(NSNotification *)notification;

@end

@implementation ServerViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleRequestNotification:) name:EchoConnectionDidRequestedNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoServerAddConnectionNotification:) name:EchoConnectionDidCloseNotification object:nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Initialize Picker Data
    _pickerData = @[@"_ggServer",@"All server"];
    self.serverPicker.dataSource = self;
    self.serverPicker.delegate = self;
    
    [self.startServerBtn setTitle:@"Start Server" forState:UIControlStateNormal];
    [self.startServerBtn setTitle:@"Stop Server" forState:UIControlStateSelected];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"browserSegue"])
    {
        NSInteger row;
        row = [self.serverPicker selectedRowInComponent:0];
        
        BrowserViewController *browserVC = segue.destinationViewController;
        browserVC.serverType = [_pickerData objectAtIndex:row];
    }
}

#pragma mark - UIPicker Data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_pickerData count];
}
// The data to return for the row and component (colum) that's being passed it
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _pickerData[row];
}

#pragma mark - Handle Request Notification
- (void)handleEchoServerAddConnectionNotification:(NSNotification *)notification
{
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\n Add connection"];
}
- (void)handleRequestNotification:(NSNotification *)notification
{
//    NSString *title = [NSString stringWithFormat:@"From %@",[UIDevice currentDevice].name];
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title
//                                                   message:@"Chơi không em??"
//                                                  delegate:nil
//                                         cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
    
}

@end
