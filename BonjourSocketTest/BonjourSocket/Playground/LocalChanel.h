//
//  LocalChanel.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chanel.h"
#import "BonjourServer.h"
#import "BonjourConnection.h"

@interface LocalChanel : Chanel
<
    BonjourConnectionDelegate,
    BonjourServerDelegate
>

@property (strong, nonatomic,readonly) BonjourServer         *server;
@property (strong, nonatomic,readonly) NSMutableSet          *clients;

- (id)init;

@end
