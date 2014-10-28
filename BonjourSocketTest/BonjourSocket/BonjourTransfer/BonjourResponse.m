//
//  EchoResponse.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/23/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourResponse.h"

@implementation BonjourResponse

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:self.response forKey:kResponse];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    self.response = [aDecoder decodeBoolForKey:kResponse];
    return self;
}

@end
