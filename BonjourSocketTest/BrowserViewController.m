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

@interface BrowserViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    BonjourBrowserDelegate
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

#pragma mark Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"playgroundSegue"])
    {
        [serverBrowser stop];
        LocalChanel *chanel = [[LocalChanel alloc]init];
        
        
    }

}

@end
