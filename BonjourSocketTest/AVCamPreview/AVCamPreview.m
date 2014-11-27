//
//  AVCamPreview.m
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/25/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "AVCamPreview.h"
@import AVFoundation;

@implementation AVCamPreview

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer]session];
}

- (void)setSession:(AVCaptureSession *)session
{
    CGRect layerBounds = self.layer.bounds;
    
    ((AVPlayerLayer *)[self layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    ((AVPlayerLayer *)[self layer]).bounds = layerBounds;
    
    ((AVPlayerLayer *)[self layer]).position = CGPointMake(CGRectGetMidX(layerBounds), CGRectGetMidY(layerBounds));
    
    [(AVCaptureVideoPreviewLayer *)[self layer]setSession:session];
}


@end
