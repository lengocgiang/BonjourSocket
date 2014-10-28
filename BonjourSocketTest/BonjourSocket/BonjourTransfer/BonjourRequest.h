//
//  EchoRequest.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/23/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kTitle          @"title"
#define kMessage        @"message"
@interface BonjourRequest : NSObject<NSCoding>

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *message;



@end
