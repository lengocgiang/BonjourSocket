//
//  AVCamPreview.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/25/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface AVCamPreview : UIView
{
    CGPoint offset;
}

@property (nonatomic) AVCaptureSession *session;


@end
