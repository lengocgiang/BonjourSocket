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
    BonjourClientBeginSendData,
    BonjourClientFinishedSendingData,
    BonjourClientCanceledSendingData,
    BonjourClientErrorSendingData
};

#define kEchoClientOpenStreamSuccess                            @"EchoClientOpenStreamSuccess"

// Define notifications
#define kBonjourClientBrowserSuccessNotification                @"EchoClientBrowserSuccessNotification"
#define kBonjourClientBrowserRemoveServiceNotification          @"EchoClientBrowserRemoveServiceNotification"
#define kBonjourClientBrowserSearchErrorNotification            @"EchoClientBrowserSearchErrorNotification"
#define kBonjourClientBrowserStopSearchNotification             @"EchoClientBrowserStopSearchNotification"

#define kBonjourClientBeginSendDataNotification                 @"BonjourClientBeginSendDataNotification"
#define kBonjourClientFinishedSendingData                       @"BonjourClientFinishedSendingData"
#define kBonjourClientCanceledSendingData                       @"BonjourClientCanceledSendingData"
#define kBonjourClientErrorSendingData                          @"BonjourClientErrorSendingData"


@interface BonjourClient : NSObject

+ (BonjourClient *)sharedBrowser;

- (void)browserForServer;
- (void)browserForServerWithType:(NSString *)serverType;
- (void)stopBrowserSearchForServer;
- (NSArray *)availableService;
- (void)closeStreams;

// Open stream with service
- (void)openStreamToConnectNetService:(NSNetService *)netService;
- (void)openStreamToConnectNetService:(NSNetService *)netService withFilePath:(NSString *)path;


@end
