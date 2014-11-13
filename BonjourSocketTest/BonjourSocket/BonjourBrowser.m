//
//  BonjourBrowser.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourBrowser.h"

// A category on NSNetService that's used to sort NSNetService objects by their name
@interface NSNetService(BrowserViewControllerAdditions)
- (NSComparisonResult)localizedCaseInsensitiveCompareByName:(NSNetService *)aNetService;
@end
@implementation NSNetService(BrowserViewControllerAdditions)

- (NSComparisonResult)localizedCaseInsensitiveCompareByName:(NSNetService *)aNetService
{
    return [[self name]localizedCaseInsensitiveCompare:[aNetService name]];
}
@end

@interface BonjourBrowser()
<
    NSNetServiceBrowserDelegate
>
- (void)sortServers;
@end

@implementation BonjourBrowser
@synthesize servers;
@synthesize delegate;

// Initialize
- (id)init
{
    servers = [[NSMutableArray alloc]init];
    return self;
}

// Cleanup
- (void)dealloc
{
    if (servers != nil)
    {
        servers = nil;
    }
    self.delegate = nil;
    
}

// Start browsing for servers
- (BOOL)start
{
    // Restarting?
    if (netServiceBrowser != nil) {
        [self stop];
    }
    netServiceBrowser = [[NSNetServiceBrowser alloc]init];
    if (!netServiceBrowser) {
        return NO;
    }
    netServiceBrowser.delegate = self;
    [netServiceBrowser searchForServicesOfType:@"_gBonjourSocket._tcp." inDomain:@""];
    
    return YES;
}
// Terminate currnet service browser and clean up
- (void)stop
{
    if (netServiceBrowser == nil) {
        return;
    }
    [netServiceBrowser stop];
    netServiceBrowser = nil;
    [servers removeAllObjects];
}
- (void)sortServers
{
    [servers sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
}

#pragma mark -
#pragma mark NSNetServiceBrowser Delegate methods
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if (![servers containsObject:aNetService]) {
        [servers addObject:aNetService];
    }
    if (moreComing) {
        return;
    }
    NSLog(@"Did find service");
    [self sortServers];
    [delegate updateServerList];
}

// Service was removed
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    // Remove from list
    [servers removeObject:aNetService];
    if (moreComing) {
        return;
    }
    [self sortServers];
    [delegate updateServerList];
}

@end
