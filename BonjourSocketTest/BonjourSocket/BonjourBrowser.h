//
//  BonjourBrowser.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourBrowserDelegate <NSObject>
- (void)updateServerList;
@end
@interface BonjourBrowser : NSObject
{
    NSNetServiceBrowser             *netServiceBrowser;
    NSMutableArray                  *servers;
}
@property (assign, nonatomic)id<BonjourBrowserDelegate>delegate;
@property (strong, nonatomic, readonly)NSArray *servers;
// Start browsing for Bonjour services
- (BOOL)start;

// Stop everything
- (void)stop;

@end
