//
//  BrowserViewController.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BrowserViewController.h"
#import "PlaygroundViewController.h"

#import "BonjourServer.h"
#import "BonjourBrowser.h"

#import "LocalChanel.h"
#import "RemoteChanel.h"
@interface BrowserViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    BonjourBrowserDelegate,
    PlaygroundViewControllerDelegate

>
@property (weak, nonatomic) IBOutlet UITableView *serverList;
@property (strong, nonatomic)BonjourBrowser *serverBrowser;

@end

@implementation BrowserViewController
@synthesize serverBrowser;
@synthesize serverList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
}
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"call me!!!");
    serverBrowser = [[BonjourBrowser alloc]init];
    serverBrowser.delegate = self;
    [serverBrowser start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - IBAction
- (IBAction)createServer:(id)sender
{
    //[serverBrowser stop];
}
- (IBAction)joinServer:(id)sender
{
    NSIndexPath *indexPath = [serverList indexPathForSelectedRow];
    if (indexPath == nil)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:@"Please select which chat room you want to join from the list above"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    NSNetService *netServiceSelected = [serverBrowser.servers objectAtIndex:indexPath.row];
    RemoteChanel *chanel = [[RemoteChanel alloc]initWithNetService:netServiceSelected];
    [serverBrowser stop];
    
    PlaygroundViewController *playVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PlaygroundViewController"];
    playVC.chanel = chanel;
    playVC.delegate = self;
    [playVC active];
    [self presentViewController:playVC animated:NO completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [serverBrowser.servers count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"serverListIdentifier";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSNetService *netService = [serverBrowser.servers objectAtIndex:indexPath.row];
    [cell.textLabel setText:netService.name];
    
    return cell;
}

#pragma mark - BonjourBrowserDelegate
- (void)updateServerList
{
    [serverList reloadData];
}
#pragma mark - PlayVCDelegate
- (void)dismissPlayViewController:(PlaygroundViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"playgroundModal"])
    {
        [serverBrowser stop];
        PlaygroundViewController *playVC = segue.destinationViewController;
        playVC.delegate = self;
        LocalChanel *chanel = [[LocalChanel alloc]init];
        playVC.chanel = chanel;
        [playVC active];
    }

}

@end
