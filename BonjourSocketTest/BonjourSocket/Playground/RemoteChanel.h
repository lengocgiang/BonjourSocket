//
//  RemoteChanel.h
//  BonjourSocketTest
//
//  Created by Le Ngoc Giang on 11/13/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//

#import "Chanel.h"
#import "BonjourConnection.h"
@interface RemoteChanel : Chanel
<
BonjourConnectionDelegate
>
- (id)initWithHost:(NSString *)host andPort:(int)port;
- (id)initWithNetService:(NSNetService *)netService;

@end
