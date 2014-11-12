//
//  RootViewController.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 10/27/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ServerViewController;

@protocol ServerViewControllerDelegate <NSObject>

- (void)dismissServerViewController:(ServerViewController*)controller;
@end

@interface ServerViewController : UIViewController
@property (assign, nonatomic)id<ServerViewControllerDelegate>delegate;
@end
