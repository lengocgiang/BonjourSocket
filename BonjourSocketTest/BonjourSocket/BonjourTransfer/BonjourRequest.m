//
//  EchoRequest.m
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/23/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "BonjourRequest.h"

@implementation BonjourRequest
#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:kTitle];
    [aCoder encodeObject:self.message forKey:kMessage];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    self.title = [aDecoder decodeObjectForKey:kTitle];
    self.message = [aDecoder decodeObjectForKey:kMessage];
    
    return self;
}

@end
