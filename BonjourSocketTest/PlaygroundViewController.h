//
//  PlaygroundViewController.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Chanel.h"

@class PlaygroundViewController;

@protocol PlaygroundViewControllerDelegate <NSObject>
- (void)dismissPlayViewController:(PlaygroundViewController *)controller;
@end
@interface PlaygroundViewController : UIViewController
<
    UITextFieldDelegate,
    ChanelDelegate
>
@property (strong, nonatomic) Chanel *chanel;
@property (assign, nonatomic) id<PlaygroundViewControllerDelegate>delegate;
- (void)active;

@end
