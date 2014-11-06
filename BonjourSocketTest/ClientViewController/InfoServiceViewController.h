//
//  DetailViewController.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InfoServiceViewController;

@protocol InfoServiceViewControllerDelegate <NSObject>

- (void)tapToDismissViewController:(InfoServiceViewController *)controller;

@end

@interface InfoServiceViewController : UIViewController
@property (assign, nonatomic) id<InfoServiceViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNetService          *netService;

@end
