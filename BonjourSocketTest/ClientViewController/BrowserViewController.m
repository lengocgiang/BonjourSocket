//
//  BrowserViewController.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BrowserViewController.h"
#import "InfoServiceViewController.h"

#import "BonjourClient.h"

@interface BrowserViewController ()
<
    InfoServiceViewControllerDelegate,
    NSNetServiceBrowserDelegate
>
@property(strong, nonatomic, readwrite) NSNetServiceBrowser         *serviceBrowser;
@property (strong, nonatomic) NSNetService                          *netServiceSelected;

// Setup methods notification handle
- (void)handleEchoClientBrowserSuccess:(NSNotification *)notification;
- (void)handleEchoClientBrowserRemoveService:(NSNotification *)notification;
- (void)handleEchoClientBrowserStopSearch:(NSNotification *)notification;
@end

@implementation BrowserViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoClientBrowserSuccess:) name:kBonjourClientBrowserSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoClientBrowserRemoveService:) name:kBonjourClientBrowserRemoveServiceNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEchoClientBrowserStopSearch:) name:kBonjourClientBrowserStopSearchNotification object:nil];
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}
- (void)dealloc
{
    //[[BonjourClient sharedBrowser]stopBrowserSearchForServer];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //NSLog(@"servertype %@",self.serverType);
    [self.tableView reloadData];
//    if ([self.serverType isEqualToString:@"All server"])
//    {
//        NSString *serverType = @"_services._dns-sd._udp.";
//        [[BonjourClient sharedBrowser]browserForServerWithType:serverType];
//    }
//    else
//    {
//        [[BonjourClient sharedBrowser]browserForServer];
//    }
    [[BonjourClient sharedBrowser]browserForServer];
    //[[EchoClient sharedBrowser]browserForServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [[[BonjourClient sharedBrowser]availableService]count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSNetService *services;
    
    services = [[[BonjourClient sharedBrowser]availableService]objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%@.%@",services.name,services.type];
    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
//    _netServiceSelected = [[[EchoClient sharedBrowser]availableService]objectAtIndex:indexPath.row];
//    NSLog(@"1 _netServiceSelected %@",_netServiceSelected);
//    [self performSegueWithIdentifier:@"infoSegue" sender:nil];

}

#pragma mark - Utilities
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    _netServiceSelected = [[[BonjourClient sharedBrowser]availableService]objectAtIndex:indexPath.row];
    
    if ([segue.identifier isEqualToString:@"infoSegue"])
    {
        InfoServiceViewController *infoVC = segue.destinationViewController;
        infoVC.delegate = self;
        infoVC.netService = _netServiceSelected;
    }
}

#pragma mark - Handle Notification
- (void)handleEchoClientBrowserSuccess:(NSNotification *)notification
{
    NSLog(@"Did find service");
    
    [self.tableView reloadData];
}
- (void)handleEchoClientBrowserRemoveService:(NSNotification *)notification
{
    NSLog(@"remove service notification");
    [self.tableView reloadData];
}
- (void)handleEchoClientBrowserStopSearch:(NSNotification *)notification
{
    NSLog(@"Stop search");
    [self.tableView reloadData];
}

#pragma mark - InfoServiceVCDelegate
- (void)tapToDismissViewController:(InfoServiceViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
