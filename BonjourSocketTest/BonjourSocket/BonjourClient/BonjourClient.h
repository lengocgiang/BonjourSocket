//
//  EchoClient.h
//  GCocoaEcho
//
//  Created by Le Ngoc Giang on 10/22/14.
//  Copyright (c) 2014 seesaavn. All rights reserved.
//  in develop

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, BonjourClientSendData) {
    BonjourClientSendDataDidFinished,
    BonjourClientSendDataDidCanceled,
    BonjourClientSendDataError
};

#define kEchoClientOpenStreamSuccess                            @"EchoClientOpenStreamSuccess"

// Define notifications
#define kBonjourClientBrowserSuccessNotification                @"EchoClientBrowserSuccessNotification"
#define kBonjourClientBrowserRemoveServiceNotification          @"EchoClientBrowserRemoveServiceNotification"
#define kBonjourClientBrowserSearchErrorNotification            @"EchoClientBrowserSearchErrorNotification"
#define kBonjourClientBrowserStopSearchNotification             @"EchoClientBrowserStopSearchNotification"

#define kBonjourClientStartSendDataNotification                 @"BonjourClientStartSendDataNotification"
#define kBonjoutClientSendingDataNotification                   @"BonjoutClientSendingDataNotification"
#define kBonjourClientSendDataDidFinishedNotification           @"BonjourClientSendDataDidFinishedNotification"
#define kBonjourClientSendDataWithErrorNotification             @"BonjourClientSendDataWithErrorNotification"
#define kBonjourClientSendDataDidCanceledNotification           @"BonjourClientSendDataDidCanceledNotification"

@interface BonjourClient : NSObject

+ (BonjourClient *)sharedBrowser;

- (void)browserForServer;
- (void)browserForServerWithType:(NSString *)serverType;
- (void)stopBrowserSearchForServer;
- (NSArray *)availableService;

- (void)openStreamToConnectNetService:(NSNetService *)netService;
- (void)openStreamToConnectNetService:(NSNetService *)netService withName:(NSString *)name;
- (void)closeStreams;
- (void)dataSending:(NSData *)dataSending;


@end
